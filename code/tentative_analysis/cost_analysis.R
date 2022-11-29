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
least_cost_gpkg <- "data/e_least_cost_path/least_cost_path_analysis.gpkg"
raster_dir <- "data/d_raster_data"

### Output directories
tentative_analysis <- "code/tentative_analysis"
least_cost_dir <- "data/e_least_cost_path"

#####################################

# View layer names within geodatabase
sf::st_layers(dsn = data_dir,
              do_count = TRUE)

#####################################
#####################################

# Load data
study_area <- st_read(dsn = data_dir, layer = "gom_study_area_marine")

## Raster grid
gom_raster <- raster::raster(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

## Constraints grid
constraints <- raster::raster(paste(least_cost_dir, "constraints_raster.grd", sep = "/"))
arcgis_constraints <- raster::raster(paste(least_cost_dir, "arc_constraints_raster.grd", sep = "/"))

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

prd_species <- st_read(dsn = data_dir, layer = "prd_species") %>%
  fasterize(raster = gom_raster,
            field = "value")

pelagic_birds <- raster::raster(paste(raster_dir, "pelagic_normalize.grd", sep = "/"))
extent(pelagic_birds) <- extent(gom_raster)

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

### Aids to Navigation
navigation_aid <- sf::st_read(dsn = data_dir, layer = "aids_to_navigation") %>%
  # add cost value of 0.75
  dplyr::mutate(value = 0.75) %>%
  fasterize(raster = gom_raster,
            field = "value")

### Shipping Lanes
shipping_lane <- sf::st_read(dsn = data_dir, layer = "shipping_lane") %>%
  # add cost value of 0.75
  dplyr::mutate(value = 0.75) %>%
  fasterize(raster = gom_raster,
            field = "value")

### Pipelines
pipeline <- sf::st_read(dsn = data_dir, layer = "pipelines") %>%
  # add cost value of 0.75
  dplyr::mutate(value = 0.75) %>%
  fasterize(raster = gom_raster,
            field = "value")

### AIS
#### Cargo 2019
ais_cargo <- raster::raster(paste(raster_dir, "cargo_ais2019_normalized.grd", sep = "/"))
extent(ais_cargo) <- extent(gom_raster)

#### Fishing 2019
ais_fishing <- raster::raster(paste(raster_dir, "fishing_ais2019_normalized.grd", sep = "/"))
extent(ais_fishing) <- extent(gom_raster)

#### Passenger 2019
ais_passenger <- raster::raster(paste(raster_dir, "passenger_ais2019_normalized.grd", sep = "/"))
extent(ais_passenger) <- extent(gom_raster)

#### Pleasure 2019
ais_pleasure <- raster::raster(paste(raster_dir, "pleasure_ais2019_normalized.grd", sep = "/"))
extent(ais_pleasure) <- extent(gom_raster)

#### Tanker 2019
ais_tanker <- raster::raster(paste(raster_dir, "tanker_ais2019_normalized.grd", sep = "/"))
extent(ais_tanker) <- extent(gom_raster)

#### Tugtow 2019
ais_tugtow <- raster::raster(paste(raster_dir, "tugtow_ais2019_normalized.grd", sep = "/"))
extent(ais_tugtow) <- extent(gom_raster)

#### Other 2019
ais_other <- raster::raster(paste(raster_dir, "other_ais2019_normalized.grd", sep = "/"))
extent(ais_other) <- extent(gom_raster)

## Fisheries
### Menhaden
menhaden <- raster::raster(paste(raster_dir, "menhaden_2000_2019_normalize.grd", sep = "/"))

## Economics
### NREL - Net Value 2015

## Logistics
### Depth / Bathymetry
bathymetry <- raster::raster(paste(raster_dir, "bathymetry_normalize.grd", sep = "/"))
extent(bathymetry) <- extent(gom_raster)

### Slope
slope <- raster::raster(paste(raster_dir, "slope_normalize.grd", sep = "/"))
extent(slope) <- extent(gom_raster)

##### resample? alignExtent?

#####################################
#####################################

# Create costs layer
## cover any NA values of another raster with values from any other raster (all barrier cells)
cost_raster <- raster::brick(special_use_airspace,
                             fish_haven,
                             prd_species,
                             pelagic_birds,
                             psbf_lrf,
                             boem_psbf,
                             coral_hapc,
                             lightering_zones,
                             not_carbon_capture,
                             navigation_aid,
                             shipping_lane,
                             pipeline,
                             ais_cargo,
                             ais_fishing,
                             ais_passenger,
                             ais_pleasure,
                             ais_tanker,
                             ais_tugtow,
                             #ais_other,
                             nexrad70km,
                             menhaden,
                             bathymetry,
                             slope) %>%
  raster::calc(sum, na.rm = T)

## Prepare for ArcGIS analysis
arc_gis_cost_raster <- raster::brick(cost_raster,
                                     arcgis_constraints) %>% # create a brick of the cost and constraints layer
  # sum the two layers while removing any NA values
  raster::calc(sum, na.rm = T) %>%
  # add 0.01 so there are no 0 values
  sum(., 0.01)
plot(arc_gis_cost_raster)

# Make any values above 99 (where a constraint would be) to be set as NA to remove from analysis
arc_gis_cost_raster[arc_gis_cost_raster >= 99] <- NA
arc_gis_cost_raster[arc_gis_cost_raster == 0.01] <- NA
plot(arc_gis_cost_raster)


#####################################

## Inspect new raster
minValue(cost_raster) # 0
maxValue(cost_raster) # maximum value = 6.162601
list(unique(cost_raster)) # list all unique values
res(cost_raster) # 100 x 100
hist(cost_raster) # show histogram of values (though mostly values near 1)
freq(cost_raster) # show frequency of values (though will round to 0 and 1)

#####################################
#####################################

# Export data
## Raster data
writeRaster(cost_raster, filename = file.path(tentative_analysis, "cost_raster.grd"), overwrite = T)
writeRaster(cost_raster, filename = file.path(least_cost_dir, "cost_raster.grd"), overwrite = T)

writeRaster(arc_gis_cost_raster, filename = file.path(least_cost_dir, "arcgis_cost_raster.grd"), overwrite = T)
