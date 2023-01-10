################################
### 4. Bathymetry -- terra() ###
################################

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
study_area <- sf::st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine") %>%
  # reproject into NAD83 to match with the bathymetry / topography data
  sf::st_transform("EPSG:4269") # EPSG 4269 (https://epsg.io/4269)

study_area_raster <- terra::rast(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

# Load bathymetry data (source: https://www.ngdc.noaa.gov/thredds/fileServer/crm/crm_vol5.nc)
## For more United States coverage and spatial resolution information, visit: https://www.ngdc.noaa.gov/mgg/coastal/crm.html
gom_bath <- terra::rast(paste(bathymetry_dir, "crm_vol5.nc", sep = "/"))

#####################################
#####################################

## The raster netCDF file will appear to have no CRS. According to the metadata its CRS is 4269
## Set coordinate reference system ("EPSG:4269","+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs +type=crs")
crs(gom_bath) <- "EPSG:4269"
cat(crs(gom_bath)) # to inspect the details around the coordinate reference system

#####################################
#####################################

# Generate raster to only study area
tx_bath_mask <- gom_bath %>%
  # crop to the study area (will be for the extent)
  terra::crop(study_area,
              # use the study area as the mask (show data only within the extent)
              mask = T)

### Old method:
# tx_bath_mask <- gom_bath %>%
#   # crop to the study area (will be for the extent)
#   terra::crop(study_area) %>%
#   # mask to the study area (show data within the extent)
#   terra::mask(study_area)

## Set the coordinate coordinate system of the Texas bathymetry if it is missing
cat(crs(tx_bath_mask)) # check the coordinate system (if EPSG is 4269 no need to run next line of code)
#crs(tx_bath_mask) <- "EPSG:4269"

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
sf::st_crs(tx_bath_mask_5070, parameters = TRUE)$units_gdal # shows resolution is in meters
cat(crs(tx_bath_mask_5070))
terra::minmax(tx_bath_mask_5070)[1,]
terra::minmax(tx_bath_mask_5070)[2,]

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
cat(crs(gom_slope))
terra::minmax(gom_slope)[1,]
terra::minmax(gom_slope)[2,]

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

# # Create normalization functions
# ## Linear function
linear_function <- function(raster){
  # calculate maximum value to set upper limit to remove any positive values
  max <- terra::minmax(raster)[2,]

  # reclassify any positive values as 0 (as these would either be errors or designate a land feature)
  raster <- terra::classify(raster, cbind(0, max, NA))

  # since bathymetry is depth all values are negative; need to multiple by -1 to get positive values for normalizing between 0 and 1
  raster <- raster * -1

  # calculate minimum value
  min <- terra::minmax(raster)[1,]

  # recalculate maximum value
  max <- terra::minmax(raster)[2,]

  # create linear function
  normalize <- (raster[] - min) / (max - min)

  # set values back to the original raster
  bathymetry_normalize <- terra::setValues(raster, normalize)

  # return the raster
  return(bathymetry_normalize)
}

# 
# ## Create s-shape membership function
# ### Adapted from https://www.mathworks.com/help/fuzzy/smf.html
smf_function <- function(raster){
  # calculate minimum value
  min <- terra::minmax(raster)[1,]

  # calculate maximum value
  max <- terra::minmax(raster)[2,]

  # calculate s-scores (more desired values get score of 0 while less desired will increase till 1)
  s_value <- ifelse(raster[] == min, 0, # if value is equal to minimum, score as 0
                    # if value is larger than minimum but lower than mid-value, calculate based on reduction equation
                    ifelse(raster[] > min & raster[] < (min + max) / 2, 2*((raster[] - min) / (max - min))**2,
                           # if value is larger than mid-value but lower than maximum, calculate based on equation
                           ifelse(raster[] >= (min + max) / 2 & raster[] < max, 1 - 2*((raster[] - max) / (max - min))**2,
                                  # if value is equal to maximum, score as 1; otherwise give NA
                                  ifelse(raster[] == max, 1, NA))))

  # set values back to the original raster
  slope_svalues <- terra::setValues(raster, s_value)

  # return the raster
  return(slope_svalues)
}
# 
# #####################################
# #####################################
# 
# # Create bathymetry normalization
bathymetry <- tx_bath_mask_5070

bathymetry_normalize <- bathymetry %>%
  linear_function() %>%
  # have data get limited to study area dimensions
  terra::crop(study_area_raster)

# # Inspect
terra::minmax(bathymetry_normalize)[1,] # minimum value = 0
terra::minmax(bathymetry_normalize)[2,] # maximum value = 1
res(bathymetry_normalize) # 100 x 100
hist(bathymetry_normalize) # show histogram of values (values mostly between 0.0 and 0.4)
freq(bathymetry_normalize) # show frequency of values (though will round to 0 and 1)
ncol(bathymetry_normalize)
nrow(bathymetry_normalize)
ncell(bathymetry_normalize)

# #####################################
# 
# # temp_r = raster(matrix(sample(2:1000, 10000, replace = TRUE), 100, 100))
# # min <- cellStats(temp_r, "min")
# # max <- cellStats(temp_r, "max")
# # temp_z_values <- zmf_function(temp_r, min, max)
# # max(temp_z_values, na.rm = T)
# # hist(temp_z_values)
# # temp_new <- setValues(temp_r, temp_z_values)
# # hist(temp_new)
# # freq(temp_new, by = 0.1)
# # max(temp_new, na.rm = T)
# 
# # Generate new s-shape values
slope <- gom_slope

slope_normalize <- slope %>%
  smf_function() %>%
  # have data get limited to study area dimensions
  terra::crop(study_area_raster)

# ## Make sure maximum value is 1
terra::minmax(slope_normalize)[1,] # minimum value = 0
terra::minmax(slope_normalize)[2,] # maximum value = 1
list(unique(slope_normalize)) # list all unique values
res(slope_normalize) # 100 x 100
ncol(slope_normalize)
nrow(slope_normalize)
ncell(slope_normalize)

# #####################################
# 
# ## Inspect new raster
# hist(slope_normalize) # show histogram of values (though mostly values near 0)
# freq(slope_normalize) # show frequency of values (though will round to 0 and 1)

#####################################
#####################################

# Export data
## Analysis data
terra::writeRaster(tx_bath_mask_5070, filename = file.path(raster_dir, "bathymetry.grd"), overwrite = T)
terra::writeRaster(gom_slope, filename = file.path(raster_dir, "slope.grd"), overwrite = T)

terra::writeRaster(bathymetry_normalize, filename = file.path(raster_dir, "bathymetry_normalize.grd"), overwrite = T)
terra::writeRaster(slope_normalize, filename = file.path(raster_dir, "slope_normalize.grd"), overwrite = T)

## Intermediate data
terra::writeRaster(tx_bath_mask, filename = file.path(intermediate_dir, "tx_bath_mask_4269.grd"), overwrite = T)
terra::writeRaster(tx_bath_mask_5070, filename = file.path(intermediate_dir, "tx_bath_mask_5070.grd"), overwrite = T)

terra::writeRaster(gom_slope, filename = file.path(intermediate_dir, "slope.grd"), overwrite = T)

terra::writeRaster(bathymetry_normalize, filename = file.path(intermediate_dir, "bathymetry_normalize.grd"), overwrite = T)
terra::writeRaster(slope_normalize, filename = file.path(intermediate_dir, "slope_normalize.grd"), overwrite = T)



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


