############################
### 2. Seagrass Habitats ###
############################

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
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directories
tpwd_seagrass_dir <- "data/a_raw_data/TPWD_Seagrass"
gom_seagrass_dir <- "data/a_raw_data/GulfwideSAV"
noaa_seagrass_dir <- "data/a_raw_data/Seagrasses/Seagrasses.gdb"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
seagrass_gpkg <- "data/b_intermediate_data/gom_seagrass.gpkg"

# View layer names within geodatabase
sf::st_layers(dsn = noaa_seagrass_dir,
              do_count = TRUE)

# View layer names within geopackage
sf::st_layers(dsn = analysis_gpkg,
              do_count = TRUE)

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- sf::st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################
#####################################

# Dissolve seagrass habitat function
## This function will take the imported data and reduce it down to a single feature.
clean_seagrass <- function(seagrass_data){
  seagrass_layer <- seagrass_data %>%
    # reproject the coordinate reference system
    sf::st_transform("EPSG:5070") %>%
    # have only the seagrass data that exists study area
    sf::st_intersection(study_area) %>%
    # create field to define as "seagrass"
    dplyr::mutate(layer = "seagrass") %>%
    # group all features by the "layer" and "value" fields to then have a single feature
    # "value" will get pulled in from the study area layer
    dplyr::group_by(layer,
                    value) %>%
    # summarise the single feature
    dplyr::summarise()
  return(seagrass_layer)
}

#####################################
#####################################

# Load seagrass layers
## TPWD Seagrass (map viewer: https://tpwd.maps.arcgis.com/apps/webappviewer/index.html?id=af7ff35381144b97b38fe553f2e7b562)
### 2012 data (source: https://tpwd.texas.gov/gis/resources/tpwd-seagrass.zip)
seagrass_tpwd <- sf::st_read(dsn = tpwd_seagrass_dir, layer = "TPWD_Seagrass_8_17_12") %>%
  # due to overlapping features, need to make invalid data valid
  sf::st_make_valid() %>%
  # now run through the clean function to have single data observation
  clean_seagrass()

### 2015 data (source: https://tpwd.texas.gov/gis/resources/tpwd-seagrass.zip)
#### Original data download site: https://tpwd.texas.gov/landwater/water/habitats/coastal-fisheries-habitat-assessment-team/
seagrass_tpwd_christmas_west_bays <- sf::st_read(dsn = tpwd_seagrass_dir, layer = "TPWD_ChristmasBay_WestBay_Seagrass") %>%
  # due to overlapping features, need to make invalid data valid
  sf::st_make_valid() %>%
  # now run through the clean function to have single data observation
  clean_seagrass()

## NOAA Seagrass (2012) (source: https://tpwd.texas.gov/gis/resources/tpwd-seagrass.zip)
### Note: None of these data fall within the present study area
seagrass_noaa_2012 <- sf::st_read(dsn = tpwd_seagrass_dir, layer = "NOAA_Seagrass_8_17_12") %>%
  # due to overlapping features, need to make invalid data valid
  sf::st_make_valid() %>%
  # now run through the clean function to have single data observation
  clean_seagrass()

## NOAA US + Territories (source: ftp://ftp.coast.noaa.gov/pub/MSP/Seagrasses.zip)
### Alternative data accessed here: https://marinecadastre.gov/downloads/data/mc/Seagrass.zip (has 3 fewer features -- none in study area)
seagrass_noaa <- sf::st_read(dsn = noaa_seagrass_dir, layer = "Seagrasses") %>%
  # now run through the clean function to have single data observation
  clean_seagrass() %>%
  # change field "Shape" to be "geometry" to match other data layers
  dplyr::rename("geometry" = "Shape")

## Gulfwide Seagrass (source: https://www.ncei.noaa.gov/waf/data-atlas-waf/biotic/documents/GulfwideSAV.zip)
seagrass_tx_ncei <- sf::st_read(dsn = gom_seagrass_dir, layer = "Seagrass_ALFLMSTX") %>%
  clean_seagrass()

#####################################

# Combine layers
seagrass_study_area <- seagrass_tpwd %>%
  # bind all datasets as unique rows
  rbind(seagrass_tpwd_christmas_west_bays,
        seagrass_noaa_2012, # these data will be in the overall bind, but will not appear in the final data
        seagrass_noaa,
        seagrass_tx_ncei) %>%
  clean_seagrass()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(seagrass_study_area, dsn = analysis_gpkg, layer = "seagrass", append = F)

## Seagrass geopackage
st_write(seagrass_tpwd, dsn = seagrass_gpkg, layer = "seagrass_tpwd", append = F)
st_write(seagrass_tpwd_christmas_west_bays, dsn = seagrass_gpkg, layer = "seagrass_tpwd_christmas_west_bays", append = F)
st_write(seagrass_noaa_2012, dsn = seagrass_gpkg, layer = "seagrass_noaa2012", append = F)
st_write(seagrass_noaa, dsn = seagrass_gpkg, layer = "seagrass_noaa", append = F)
st_write(seagrass_tx_ncei, dsn = seagrass_gpkg, layer = "seagrass_tx_ncei", append = F)
