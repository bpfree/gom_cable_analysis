############################
### 1. Define Study Area ###
############################

# Clear environment
rm(list = ls())

# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr,
               fasterize,
               ggplot2,
               plyr,
               raster,
               rgdal,
               rgeos,
               rnaturalearth, # use devtools::install_github("ropenscilabs/rnaturalearth") if packages does not install properly
               sf,
               sp,
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directories
land_dir <- "data/a_raw_data/globalislandsfix.gdb"
wind_area_dir <- "data/a_raw_data/BOEMWindLayers_4Download.gdb"

### Output directories
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
raster_dir <- "data/d_raster_data"
study_area_gpkg <- "data/b_intermediate_data/gom_study_area.gpkg"
wind_farm_gpkg <- "data/b_intermediate_data/gom_wind_area.gpkg"
physical_land_gpkg <- "data/b_intermediate_data/gom_physical_land.gpkg"

gis_dir <- "data/zz_gis_data"

#####################################

# View layer names within geodatabase
## ****Note: should notice 4 layers
sf::st_layers(dsn = land_dir,
              do_count = TRUE)

## ***Note: should notice 5 layers
sf::st_layers(dsn = wind_area_dir,
              do_count = TRUE)

#####################################
#####################################

land_function <- function(land_data){
  land_layer <- land_data %>%
    # create field called "land"
    dplyr::mutate(land = "land") %>%
    dplyr::select(land) %>%
    # reproject the coordinate reference system to match BOEM call areas
    sf::st_transform("EPSG:5070") %>%
    dplyr::group_by(land) %>%
    dplyr::summarise()
  return(land_layer)
}

#####################################
#####################################

# Load BOEM Wind Call Areas
## Source (geodatabase): https://www.boem.gov/renewable-energy/mapping-and-data/renewable-energy-gis-data
## Metadata: https://metadata.boem.gov/geospatial/boem_renewable_lease_areas.xml
### ***Note: Data are also accessible for download on MarineCadastre (under "Active Renewable Energy Leases")
boem_wind_areas <- sf::st_read(dsn = wind_area_dir, layer = "Wind_Planning_Area_Outlines_11_17_2022") %>%
  # filter to wind areas only for Gulf of Mexico
  dplyr::filter(stringr::str_detect(ADDITIONAL_INFORMATION,
                                    "Gulf of Mexico")) %>%
  dplyr::rename("geometry" = "Shape")

g <- ggplot() +
  geom_sf(data = boem_wind_areas, color = "blue") +
  # Label wind areas
  geom_sf_label(data=boem_wind_areas, mapping=aes(label=PROTRACTION_NUMBER), show.legend = F, size=2.5)
g

wind_farm_i <- boem_wind_areas %>%
  dplyr::filter(PROTRACTION_NUMBER == "NH15-10")

g <- ggplot() +
  geom_sf(data = wind_farm_i, color = "blue") +
  # Label wind areas
  geom_sf_label(data=wind_farm_i, mapping=aes(label=PROTRACTION_NUMBER), show.legend = F, size=2.5)
g

#####################################
#####################################

# Study Area
## Create points for study area
### Add points as they need to be drawn (clockwise or counterclockwise)
aoi_points <- rbind(c("point",-94,28), # southeastern point
                    c("point",-94,30), # northeastern point
                    c("point",-95.5,30), # northwestern point
                    c("point",-95.5,28)) %>% # southwestern point
  # convert to data frame
  as.data.frame() %>%
  # rename column names
  dplyr::rename("point" = "V1",
                "lon" = "V2",
                "lat" = "V3") %>%
  # convert to simple feature
  st_as_sf(coords = c("lon", "lat"),
           # set the coordinate reference system to WGS84
           crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
  # reproject the coordinate reference system to match BOEM call areas
  st_transform("EPSG:5070") # EPSG 5070 (https://epsg.io/5070)

#####################################

# Create polygon
aoi_poly <- aoi_points %>%
  # group by the points field
  group_by(point) %>%
  # combine geometries without resolving borders to create multipoint feature
  summarise(geometry = st_combine(geometry)) %>%
  # convert back to sf
  st_as_sf() %>%
  # convert to polygon simple feature
  st_cast("POLYGON") %>%
  st_as_sf()

## Check units for determining cellsize of grid
st_crs(aoi_poly, parameters = TRUE)$units_gdal

#####################################

# Create study area
## Texas land boundary
### Shoreline data (USGS Global Islands Vector dataset)
### Global Island Explorer has detailed information about the dataset and can link to the paper detailing the methods (https://rmgsc.cr.usgs.gov/gie/)
### For visual inspection, navigate to here: https://rmgsc.cr.usgs.gov/gie/gie.shtml
### For downloading the data:
#### 1.) Navigate to this page: https://rmgsc.cr.usgs.gov/outgoing/ecosystems/Global/
#### 2.) Click the USGSEsriWCMC_GlobalIslands_v3.mpk (Note: there may be a newer version so name could be different -- Version 3 as of `October 11 October 2022)
#### 3.) Where file (.mpk -- Esri mappackage) is located change .mpk to .zip
#### 4.) Unzip file
#### 5.) Navigate to and copy geodatabase (as of 11 October 2021, v10 and v108 had no differences in their data)
#### 6.) Paste to data dictionary

##### Load continental land data
continents <- st_read(dsn = land_dir, layer = "USGSEsriWCMC_GlobalIslandsv2_Continents") %>%
  land_function()

##### Load big island land data
big_islands <- st_read(dsn = land_dir, layer = "USGSEsriWCMC_GlobalIslandsv2_BigIslands") %>%
  # make all features valid as an error may be generated otherwise
  st_make_valid() %>%
  land_function()

##### Load small island land data
small_islands <- st_read(dsn = land_dir, layer = "USGSEsriWCMC_GlobalIslandsv2_SmallIslands") %>%
  land_function()

##### Load very small island land data
very_small_islands <- st_read(dsn = land_dir, layer = "USGSEsriWCMC_GlobalIslandsv2_VerySmallIslands") %>%
  land_function()

#####################################

### Remove land areas
aoi_marine <- aoi_poly %>%
  # Remove continental land
  sf::st_difference(continents) %>%
  # Remove big island land
  sf::st_difference(big_islands) %>%
  # Remove small island land
  sf::st_difference(small_islands) %>%
  # Remove very small island land
  sf::st_difference(very_small_islands) %>%
  # create value field
  dplyr::mutate(value = 0) %>%
  # select value field
  dplyr::select(value)

#####################################


# Alternative: Create single land features
## This feature will allow the study area to target only marine / coastal areas
### Remove any continental land
# aoi_continent <- aoi_poly %>%
#   sf::st_difference(continents)
# 
# ### Remove any big islands land
# aoi_continent_big <- aoi_continent %>%
#   sf::st_difference(big_islands)
# 
# ### Remove any continental land
# aoi_continent_big_small <- aoi_continent_big %>%
#   sf::st_difference(small_islands)
# 
# ### Remove any small islands land
# aoi_continent_big_small_very_small <- aoi_continent_big_small %>%
#   sf::st_difference(very_small_islands)


#####################################

##### Obtain land features in study area
aoi_continental <- continents %>%
  st_make_valid() %>%
  st_intersection(aoi_poly)

aoi_big <- big_islands %>%
  st_make_valid() %>%
  st_intersection(aoi_poly)

aoi_small <- small_islands %>%
  st_make_valid() %>%
  st_intersection(aoi_poly)

aoi_very_small <- very_small_islands %>%
  st_make_valid() %>%
  st_intersection(aoi_poly)

#####################################

# ### Alternative: Natural Earth has data for Administration Level 2 (states) (website: https://www.naturalearthdata.com/)
# ### The data from ne_states() pulls in the 10m resolution
# ### rnaturalearth package provides quick access to import the data (https://cran.r-project.org/web/packages/rnaturalearth/README.html)
# texas <- rnaturalearth::ne_states(country = "United States of America", geounit = "United States of America", returnclass = "sf") %>%
#   # select only Texas
#   dplyr::filter(name == "Texas") %>%
#   # reproject the coordinate reference system to match BOEM call areas
#   sf::st_transform("EPSG:5070")

#####################################
# 
# ## Create polygon for only coastal / marine area
# aoi_marine <- aoi_poly %>%
#   # remove any of the polygon that falls on land (in Texas)
#   sf::st_difference(texas) %>%
#   dplyr::select(name)

#####################################
#####################################

# Create grid
## Square
### Grid with 100 meter cell size
#### Create a template raster that has the extent of the study area
rast_temp <- raster(extent(aoi_marine),
                    # cell resolution is 100 meters
                    res = 100,
                    # has the came coordinate reference system as the study area
                    crs = aoi_marine)

#### Create raster filed with the data from the study area
rast_100m <- fasterize(sf = aoi_marine,
                       raster = rast_temp,
                       field = "value")

#####################################

# Alternatively, you can make a grid for the entire study area
# In this case, it will have a boundary box that matches the entire
# maximum extent of the study area. Therefore, it will have a regular
# rectugular shape instead of following the waterline boundary as above.

# aoi_100 <- st_make_grid(aoi_marine,
#                         cellsize = 100, # units are in meter
#                         offset = st_bbox(aoi_marine)[c("xmin", "ymin")],
#                         what = "polygons",
#                         crs = 5070, # NAD83 / Conus Albers
#                         square = TRUE, # keep it as square
#                         flat_topped = TRUE) %>%
#   # convert to sf (simple feature)
#   st_sf() %>%
#   # create value field
#   dplyr::mutate(value = 0)
# 
# ### Grid with 65 meter cell size
# aoi_65 <- st_make_grid(aoi_marine,
#                        cellsize = 65, # units are in meter
#                        offset = st_bbox(aoi_poly)[c("xmin", "ymin")],
#                        what = "polygons",
#                        crs = 5070, # NAD83 / Conus Albers
#                        square = TRUE, # keep it as square
#                        flat_topped = TRUE) %>%
#   # convert to sf (simple feature)
#   st_sf()
# 
# #####################################
# 
# If so desired, the grid can be made as a hexagonal grid.
# Rasters cannot use a hexagonal grid, so this will be
# less useful in this case.
#
# ## Hexagonal
# ### Grid with 100 meter cell size
# aoi_hex_100 <- st_make_grid(aoi_marine,
#                             cellsize = 100, # units are in meter
#                             offset = st_bbox(aoi_poly)[c("xmin", "ymin")],
#                             what = "polygons",
#                             crs = 5070, # NAD83 / Conus Albers
#                             square = FALSE, # create hexagonal
#                             flat_topped = TRUE) %>%
#   # convert to sf (simple feature)
#   st_sf()

#####################################

# Inspect grid
## Calculate longitude resolution
# xmin_100 <- st_bbox(aoi_100)$xmin
# xmax_100 <- st_bbox(aoi_100)$xmax
# 
# ncol_100 <- (xmax_100 - xmin_100) / 100
# 
# ## Calculate latitude resolution
# ymin_100 <- st_bbox(aoi_100)$ymin
# ymax_100 <- st_bbox(aoi_100)$ymax
# 
# nrow_100 <- (ymax_100 - ymin_100) / 100

#####################################
#####################################

# # Convert to raster
# temp_rast <- raster(xmn = xmin_100, xmx = xmax_100,
#                     ymn = ymin_100, ymx = ymax_100,
#                     res = 100,
#                     crs = 5070)
# 
# aoi_100m_raster <- fasterize(sf = aoi_100,
#                              raster = temp_rast,
#                              field = "value",
#                              fun = "last")

#####################################
#####################################

# Export data
## Geopackage
st_write(aoi_poly, dsn = analysis_gpkg, layer = "gom_study_area", append = F)
st_write(aoi_marine, dsn = analysis_gpkg, layer = "gom_study_area_marine", append = F)
st_write(wind_farm_i, dsn = analysis_gpkg, layer = "gom_wind_area_i", append = F)

## Raster
# writeRaster(aoi_100m_raster, filename = file.path(raster_dir, "gom_study_area_marine_100m_raster.grd"), overwrite = T)
writeRaster(rast_100m, filename = file.path(raster_dir, "gom_study_area_marine_100m_raster.grd"), overwrite = T)

## Study area geopackage
### Study areas
st_write(aoi_continent, dsn = study_area_gpkg, layer = "gom_study_area_continental", append = F)
st_write(aoi_continent_big, dsn = study_area_gpkg, layer = "gom_study_area_continental_big_island", append = F)
st_write(aoi_continent_big_small, dsn = study_area_gpkg, layer = "gom_study_area_continental_big_small_islands", append = F)
st_write(aoi_continent_big_small_very_small, dsn = study_area_gpkg, layer = "gom_study_area_continental_big_small__vsmall_islands", append = F)
st_write(aoi_marine, dsn = study_area_gpkg, layer = "gom_study_area_marine", append = F)

### Physical land
st_write(continents, dsn = physical_land_gpkg, layer = "continental", append = F)
st_write(big_islands, dsn = physical_land_gpkg, layer = "big_island", append = F)
st_write(small_islands, dsn = physical_land_gpkg, layer = "small_islands", append = F)
st_write(very_small_islands, dsn = physical_land_gpkg, layer = "very_small_islands", append = F)

st_write(aoi_continental, dsn = physical_land_gpkg, layer = "aoi_continental", append = F)
st_write(aoi_big, dsn = physical_land_gpkg, layer = "aoi_big_island", append = F)
st_write(aoi_small, dsn = physical_land_gpkg, layer = "aoi_small_islands", append = F)
st_write(aoi_very_small, dsn = physical_land_gpkg, layer = "aoi_very_small_islands", append = F)

## Wind Area geopackage
st_write(wind_farm_i, dsn = wind_farm_gpkg, layer = "gom_wind_area_i", append = F)

## Shapefile
st_write(aoi_poly, dsn = paste0(gis_dir, "/", layer = "gom_cable_study_boundary.shp"), append = F)
