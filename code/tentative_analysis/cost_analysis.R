##########################
### Cost Data Creation ###
##########################

# Clear environment
rm(list = ls())

# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr,
               fasterize,
               ggplot2,
               plyr,
               ncdf4, # can be used to read the bathymetry data (as they are an netCDF file [.nc])
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
data_dir <- "data/c_analysis_data/gom_cable_study.gpkg"
raster_dir <- "data/d_raster_data"

### Output directories
tentative_analysis <- "code/tentative_analysis"

#####################################

# View layer names within geodatabase
sf::st_layers(dsn = data_dir,
              do_count = TRUE)

# Load data
## National Security
### Special use Airspace
special_use_airspace <- st_read(dsn = data_dir, layer = "special_use_airspace") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5)

## Natural & Cultural Resources
### Fish Havens
fish_haven <- st_read(dsn = data_dir, layer = "fish_havens") %>%
  # add cost value of 0.3
  dplyr::mutate(value = 0.3)

### Potentially Sensitive Biological Features and Low Relief Features
psbf_lrf <- st_read(dsn = data_dir, layer = "psbf_lrf") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5)

### BOEM Potentially Sensitive Biological Features and Low Relief Features
boem_psbf <- st_read(dsn = data_dir, layer = "boem_psbf") %>%
  # add cost value of 0.8
  dplyr::mutate(value = 0.8)

### Existing Coral Habitat Areas of Particular Concern and Coral Amendment 9 Habitat Areas of Particular Concern
coral_hapc <- st_read(dsn = data_dir, layer = "coral_hapc") %>%
  # add cost value of 0.8
  dplyr::mutate(value = 0.8)

## Industry, Navigation & Transportation
### Federal Lightering Rendezvous Areas
lightering_zones <- st_read(dsn = data_dir, layer = "lightering_zones") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5)

### Areas Outside Carbon Capture Lease Blocks
not_carbon_capture <- st_read(dsn = data_dir, layer = "not_carbon_capture_lease_blocks") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5)

### NEXRAD Sites (35 - 70km setback)
not_carbon_capture <- st_read(dsn = data_dir, layer = "nexrad70km") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5)

## Economics
### NREL - Net Value 2015

## Logistics
### Depth / Bathymetry
bathymetry <- raster::raster(paste(raster_dir, "bathymetry.grd", sep = "/"))

### Slope
slope <- raster::raster(paste(raster_dir, "slope.grd", sep = "/"))