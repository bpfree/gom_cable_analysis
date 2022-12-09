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
carbon_capture_dir <- "data/a_raw_data/GOM_Potential_CCUS_BlocksForSuitabilityModelRun"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
carbon_capture_gpkg <- "data/b_intermediate_data/carbon_capture.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Data came from Tershara Matthews (Tershara.Matthews@boem.gov)
## For further questions, direct them to BOEM

### Carbon capture underground storage lease blocks
carbon_capture <- st_read(dsn = carbon_capture_dir, layer = "GOM_Potential_CCUS_Blocks") %>%
  # reproject the coordinate reference system
  st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # create field called "layer" and fill with "carbon capture" for summary along with "value" field with 0
  dplyr::mutate(layer = "carbon capture",
                value = 0) %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()

not_carbon_capture <- study_area %>%
  # obtain data outside carbon capture within study area (erase carbon capture area from study area)
  rmapshaper::ms_erase(carbon_capture)

g <- ggplot() + 
  geom_sf(data = study_area, fill = NA, color = "blue", linetype = "dashed") +
  geom_sf(data = carbon_capture, color = "orange") +
  geom_sf(data = not_carbon_capture, fill = NA, color = "red", linetype = "dashed")
g

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = not_carbon_capture, dsn = analysis_gpkg, "not_carbon_capture_lease_blocks", append = F)

## Carbon capture geopackage
st_write(obj = carbon_capture, dsn = carbon_capture_gpkg, "not_carbon_capture_lease_blocks", append = F)
