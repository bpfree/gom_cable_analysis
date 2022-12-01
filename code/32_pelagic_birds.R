##########################
### 32. Pelagic Birds  ###
##########################

# Clear environment
rm(list = ls())

# Load packages
pacman::p_load(dplyr,
               fasterize,
               ggplot2,
               lubridate,
               plyr,
               raster,
               rgdal,
               rgeos,
               rmapshaper,
               sf,
               sp,
               stringr,
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directories
pelagic_dir <- "data/a_raw_data/"
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
raster_dir <- "data/d_raster_data"

### Output directories
pelagic_gpkg <- "data/b_intermediate_data/prd_species.gpkg"
intermediate_dir <- "data/b_intermediate_data"
raster_dir <- "data/d_raster_data"

#####################################
#####################################

## Create s-shape membership function
### Adapted from https://www.mathworks.com/help/fuzzy/smf.html
smf_function_terra <- function(raster){
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
  pelagic_svalues <- setValues(raster, s_value)
  
  # return the raster
  return(pelagic_svalues)
}

#####################################

smf_function_raster <- function(raster){
  # calculate minimum value
  min <- raster::minValue(raster)
  
  # calculate maximum value
  max <- raster::maxValue(raster)
  
  # calculate s-scores (more desired values get score of 0 while less desired will increase till 1)
  s_value <- ifelse(raster[] == min, 0, # if value is equal to minimum, score as 0
                    # if value is larger than minimum but lower than mid-value, calculate based on reduction equation
                    ifelse(raster[] > min & raster[] < (min + max) / 2, 2*((raster[] - min) / (max - min))**2,
                           # if value is larger than mid-value but lower than maximum, calculate based on equation
                           ifelse(raster[] >= (min + max) / 2 & raster[] < max, 1 - 2*((raster[] - max) / (max - min))**2,
                                  # if value is equal to maximum, score as 1; otherwise give NA
                                  ifelse(raster[] == max, 1, NA))))
  
  # set values back to the original raster
  pelagic_svalues <- setValues(raster, s_value)
  
  # return the raster
  return(pelagic_svalues)
}

#####################################
#####################################

# Load data
## Study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

## Raster grid
gom_raster <- raster::raster(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

## Pelagic bird species
### ***Note: These data were originally from a geodatabase. To use them in this analysis,
### the data were exported from ArcGIS as a GRID.

#### To project to EPSG:5070 use the following:
# pelagic_bird5070 <- terra::rast(paste(pelagic_dir, "seabird", sep = "/")) %>%
#    terra::project(y = "EPSG:5070")

pelagic_birds <- terra::rast(paste(intermediate_dir, "pelagic_bird5070.grd", sep = "/")) %>%
  # downscale to resolution of 100 meters (factor = current resolution / 100)
  #terra::disagg(fact = res(.)/100) %>%
  terra::project(x = .,
                 y = "EPSG:5070",
                 res = 100,
                 origin = c(0,0),
                 method = "bilinear") %>%
  # crop to the study area (will be for the extent)
  terra::crop(gom_raster)


#####################################

# Create normalized pelagic data
pelagic_normalize <- pelagic_birds %>%
  smf_function_terra()

# Inspect 
terra::minmax(pelagic_normalize)[2,] # maximum value = 1
terra::minmax(pelagic_normalize)[1,] # minimum value = 0
res(pelagic_normalize) # 100 x 100
hist(pelagic_normalize) # show histogram of values (though mostly values near 1)
freq(pelagic_normalize) # show frequency of values (though will round to 0 and 1)

#####################################
#####################################
  
pelagic_bird <- raster::raster(paste(intermediate_dir, "pelagic_bird5070.grd", sep = "/")) %>%
  # reproject so resolution is 100 meters
  raster::projectRaster(crs = 5070,
                        res = 100) %>% # resolution should be put in meters as EPSG:5070 is in meters, no longer degrees
  # crop to the study area (will be for the extent)
  raster::crop(gom_raster) %>%
  # mask to study area
  raster::mask(study_area)
  
#####################################

# Create normalized pelagic data
pelagic_bird_normalize <- pelagic_bird %>%
  smf_function_raster()

extent(pelagic_bird_normalize) <- extent(gom_raster)
nrow(pelagic_bird_normalize) <- nrow(gom_raster)

# Inspect 
raster::maxValue(pelagic_bird_normalize) # maximum value = 1
raster::minValue(pelagic_bird_normalize) # minimum value = 0
res(pelagic_bird_normalize) # 100 x 100
hist(pelagic_bird_normalize) # show histogram of values (though mostly values near 1)
freq(pelagic_bird_normalize) # show frequency of values (though will round to 0 and 1)

#####################################
#####################################

# Export data
## Raster data
writeRaster(pelagic_normalize, filename = file.path(raster_dir, "pelagic_normalize.grd"), overwrite = T)
writeRaster(pelagic_bird_normalize, filename = file.path(raster_dir, "pelagic_bird_normalize.grd"), overwrite = T)

## Intermediate data
writeRaster(pelagic_normalize, filename = file.path(intermediate_dir, "pelagic_normalize.grd"), overwrite = T)
writeRaster(pelagic_bird5070, filename = file.path(intermediate_dir, "pelagic_bird5070.grd"), overwrite = T)
writeRaster(pelagic_birds, filename = file.path(intermediate_dir, "pelagic_birds.grd"), overwrite = T)
writeRaster(pelagic_bird_normalize, filename = file.path(intermediate_dir, "pelagic_bird_normalize.grd"), overwrite = T)
