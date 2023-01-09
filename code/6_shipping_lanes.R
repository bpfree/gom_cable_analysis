#########################
### 6. Shipping Lanes ###
#########################

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
ship_lanes_dir <- "data/a_raw_data/shippinglanes"
texas_county_dir <- "data/a_raw_data/texas_county"
texas_county_ship <- "data/a_raw_data/tx_county_ship"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
vessel_gpkg <- "data/b_intermediate_data/gom_vessel.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

# Texas county data (source: https://gis-txdot.opendata.arcgis.com/datasets/TXDOT::texas-county-boundaries-detailed/explore?location=31.059220%2C-100.077018%2C6.58)
## Summary details: https://gis-txdot.opendata.arcgis.com/datasets/TXDOT::texas-county-boundaries-detailed/about
texas_county <- st_read(dsn = texas_county_dir, layer = "County") %>%
  # match coordinate reference system as study area
  sf::st_transform("EPSG:5070") %>%
  # obtain only parts of counties that have coastlines in study area
  sf::st_intersection(study_area)

# Sort the list of counties bounded to the study area
list(sort(texas_county$CNTY_NM))

### We see that five counties as potential landing areas for the cabling:
#### Brazoria
#### Chambers
#### Galveston
#### Harris
#### Jefferson

#####################################
#####################################

# Clean and dissolve Texas shipping lanes
## This function will take the imported data and reduce it down to a single feature.
vessel_function <- function(vessel_data){
  vessel_lane <- vessel_data %>%
    # change coordinate reference system to match all other data (EPSG:5070)
    sf::st_transform("EPSG:5070") %>%
    # create setback (buffer) of 500 meters
    sf::st_buffer(dist = 500) %>%
    # change to multipolygon from multistring (to match shipping lane data)
    sf::st_cast(to = "MULTIPOLYGON") %>%
    # create fields to define as "shipping lane" and "value" populated with 0
    dplyr::mutate(layer = "shipping lane",
                  value = 0) %>%
    # group all features by the "layer" and "value" fields to then have a single feature
    # "value" will get pulled in from the study area layer
    dplyr::group_by(layer,
                    value) %>%
    # summarise all features to become single feature
    dplyr::summarise()
  return(vessel_lane)
}

#####################################
#####################################

# Load shipping lane data
## Shipping lanes (raw data: http://encdirect.noaa.gov/theme_layers/data/shipping_lanes/shippinglanes.zip)
### These are federal water shipping lanes
shipping_lanes <- sf::st_read(dsn = ship_lanes_dir, layer = "shippinglanes") %>%
  # change coordinate reference system to match all other data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>%
  # have only the shipping lane data that passes through study area
  sf::st_intersection(study_area) %>%
  # create setback (buffer) of 500 meters
  sf::st_buffer(dist = 500) %>%
  # change to multipolygon from multistring (to match shipping lane data)
  sf::st_cast(to = "MULTIPOLYGON") %>%
  # create field called "layer" and designate as shipping lane
  dplyr::mutate(layer = "shipping lane") %>%
  # group by layer and value to have all features become one
  dplyr::group_by(layer,
                  value) %>%
  # summarise all features to become single feature
  dplyr::summarise()

st_crs(shipping_lanes, parameters = TRUE)$units_gdal

#####################################

## Texas shipping channels (i.e., state waters)
## Source: RRC (all layers by county: https://www.rrc.texas.gov/resource-center/research/data-sets-available-for-download/)
## Actual county data are obtainable from here: https://mft.rrc.texas.gov/link/7a5577fc-e325-4d7b-bc41-daf23f4b6e80)
## List of county FIPS codes: https://www.rrc.texas.gov/about-us/locations/oil-gas-counties-districts/
## FIPS Codes for the 5 affected counties
#### Brazoria -- 039
#### Chambers -- 071
#### Galveston -- 167
#### Harris -- 201
#### Jefferson -- 245

### Load raw data
brazoria_ship <- st_read(dsn = texas_county_ship, layer = "ship039l") %>%
  vessel_function()
chambers_ship <- st_read(dsn = texas_county_ship, layer = "ship071l") %>%
  vessel_function()
galveston_ship <- st_read(dsn = texas_county_ship, layer = "ship167l") %>%
  vessel_function()
harris_ship <- st_read(dsn = texas_county_ship, layer = "ship201l") %>%
  vessel_function()
jefferson_ship <- st_read(dsn = texas_county_ship, layer = "ship245l") %>%
  vessel_function()

#####################################

### Combine Texas shipping lane
texas_ship <- brazoria_ship %>%
  # binding all county datasets as unique rows
  rbind(chambers_ship,
        galveston_ship,
        harris_ship,
        jefferson_ship) %>%
  # group data by layer and value fields
  dplyr::group_by(layer,
                  value) %>%
  # summarise data based on those fields to return a single feature
  dplyr::summarise()

st_crs(texas_ship, parameters = TRUE)$units_gdal

#####################################
#####################################

# Combine shipping lane data
shipping500 <- shipping_lanes %>%
  # combine federal shipping lane data with Texas state shipping data
  rbind(texas_ship) %>%
  # group by layer to have all features become one
  dplyr::group_by(layer,
                  value) %>%
  # summarise all features to become single feature
  dplyr::summarise()

#####################################

# Shipping lanes only in study area
shipping_study <- shipping500 %>%
  dplyr::mutate(name = "shipping lane") %>%
  dplyr::group_by(name) %>%
  dplyr::summarise() %>%
  st_intersection(study_area)

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(shipping_study, dsn = analysis_gpkg, layer = "shipping_lane", append = F)

## Shipping lanes geopackage
st_write(shipping_study, dsn = vessel_gpkg, layer = "shipping_lane", append = F)

### Texas shipping lanes
st_write(brazoria_ship, dsn = vessel_gpkg, layer = "brazoria_ship", append = F)
st_write(chambers_ship, dsn = vessel_gpkg, layer = "chambers_ship", append = F)
st_write(galveston_ship, dsn = vessel_gpkg, layer = "galveston_ship", append = F)
st_write(harris_ship, dsn = vessel_gpkg, layer = "harris_ship", append = F)
st_write(jefferson_ship, dsn = vessel_gpkg, layer = "jefferson_ship", append = F)

### Texas shipping combined
st_write(texas_ship, dsn = vessel_gpkg, layer = "texas_ship_combined", append = F)
st_write(shipping500, dsn = vessel_gpkg, layer = "texas_ship500_combined", append = F)
