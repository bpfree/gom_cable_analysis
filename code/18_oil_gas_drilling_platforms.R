##########################################
### 18. Oil and Gas Drilling Platforms ###
##########################################

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
bsee_platform_dir <- "data/a_raw_data/drilling_platforms"
#boem_platform_dir <- "data/a_raw_data/Platforms.gdb" # alternative

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
platforms_gpkg <- "data/b_intermediate_data/drilling_platforms.gpkg"

# View layer names within geodatabase
sf::st_layers(dsn = boem_platform_dir,
              do_count = TRUE)

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Load BSEE drilling platform data (source: https://www.data.bsee.gov/Main/Platform.aspx)
## Query: https://www.data.bsee.gov/Platform/PlatformStructures/Default.aspx
## Metadata information: https://www.data.bsee.gov/Main/Platform.aspx
### ***Note: These data came from generated CSV for all data within the query database
bsee_platforms <- read.csv(file = paste(bsee_platform_dir, "PlatStruc.csv", sep = "/")) %>%
  # remove any features that do not have longitude data
  dplyr::filter(!is.na(Longitude)) %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("Longitude", "Latitude"),
               crs = 4267) %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain only platforms in study area
  sf::st_intersection(study_area) %>%
  # Filter for platforms that have been installed but not yet removed
  dplyr::filter(Install.Date != "" & # platforms that have an install date (so not blank)
                Removal.Date == "") %>% # platforms that lack a removal date (so are blank)
  #  add a setback (buffer) distance of 152.4 meters (500 feet) around each drilling platform
  sf::st_buffer(dist = 152.4) %>%
  # create field called "layer" and fill with "drilling platform" for summary
  dplyr::mutate(layer = "drilling platform") %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  # "value" will get pulled in from the study area layer
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()

## Check units for determining cellsize of grid
st_crs(bsee_platforms, parameters = TRUE)$units_gdal

#####################################

# Alternative Method

# Load BOEM drilling platform data (source: https://www.data.boem.gov/Mapping/Files/platform.zip)
## Metadata: https://www.data.boem.gov/Mapping/Files/platform_meta.html
### Note: These data came from the mapping page: https://www.data.boem.gov/Main/Mapping.aspx#ascii
### Note: These data are different from the platform query page that BOEM has: https://www.data.boem.gov/Platform/PlatformStructures/Default.aspx
### That query page seems to mirror the data that BSEE also has
# boem_platforms <- st_read(dsn = boem_platform_dir, layer = "Platforms") %>%
#   # reproject the coordinate reference system to match study area data (EPSG:5070)
#   sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
#   # obtain only active oil and gas lease blocks in the study area
#   sf::st_intersection(study_area) %>%
#   # Filter for platforms that have been installed but not yet removed
#   dplyr::filter(!is.na(INSTALL_DATE) & # platforms that have an install date (so is not NA)
#                 is.na(REMOVAL_DATE)) %>% # platforms that lack a removal date (so is NA)
#   # create field called "layer" and fill with "drilling platform" for summary
#   dplyr::mutate(layer = "drilling platform") %>%
#   # summarise the data to get a single feature
#   dplyr::select(layer) %>%
#   # group by layer to later summarise data
#   dplyr::group_by(layer) %>%
#   # summarise data to obtain single feature
#   dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = bsee_platforms, dsn = analysis_gpkg, "drilling_platforms", append = F)

## Drilling Platforms geopackage
st_write(obj = bsee_platforms, dsn = platforms_gpkg, "drilling_platforms", append = F)
