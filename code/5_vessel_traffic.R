#########################
### 5. Vessel Traffic ###
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
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directory
ais_tracks_dir <- "data/a_raw_data/ais_counts_2019"
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
raster_dir <- "data/d_raster_data"

### Output directory
intermediate_dir <- "data/b_intermediate_data"

#####################################
#####################################

# Load data
## Study area (to clip habitats to only that area)
study_area <- sf::st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

## Raster grid
gom_raster <- terra::rast(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

#####################################

## Load AIS data (2019)
### Transit counts: https://marinecadastre.gov/downloads/data/ais/ais2019/AISVesselTransitCounts2019.zip)
### Metadata: https://www.fisheries.noaa.gov/inport/item/61037
### ***Note: these data were cleaned in ArcGIS due to R and QGIS cannot open rasters from an ESRI .gdb

#### Cargo vessels
cargo_ais2019 <- terra::rast(paste(ais_tracks_dir, "AIS19_Cargo1.tif", sep = "/"))

#### Fishing vessels
fishing_ais2019 <- terra::rast(paste(ais_tracks_dir, "AIS19_Fishing1.tif", sep = "/"))

#### Passenger vessels
passenger_ais2019 <- terra::rast(paste(ais_tracks_dir, "AIS19_Passenger1.tif", sep = "/"))

#### Pleasure craft and sailing vessels
pleasure_ais2019 <- terra::rast(paste(ais_tracks_dir, "AIS19_Pleasure1.tif", sep = "/"))

#### Tanker vessels
tanker_ais2019 <- terra::rast(paste(ais_tracks_dir, "AIS19_Tanker1.tif", sep = "/"))

#### Tug and tow vessels
tugtow_ais2019 <- terra::rast(paste(ais_tracks_dir, "AIS19_TugTow1.tif", sep = "/"))

## Vessel tracks (other): https://marinecadastre.gov/downloads/data/ais/ais2019/AISVesselTracks2019.zip
### Metadata: https://www.fisheries.noaa.gov/inport/item/59927
### ***Note: these data were cleaned in ArcGIS due to R and QGIS cannot open rasters from an ESRI .gdb

#### Other vessels
other_ais2019 <- terra::rast(paste(ais_tracks_dir, "AIS19_Other1.tif", sep = "/"))

#####################################
#####################################

# Create normalization functions
## Linear function
linear_function <- function(raster, gom_raster, study_area){
  # define projection (EPSG:5070)
  crs <- "EPSG:5070"
  
  # reproject into coordinate reference system
  raster_5070 <- terra::project(x = raster,
                                y = crs,
                                res = 100) # resolution should be put in meters as EPSG:5070 is in meters, no longer degrees
  
  # calculate minimum value
  min <- terra::minmax(raster_5070)[1,]
  
  # recalculate maximum value
  max <- terra::minmax(raster_5070)[2,]
  
  # create linear function
  normalize <- (raster_5070[] - min) / (max - min)
  
  # set values back to the newly projected raster
  vessel_normalize <- terra::setValues(raster_5070, normalize) %>%
    # crop to the study area (will be for the extent)
    terra::crop(gom_raster) %>%
    # mask to study area
    terra::mask(study_area)
  
  # return the raster
  return(vessel_normalize)
}

#####################################
#####################################

# Normalize vessel traffic
cargo_normalized <- cargo_ais2019 %>%
  linear_function(., gom_raster, study_area)

fishing_normalized <- fishing_ais2019 %>%
  linear_function(., gom_raster, study_area)

passenger_normalized <- passenger_ais2019 %>%
  linear_function(., gom_raster, study_area)

pleasure_normalized <- pleasure_ais2019 %>%
  linear_function(., gom_raster, study_area)

tanker_normalized <- tanker_ais2019 %>%
  linear_function(., gom_raster, study_area)

tugtow_normalized <- tugtow_ais2019 %>%
  linear_function(., gom_raster, study_area)

other_normalized <- other_ais2019 %>%
  linear_function(., gom_raster, study_area)

#####################################
#####################################

# Export data
## Raster data
terra::writeRaster(cargo_normalized, filename = file.path(raster_dir, "cargo_ais2019_normalized.grd"), overwrite = T)
terra::writeRaster(fishing_normalized, filename = file.path(raster_dir, "fishing_ais2019_normalized.grd"), overwrite = T)
terra::writeRaster(passenger_normalized, filename = file.path(raster_dir, "passenger_ais2019_normalized.grd"), overwrite = T)
terra::writeRaster(pleasure_normalized, filename = file.path(raster_dir, "pleasure_ais2019_normalized.grd"), overwrite = T)
terra::writeRaster(tanker_normalized, filename = file.path(raster_dir, "tanker_ais2019_normalized.grd"), overwrite = T)
terra::writeRaster(tugtow_normalized, filename = file.path(raster_dir, "tugtow_ais2019_normalized.grd"), overwrite = T)
terra::writeRaster(other_normalized, filename = file.path(raster_dir, "other_ais2019_normalized.grd"), overwrite = T)
