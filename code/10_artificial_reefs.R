############################
### 10. Artificial Reefs ###
############################

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
data_dir <- "data/a_raw_data/tpwd-artificial-reef-data"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
artificial_reefs_gpkg <- "data/b_intermediate_data/gom_artificial_reefs.gpkg"

#####################################
#####################################

## Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Read artificial reefs data (https://tpwd.texas.gov/gis/resources/tpwd-artificial-reef-data.zip)
## Data are from Texas Parks and Wildlife
artificial_reefs <- read.csv(paste(data_dir, "TPWD_ArtReefSites_Jan21.csv", sep = "/")) %>%
  # remove any observations that has NA values (only 1 occurrence)
  na.omit() %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("Longitude.WGS84", "Latitude.WGS84"),
               # set the coordinate reference system to WGS84
               # ***Note: Read Me for the data states data are in decimal degrees and Web Mercator (https://epsg.io/3857)
               crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
  # reproject the coordinate reference system
  st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # create setback (buffer) of 304.8 meters (1000 feet)
  st_buffer(dist = 304.8) %>%
  # limit reefs to only those within study area
  st_intersection(study_area) %>%
  # create field "layer" and populate with description "artificial reefs"
  dplyr::mutate(layer = "artificial reefs") %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  # "value" will get pulled in from the study area layer
  dplyr::group_by(layer,
                  value) %>%
  # summarise data
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(artificial_reefs, dsn = analysis_gpkg, layer = "artificial_reefs", append = F)

## Artificial reefs geopackage
st_write(artificial_reefs, dsn = artificial_reefs_gpkg, layer = "artificial_reefs", append = F)
