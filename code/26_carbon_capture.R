#######################################
### 26. Carbon Capture Lease Blocks ###
#######################################

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
carbon_capture_dir <- "data/a_raw_data/GOM_Potential_CCUS_BlocksForSuitabilityModelRun"

### Output directories
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
carbon_capture_gpkg <- "data/b_intermediate_data/carbon_capture.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################
#####################################

# Data came from Tershara Matthews (Tershara.Matthews@boem.gov)
## For further questions, direct them to BOEM

### Carbon capture underground storage lease blocks
carbon_capture <- st_read(dsn = carbon_capture_dir, layer = "GOM_Potential_CCUS_Blocks") %>%
  # reproject the coordinate reference system to match BOEM call areas
  st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain sensor data within study area
  st_intersection(study_area) %>%
  # create field called "layer" and fill with "environmental sensor" for summary
  dplyr::mutate(layer = "carbon capture") %>%
  # group by layer to later summarise data
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = carbon_capture, dsn = analysis_gpkg, "carbon_capture_lease_blocks", append = F)

## Coral HAPC geopackage
st_write(obj = carbon_capture, dsn = carbon_capture_gpkg, "carbon_capture_lease_blocks", append = F)
