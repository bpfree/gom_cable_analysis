###############################
### Normalization Functions ###
###############################

# Clear environment
rm(list = ls())

# Load packages
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
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Directories
#### Input
raster_dir <- "data/d_raster_data"

#### Output
intermediate_dir <- "data/b_intermediate_data"



#####################################
#####################################

# Load data
bathymetry <- raster::raster(paste(raster_dir, "bathymetry.grd", sep = "/"))
slope <- raster::raster(paste(raster_dir, "slope.grd", sep = "/"))

## Inspect data
NAvalue(bathymetry)
frequency(bathymetry)
hist(bathymetry)

NAvalue(slope)
freq(slope)

#####################################

# Load raster grid
gom_raster <- raster::raster(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

#####################################
#####################################

# Create normalization functions
## Linear function
linear_function <- function(raster){
  # calculate maximum value to set upper limit to remove any positive values
  max <- maxValue(raster)
  
  # reclassify any positive values as 0 (as these would either be errors or designate a land feature)
  raster <- raster::reclassify(raster, c(0, max, NA))
  
  # since bathymetry is depth all values are negative; need to multiple by -1 to get positive values for normalizing between 0 and 1
  raster <- raster * -1
  
  # calculate minimum value
  min <- minValue(raster)
  
  # recalculate maximum value
  max <- maxValue(raster)
  
  # create linear function
  normalize <- (raster[] - min) / (max - min)
  
  # set values back to the original raster
  bathymetry_normalize <- setValues(raster, normalize)
  
  # return the raster
  return(bathymetry_normalize)
}

## Create s-shape membership function
### Adapted from https://www.mathworks.com/help/fuzzy/smf.html
smf_function <- function(raster){
  # calculate minimum value
  min <- minValue(raster)
  
  # calculate maximum value
  max <- maxValue(raster)
  
  # calculate s-scores (more desired values get score of 0 while less desired will increase till 1)
  s_value <- ifelse(raster[] == min, 0, # if value is equal to minimum, score as 0
                    # if value is larger than minimum but lower than mid-value, calculate based on reduction equation
                    ifelse(raster[] > min & raster[] < (min + max) / 2, 2*((raster[] - min) / (max - min))**2,
                           # if value is larger than mid-value but lower than maximum, calculate based on equation
                           ifelse(raster[] >= (min + max) / 2 & raster[] < max, 1 - 2*((raster[] - max) / (max - min))**2,
                                  # if value is equal to maximum, score as 1; otherwise give NA
                                  ifelse(raster[] == max, 1, NA))))
  
  # set values back to the original raster
  slope_svalues <- setValues(raster, s_value)
  
  # return the raster
  return(slope_svalues)
}

#####################################
#####################################

# Create bathymetry normalization
bathymetry_normalize <- bathymetry %>%
  linear_function()

# Inspect 
hist(bathymetry_normalize) # show histogram of values (though mostly values near 1)
freq(bathymetry_normalize) # show frequency of values (though will round to 0 and 1)

#####################################

# temp_r = raster(matrix(sample(2:1000, 10000, replace = TRUE), 100, 100))
# min <- cellStats(temp_r, "min")
# max <- cellStats(temp_r, "max")
# temp_z_values <- zmf_function(temp_r, min, max)
# max(temp_z_values, na.rm = T)
# hist(temp_z_values)
# temp_new <- setValues(temp_r, temp_z_values)
# hist(temp_new)
# freq(temp_new, by = 0.1)
# max(temp_new, na.rm = T)

# Generate new s-shape values
slope_normalize <- slope %>%
  smf_function()

## Make sure maximum value is 1
maxValue(slope_normalize) ## maximum value = 0.9961739
list(unique(slope_normalize)) # list all unique values

#####################################

## Inspect new raster
hist(slope_normalize) # show histogram of values (though mostly values near 1)
freq(slope_normalize) # show frequency of values (though will round to 0 and 1)


#####################################

# # Check data
# slope_df <- slope %>%
#   as.data.frame(xy = T)
# slope_df_min <- min(slope_df$slope, na.rm = T)
# slope_df_max <- max(slope_df$slope, na.rm = T)
# slope_df_z <- zmf_function(slope_df$slope)
# slope_df$zscore <- slope_df_z
# hist(slope_df$zscore)
# 
# slope_z_sf <- slope_df %>%
#   # convert to simple feature
#   st_as_sf(coords = c("x", "y"),
#            crs = 5070) %>% # EPSG 5070 (https://epsg.io/5070)
#   st_buffer(dist = 100)
# 
# slope_z_raster <- fasterize(sf = slope_z_sf,
#                             raster = gom_raster,
#                             field = "zscore")
# 
# slope_z_raster2 <- slope_df %>%
#   # convert to simple feature
#   st_as_sf(coords = c("x", "y"),
#            crs = 5070) %>% # EPSG 5070 (https://epsg.io/5070)
#   st_bufer(dist = 100) %>%
#   fasterize(raster = gom_raster,
#             field = "zscore")

#####################################
#####################################
# Export data
## Raster data
writeRaster(bathymetry_normalize, filename = file.path(raster_dir, "bathymetry_normalize.grd"), overwrite = T)
writeRaster(slope_normalize, filename = file.path(raster_dir, "slope_normalize.grd"), overwrite = T)

## Intermediate data
writeRaster(bathymetry_normalize, filename = file.path(intermediate_dir, "bathymetry_normalize.grd"), overwrite = T)
writeRaster(slope_normalize, filename = file.path(intermediate_dir, "slope_normalize.grd"), overwrite = T)
