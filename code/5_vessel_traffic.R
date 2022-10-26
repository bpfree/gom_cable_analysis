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
ais_tracks_dir <- "data/a_raw_data/AISVesselTransitCounts2019.gdb"

### Output directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
ais_tracks_gpkg <- "data/b_intermediate_data/gom_vessel.gpkg"

# View layer names within geodatabase
sf::st_layers(dsn = ais_tracks_dir,
              do_count = TRUE)

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Load AIS data (source: https://marinecadastre.gov/downloads/data/ais/ais2019/AISVesselTransitCounts2019.zip)
## Metadata: https://www.fisheries.noaa.gov/inport/item/61037
### All vessels


### Cargo vessels


### Fishing vessels


### Passenger vessels


### Pleasure craft and sailing vessels


### Tanker vessels


### Tug and tow vessels

