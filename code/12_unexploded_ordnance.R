################################
### 12. Unexploded Ordnances ###
################################

# Clear environment
rm(list = ls())

# Load packages
pacman::p_load(dplyr,
               ggplot2,
               plyr,
               raster,
               rgdal,
               rgeos,
               sf,
               sp,
               stringr,
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directories
uxo_dir <- "data/a_raw_data/UnexplodedOrdnance/UnexplodedOrdnance.gdb"

### Output directories
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
uxo_gpkg <- "data/b_intermediate_data/gom_uneploded_ordnance.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# View layer names within geodatabase
sf::st_layers(dsn = uxo_dir,
              do_count = TRUE)

#####################################

# Load unexploded ordnance point data (source: https://marinecadastre.gov/downloads/data/mc/UnexplodedOrdnance.zip)
unexploded_ordnance_points <- st_read(dsn = uxo_dir, layer = "UnexplodedOrdnanceLocations") %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain only unexploded ordnance sites in the study area
  sf::st_intersection(study_area) %>%
  # add a buffer of 500 meters around sites
  sf::st_buffer(dist = 500) %>%
  # create field called "layer" and fill with "unexploded ordnance" for summary
  dplyr::mutate(layer = "unexploded ordnance") %>%
  # select the layer field for later data summary
  dplyr::select(layer,
                value)

st_crs(unexploded_ordnance_points, parameters = TRUE)$units_gdal

# Load unexploded ordnance area data
## ***Note: Unexploded Ordnance Areas data (https://marinecadastre.gov/downloads/data/mc/UnexplodedOrdnanceArea.zip)
## has one fewer area than the location dataset (https://marinecadastre.gov/downloads/data/mc/UnexplodedOrdnance.zip)
unexploded_ordnance_areas <- st_read(dsn = uxo_dir, layer = "UnexplodedOrdnanceAreas") %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform(5070) %>%
  # obtain only unexploded ordnance sites in the study area
  sf::st_intersection(study_area) %>%
  # create field called "layer" and fill with "unexploded ordnance" for summary
  dplyr::mutate(layer = "unexploded ordnance") %>%
  # select the layer field for later data summary
  dplyr::select(layer,
                value)

#####################################

# Inspect the point and polygon data for unexploded ordnances
g <- ggplot() + 
  geom_sf(data = unexploded_ordnance_areas, color = "red", fill = NA) +
  geom_sf(data = unexploded_ordnance_points, color = "blue") +
  geom_sf(data = study_area, color = "black", linetype = "dashed", fill = NA)
g

#####################################
#####################################

# Combine data
unexploded_ordnance <- unexploded_ordnance_points %>%
  # Combine site data with area data
  rbind(unexploded_ordnance_areas) %>%
  # group by layer for later summary
  dplyr::group_by(layer,
                  value) %>%
  # summarise the data to get single feature
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = unexploded_ordnance, dsn = analysis_gpkg, "unexploded_ordnance", append = F)

## Unexploded ordnance geopackage
st_write(obj = unexploded_ordnance, dsn = uxo_gpkg, "unexploded_ordnance", append = F)
st_write(obj = unexploded_ordnance_points, dsn = uxo_gpkg, "unexploded_ordnance_point", append = F)
st_write(obj = unexploded_ordnance_areas, dsn = uxo_gpkg, "unexploded_ordnance_areas", append = F)
