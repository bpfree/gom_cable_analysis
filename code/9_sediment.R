###################
### 9. Sediment ###
###################

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
               sf,
               sp,
               stringr,
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
lightering_zone_dir <- "data/a_raw_data/lightering_zone.gpkg"

analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
lightering_zone_gpkg <- "data/b_intermediate_data/lightering_zone.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")