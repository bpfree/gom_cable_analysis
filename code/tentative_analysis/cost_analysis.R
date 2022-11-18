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
               terra,
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

#####################################
#####################################

# Load data
## Raster grid
gom_raster <- raster::raster(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

## National Security
### Special use Airspace
special_use_airspace <- st_read(dsn = data_dir, layer = "special_use_airspace") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  fasterize(raster = gom_raster,
            field = "value")

## Natural & Cultural Resources
### Fish Havens
fish_haven <- st_read(dsn = data_dir, layer = "fish_havens") %>%
  # add cost value of 0.3
  dplyr::mutate(value = 0.3) %>%
  fasterize(raster = gom_raster,
            field = "value")

### Potentially Sensitive Biological Features and Low Relief Features
psbf_lrf <- st_read(dsn = data_dir, layer = "psbf_lrf") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  fasterize(raster = gom_raster,
            field = "value")

### BOEM Potentially Sensitive Biological Features and Low Relief Features
boem_psbf <- st_read(dsn = data_dir, layer = "boem_psbf") %>%
  # add cost value of 0.8
  dplyr::mutate(value = 0.8) %>%
  fasterize(raster = gom_raster,
            field = "value")

### Existing Coral Habitat Areas of Particular Concern and Coral Amendment 9 Habitat Areas of Particular Concern
coral_hapc <- st_read(dsn = data_dir, layer = "coral_hapc") %>%
  # add cost value of 0.8
  dplyr::mutate(value = 0.8) %>%
  fasterize(raster = gom_raster,
            field = "value")

## Industry, Navigation & Transportation
### Federal Lightering Rendezvous Areas
lightering_zones <- st_read(dsn = data_dir, layer = "lightering_zones") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  fasterize(raster = gom_raster,
            field = "value")

### Areas Outside Carbon Capture Lease Blocks
not_carbon_capture <- st_read(dsn = data_dir, layer = "not_carbon_capture_lease_blocks") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  fasterize(raster = gom_raster,
            field = "value")

### NEXRAD Sites (35 - 70km setback)
nexrad70km <- st_read(dsn = data_dir, layer = "nexrad70km") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  fasterize(raster = gom_raster,
            field = "value")

## Fisheries
### Menhaden
menhaden <- raster::raster(paste(raster_dir, "menhaden_2000_2019_normalize.grd", sep = "/"))

## Economics
### NREL - Net Value 2015

## Logistics
### Depth / Bathymetry
bathymetry <- raster::raster(paste(raster_dir, "bathymetry_normalize.grd", sep = "/"))

### Slope
slope <- raster::raster(paste(raster_dir, "slope_normalize.grd", sep = "/"))

#####################################
#####################################

# Create costs layer
## cover any NA values of another raster with values from any other raster (all barrier cells)
cost_raster <- raster::brick(special_use_airspace,
                             fish_haven,
                             psbf_lrf,
                             boem_psbf,
                             coral_hapc,
                             lightering_zones,
                             not_carbon_capture,
                             nexrad70km,
                             menhaden,
                             bathymetry,
                             slope) %>%
  raster::calc(sum, na.rm = T)

#####################################

## Inspect new raster
minValue(cost_raster)
maxValue(cost_raster) # maximum value = 0.9961739
list(unique(cost_raster)) # list all unique values
res(cost_raster) # 100 x 100
hist(cost_raster) # show histogram of values (though mostly values near 1)
freq(cost_raster) # show frequency of values (though will round to 0 and 1)

#####################################
#####################################

# Export data
## Raster data
writeRaster(cost_raster, filename = file.path(tentative_analysis, "cost_raster.grd"), overwrite = T)
