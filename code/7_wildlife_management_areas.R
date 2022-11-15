#############################
### 7. Conservation Areas ###
#############################

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
### Input directories
wma_dir <- "data/a_raw_data/texas_wma"
state_parks_dir <- "data/a_raw_data/tx_state_parks"
fws_nrb_dir <- "data/a_raw_data/fws_nrb.gdb"
fgbnms_dir <- "data/a_raw_data/fgbnms_py"

### Output directories
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
conservation_areas_gpkg <- "data/b_intermediate_data/gom_conservation_areas.gpkg"

#####################################

# View layer names within geodatabase
## FWS National Realty Boundaries directory
sf::st_layers(dsn = fws_nrb_dir,
              do_count = TRUE)

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################
#####################################

# Clean and dissolve conservation areas
## This function will take the imported data and reduce it down to a single feature.
conservation_areas_function <- function(conservation_data){
  conservation_areas <- conservation_data %>%
    # reproject the coordinate reference system to match study area data (EPSG:5070)
    sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
    # obtain only conservation management areas that fall within study area
    sf::st_intersection(study_area) %>%
    # create field "layer" to set
    dplyr::mutate(layer = "conservation area") %>%
    # group by setback to have all features become one
    dplyr::group_by(layer,
                    value) %>%
    # summarise all features to become single feature
    dplyr::summarise()
  return(conservation_areas)
}

#####################################
#####################################

# Load conservation areas layers
## Texas Wildlife Management Areas (source: https://tpwd.texas.gov/gis/resources/wildlife-management-areas.zip)
texas_wma <- st_read(dsn = wma_dir, layer = "WildlifeManagementAreas") %>%
  conservation_areas_function()

## Texas State Parks (source: https://tpwd.texas.gov/gis/resources/tpwd-statepark-boundaries.zip)
texas_state_parks <- st_read(dsn = state_parks_dir, layer = "TPWDStateParksBoundary") %>%
  # clean the data to prepare
  conservation_areas_function()

## FWS National Realty Boundaries (source: https://gis-fws.opendata.arcgis.com/datasets/fws-national-realty-boundaries/explore?location=28.651320%2C-94.276551%2C8.00)
## Metadata: 
fws_nrb <- st_read(dsn = fws_nrb_dir, layer = "FWSBoundaries") %>%
  # clean the data to prepare
  conservation_areas_function() %>%
  dplyr::rename("geometry" = "SHAPE")

## Flower Garden Banks National Marine Sanctuary (source: https://sanctuaries.noaa.gov/media/gis/fgbnms_py.zip)
## Metadata: https://nmssanctuaries.blob.core.windows.net/sanctuaries-prod/media/gis/fgbnms_py.pdf
fgbnms <- st_read(dsn = fgbnms_dir, layer = "FGBNMS_py") %>%
  # clean the data to prepare
  conservation_areas_function()

#####################################

# Combine conservation areas
texas_conservation <- texas_wma %>%
  # combine wildlife management areas with other datasets
  rbind(texas_state_parks,
        fws_nrb,
        fgbnms) %>%
  # group by layer
  dplyr::group_by(layer,
                  value) %>%
  # summarise to have single feature
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(texas_conservation, dsn = analysis_gpkg, layer = "conservation_areas", append = F)

## Conservation Areas geopackage
### Texas Wildlife Management Areas
st_write(texas_wma, dsn = conservation_areas_gpkg, layer = "texas_wma", append = F)

### Texas State Parks
st_write(texas_state_parks, dsn = conservation_areas_gpkg, layer = "texas_state_parks", append = F)

### FWS National Realty Boundaries
st_write(fws_nrb, dsn = conservation_areas_gpkg, layer = "fws_nrb", append = F)

### Flower Garden Banks National Marine Sanctuary
st_write(fgbnms, dsn = conservation_areas_gpkg, layer = "fgbnms", append = F)
