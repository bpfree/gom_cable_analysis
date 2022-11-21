################################################
### 30. Shrimp Electric Logbook 2015 - 2019  ###
################################################

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
shrimp_dir <- "data/a_raw_data/shrimp_logbook"
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
raster_dir <- "data/d_raster_data"