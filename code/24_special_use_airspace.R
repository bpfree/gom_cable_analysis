################################
### 24. Special Use Airspace ###
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
airspace_dir <- "data/a_raw_data/Special_Use_Airspace"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
airspace_gpkg <- "data/b_intermediate_data/nexrad.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Load special use airspace data (source: https://ais-faa.opendata.arcgis.com/datasets/dd0d1b726e504137ab3c41b21835d05b_0/)
## Metadata: https://www.arcgis.com/sharing/rest/content/items/dd0d1b726e504137ab3c41b21835d05b/info/metadata/metadata.xml?format=default&output=html
airspace <- st_read(dsn = airspace_dir, layer = "Special_Use_Airspace") %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain only special use airspace areas in the study area
  sf::st_intersection(study_area) %>%
  # create field called "layer" and fill with "special use airspace" for summary
  dplyr::mutate(layer = "special use airspace") %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  # "value" will get pulled in from the study area layer
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = airspace, dsn = analysis_gpkg, "special_use_airspace", append = F)

## NEXRAD geopackage
st_write(obj = airspace, dsn = airspace_gpkg, "special_use_airspace", append = F)
