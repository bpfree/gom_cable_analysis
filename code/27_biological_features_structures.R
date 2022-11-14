############################################
### 27. Biological Features / Structures ###
############################################

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
psbf_lrf_dir <- "data/a_raw_data/NAZ_PSBF_LRF_withBuffers"
boem_psbf_dir <- "data/a_raw_data/boem_psbf"

### Output directories
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
biological_structures_features_gpkg <- "data/b_intermediate_data/biological_features_structures.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################
#####################################

# Potentially sensitive biological features
psbf_lrf <- st_read(dsn = psbf_lrf_dir, layer = "NAZ_PSBF_LRF_withBuffers") %>%
  # reproject the coordinate reference system to match BOEM call areas
  st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)

boem_psbf <- st_read(dsn = boem_psbf_dir, layer = "BOEM_PSBFS_SW_DW_Merged")
