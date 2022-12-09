#####################
### 4. Bathymetry ###
#####################

# Clear environment
rm(list = ls())

# Load packages
## Need to install a development version of terra to open the netCDF
### ***Note: May need restart R upon installing (stop running after first installation)
install.packages('terra', repos='https://rspatial.r-universe.dev')

if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr,
               fasterize,
               ggplot2,
               plyr,
               ncdf4, # can be used to read the bathymetry data (as they are an netCDF file [.nc])
               raster,
               rgdal,
               rgeos,
               sf,
               sp,
               terra,
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directories
bathymetry_dir <- "data/a_raw_data"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
raster_dir <- "data/d_raster_data"

#### Intermediate directory
intermediate_dir <- "data/b_intermediate_data"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine") %>%
  # reproject into NAD83 to match with the bathymetry / topography data
  sf::st_transform("EPSG:4269") # EPSG 4269 (https://epsg.io/4269)

study_area_raster <- terra::rast(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

# Load bathymetry data (source: https://www.ngdc.noaa.gov/thredds/fileServer/crm/crm_vol5.nc)
## For more United States coverage and spatial resolution information, visit: https://www.ngdc.noaa.gov/mgg/coastal/crm.html
gom_bath <- terra::rast(paste(bathymetry_dir, "crm_vol5.nc", sep = "/"))

## ***Note: if wanting to use raster package, then notation is raster::raster() to open files

#####################################
#####################################

## The raster/netCDF file will appear to have no CRS. According to the metadata its CRS is 4269
## Set coordinate reference system ("EPSG:4269","+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs +type=crs")
crs(gom_bath) <- "EPSG:4269"
cat(crs(gom_bath)) # to inspect the details around the coordinate reference system

#####################################
#####################################

# Generate raster to only study area
tx_bath_mask <- gom_bath %>%
  # crop to the study area (will be for the extent)
  terra::crop(study_area) %>%
  # mask to the study area (show data within the extent)
  terra::mask(study_area)

## Set the coordinate coordinate system of the Texas bathymetry if it is missing
cat(crs(tx_bath_mask)) # check the coordinate system (if EPSG is 4269 no need to run next line of code)
crs(tx_bath_mask) <- "EPSG:4269"

#####################################
#####################################

# If slope data is already created and need to be reprojected,
# pull in exported slope data instead of generating the data again.
# tx_bath_mask <- terra::rast(paste(intermediate_dir, "tx_bath_mask_4269.grd", sep = "/"))

# Inspect the units
# Should show resolution is in degrees (0.001 = 111 meters approximately)
# Can also see units under the angle unit using cat(crs())
st_crs(tx_bath_mask, parameters = TRUE)$units_gdal

## Set coordinate reference system
### ***Note: this coordinate reference system will put units in meters
crs <- "EPSG:5070"

## Reproject raster
tx_bath_mask_5070 <- tx_bath_mask %>%
  # reproject into coordinate reference system
  terra::project(y = crs,
                 res = 100) # resolution should be put in meters as EPSG:5070 is in meters, no longer degrees

#####################################

## check units and coordinate reference system
st_crs(tx_bath_mask_5070, parameters = TRUE)$units_gdal # shows resolution is in meters
cat(crs(tx_bath_mask_5070))

#####################################
#####################################

# Calculate bathymetry slope
gom_slope <- tx_bath_mask_5070 %>% 
  # calculate the slope with result being in degrees
  ## for more on the methods, see: https://www.rdocumentation.org/packages/raster/versions/3.0-2/topics/terrain
  terra::terrain(v = "slope",
                 unit = "degrees",
                 neighbors = 8) # neighbors 4 is faster, 8 takes all neighboring cells

# If slope data is already created and need to be reprojected,
# pull in exported slope data instead of generating the data again.
# gom_slope <- raster::raster(paste(intermediate_dir, "slope.grd", sep = "/"))

st_crs(gom_slope, parameters = TRUE)$units_gdal # shows resolution is in meters

slope_5070 <- gom_slope %>%
  # reproject into coordinate reference system
  terra::project(y = crs,
                 res = 100) # 100 meter resolution

cat(crs(slope_5070))

#####################################
#####################################

# Mapping the data
## Make raster as a data frame
gom_bath_df <- gom_bath %>%
  as.data.frame(xy = T)

tx_bath_mask_df <- tx_bath_mask %>%
  as.data.frame(xy = T)

r <- ggplot() +
  geom_sf(data = study_area, fill = NA, color = "black", linetype = "dashed") +
  geom_tile(data = tx_bath_mask_df, aes(x=x, y=y, fill=z))
r

#####################################
#####################################

# Export data
## Analysis data
writeRaster(tx_bath_mask_5070, filename = file.path(raster_dir, "bathymetry.grd"), overwrite = T)
writeRaster(slope_5070, filename = file.path(raster_dir, "slope.grd"), overwrite = T)

## Intermediate data
writeRaster(tx_bath_mask, filename = file.path(intermediate_dir, "tx_bath_mask_4269.grd"), overwrite = T)
writeRaster(tx_bath_mask_5070, filename = file.path(intermediate_dir, "tx_bath_mask_5070.grd"), overwrite = T)

writeRaster(gom_slope, filename = file.path(intermediate_dir, "slope.grd"), overwrite = T)
writeRaster(slope_5070, filename = file.path(intermediate_dir, "slope_5070.grd"), overwrite = T)



#####################################
#####################################
#####################################
#####################################

# ## Alternative way to add and inspect the bathymetry data
# 
# gom_bathymetry <- ncdf4::nc_open(paste(bathymetry_dir, "crm_vol5.nc", sep = "/"))
# 
# # Inspect bathymetry data
# print(gom_bathymetry)
# 
# # Get variable values
# lon <- ncdf4::ncvar_get(gom_bathymetry, "x")
# lat <- ncdf4::ncvar_get(gom_bathymetry, "y")
# depth <- ncdf4::ncvar_get(gom_bathymetry, "z")
# 
# # Verify depth units are meters
# depth_units <- ncdf4::ncatt_get(gom_bathymetry, "z", "units")
# depth_units$value # yes, the values are in meters
# 
# # Dimensions of variables
# nlon <- dim(lon)
# nlat <- dim(lat)
# 
# # Change missing values and fill values to be "NA"
# gom_bathymetry[["var"]][["z"]][["_FillValue"]] <- NA
# gom_bathymetry[["var"]][["z"]][["missval"]] <- NA


