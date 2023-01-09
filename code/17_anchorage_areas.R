###########################
### 17. Anchorage Areas ###
###########################

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
anchorage_areas_dir <- "data/a_raw_data/anchorage/AnchorageAreas.gdb"

### Output directories
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
anchorage_areas_gpkg <- "data/b_intermediate_data/anchorage_areas.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- sf::st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# View layer names within geodatabase
sf::st_layers(dsn = anchorage_areas_dir,
              do_count = TRUE)

#####################################

# Load anchorage area data (source: https://marinecadastre.gov/downloads/data/mc/Anchorage.zip)
## Metadata: https://www.fisheries.noaa.gov/inport/item/48849
anchorage_areas <- sf::st_read(dsn = anchorage_areas_dir, layer = "AnchorageAreas") %>%
  # change multistring to multipolygon (for 5 features are multisurface: 654, 661, 672, 673, 721)
  sf::st_cast(to = "MULTIPOLYGON") %>%
  # make sure all geometries are valid
  sf::st_make_valid() %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain only anchorage areas in the study area
  sf::st_intersection(study_area) %>%
  # create field called "layer" and fill with "anchorage areas" for summary
  dplyr::mutate(layer = "anchorage areas") %>%
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
sf::st_write(obj = anchorage_areas, dsn = analysis_gpkg, "anchorage_areas", append = F)

## Anchorage Areas geopackage
sf::st_write(obj = anchorage_areas, dsn = anchorage_areas_gpkg, "anchorage_areas", append = F)
