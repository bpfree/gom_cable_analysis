#######################
### 11. Fish Havens ###
#######################

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
fish_haven_dir <- "data/a_raw_data/fish_havens.gdb"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
fish_haven_gpkg <- "data/b_intermediate_data/gom_fish_havens.gpkg"

# View layer names within geodatabase
sf::st_layers(dsn = fish_haven_dir,
              do_count = TRUE)

#####################################
#####################################

## Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Fish haven data common from NOAA's Electronic Nautical Charts (ENCs)
# They are labeled as obstruction areas as vessels are required to
# avoid them when at sea.
# To obtain the data, visit https://encdirect.noaa.gov/. A helpful
# user guide for how to interact with the map viewer and download any
# data is accessible here: https://encdirect.noaa.gov/help/encdirect_help.html#using-the-map
# To download the data follow these steps:
#   1.) Click the briefcase looking icon in the top right (Data Extract)
#   2.) Expand the Extract Coastal option
#   3.) Scroll to and then mark DangersA\Coastal_Obstruction_area
#   4.) Scroll further to Area of Interest* and pick shape to draw boundary
#   5.) Click on map and drag mouse to create desired area of interest
#   6.) Select Feature Format you want
#   7.) Click Execute
#   8.) Click generate hyperlink to download the data

# Load obstruction area data
fish_haven <- st_read(dsn = fish_haven_dir, layer = "Coastal_Obstruction_area") %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # # select only fish haven data (if that is desired output -- uncomment lines to have the filter go into effect)
  # dplyr::filter(CATOBS == "fish haven") %>%
  # obtain on fish havens in study area
  sf::st_intersection(study_area) %>%
  # add a setback (buffer) distance of 152 meters (500 feet)
  sf::st_buffer(dist = 152) %>%
  # change field "CATOBS" to be "obstruction"
  dplyr::rename("layer" = "CATOBS") %>%
  # recode obstruction values
  dplyr::mutate(layer = recode(layer,
                               "fish haven" = "obstruction",
                               # other field value is actually " " not "" (see list(unique(fish_haven$layer)) to see this before running this step)
                               " " = "obstruction")) %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  # "value" will get pulled in from the study area layer
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to reduce features to a single observation
  dplyr::summarise()

st_crs(fish_haven, parameters = TRUE)$units_gdal

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = fish_haven, dsn = analysis_gpkg, "fish_havens", append = F)

## Fish haven geopackage
st_write(obj = fish_haven, dsn = fish_haven_gpkg, "fish_havens", append = F)
