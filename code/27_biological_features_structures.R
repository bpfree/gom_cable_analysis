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
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
biological_structures_features_gpkg <- "data/b_intermediate_data/biological_features_structures.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Potentially sensitive biological features
## Flower Garden Banks
psbf_lrf <- st_read(dsn = psbf_lrf_dir, layer = "NAZ_PSBF_LRF_withBuffers") %>%
  # reproject the coordinate reference system
  st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # filter for only potentially sensitive biological features or low relief features
  dplyr::filter(Zone %in% c("PSBF",
                            "LRF")) %>%
  # obtain biological features data within study area
  st_intersection(study_area) %>%
  # create field called "layer" and fill with "biological features" for summary
  dplyr::mutate(layer = "biological features") %>%
  #  add a setback (buffer) distance of 304.8 meter (1000 feet) around potentially sensitive biological features or low relief features
  sf::st_buffer(304.8) %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  # "value" will get pulled in from the study area layer
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()
  
st_crs(psbf_lrf, parameters = TRUE)$units_gdal

## BOEM
boem_psbf <- st_read(dsn = boem_psbf_dir, layer = "BOEM_PSBFS_SW_DW_Merged") %>%
  # reproject the coordinate reference system
  st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain biological feature data within study area
  st_intersection(study_area) %>%
  # create field called "layer" and fill with "biological features" for summary
  dplyr::mutate(layer = "biological features") %>%
  # filter to include only potentially sensitive biological features (use list(unique(boem_psbf$FEATURE_TY)) to see options)
  dplyr::filter(FEATURE_TY %in% c("PSBF",
                                  "Potentially Sensitive Bi*")) %>%
  #  add a setback (buffer) distance of 76.2 meter (250 feet) around potentially sensitive biological features or low relief features
  sf::st_buffer(76.2) %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  # "value" will get pulled in from the study area layer
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()

st_crs(boem_psbf, parameters = TRUE)$units_gdal

#####################################
#####################################

g <- ggplot() + 
  geom_sf(data = study_area, fill = NA, color = "blue", linetype = "dashed") +
  geom_sf(data = boem_psbf, color = "orange") +
  geom_sf(data = psbf_lrf, fill = NA, color = "red", linetype = "dashed")
g

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = psbf_lrf, dsn = analysis_gpkg, "psbf_lrf", append = F)
st_write(obj = boem_psbf, dsn = analysis_gpkg, "boem_psbf", append = F)

## Potentially sensitive biology geopackage
st_write(obj = psbf_lrf, dsn = biological_structures_features_gpkg, "psbf_lrf", append = F)
st_write(obj = boem_psbf, dsn = biological_structures_features_gpkg, "boem_psbf", append = F)
