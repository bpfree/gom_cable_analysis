##############################
### 37. Cost Data Creation ###
##############################

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

### Output directory
#### Least Cost Path directory
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
gom_raster <- terra::rast(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

## Constraints grid
constraints <- terra::rast(paste(least_cost_dir, "constraints_raster.grd", sep = "/"))

## National Security
### Special use Airspace
special_use_airspace <- st_read(dsn = data_dir, layer = "special_use_airspace") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

## Natural & Cultural Resources
### Fish Havens
fish_haven <- st_read(dsn = data_dir, layer = "fish_havens") %>%
  # add cost value of 0.3
  dplyr::mutate(value = 0.3) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

prd_species <- st_read(dsn = data_dir, layer = "prd_species") %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

pelagic_birds <- terra::rast(paste(raster_dir, "pelagic_normalize.grd", sep = "/"))
terra::ext(pelagic_birds) <- terra::ext(gom_raster) # give the pelagic birds the same extent as the GOM raster

### Potentially Sensitive Biological Features and Low Relief Features
psbf_lrf <- st_read(dsn = data_dir, layer = "psbf_lrf") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

### BOEM Potentially Sensitive Biological Features and Low Relief Features
boem_psbf <- st_read(dsn = data_dir, layer = "boem_psbf") %>%
  # add cost value of 0.8
  dplyr::mutate(value = 0.8) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

### Existing Coral Habitat Areas of Particular Concern and Coral Amendment 9 Habitat Areas of Particular Concern
coral_hapc <- st_read(dsn = data_dir, layer = "coral_hapc") %>%
  # add cost value of 0.8
  dplyr::mutate(value = 0.8) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

## Industry, Navigation & Transportation
### Federal Lightering Rendezvous Areas
lightering_zones <- st_read(dsn = data_dir, layer = "lightering_zones") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

### Areas Outside Carbon Capture Lease Blocks
not_carbon_capture <- st_read(dsn = data_dir, layer = "not_carbon_capture_lease_blocks") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

### NEXRAD Sites (35 - 70km setback)
nexrad70km <- st_read(dsn = data_dir, layer = "nexrad70km") %>%
  # add cost value of 0.5
  dplyr::mutate(value = 0.5) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

### Aids to Navigation
navigation_aid <- sf::st_read(dsn = data_dir, layer = "aids_to_navigation") %>%
  # add cost value of 0.75
  dplyr::mutate(value = 0.75) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

### Shipping Lanes
shipping_lane <- sf::st_read(dsn = data_dir, layer = "shipping_lane") %>%
  # add cost value of 0.75
  dplyr::mutate(value = 0.75) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

### Pipelines
pipeline <- sf::st_read(dsn = data_dir, layer = "pipelines") %>%
  # add cost value of 0.75
  dplyr::mutate(value = 0.75) %>%
  # rasterize data
  terra::rasterize(y = gom_raster,
                   field = "value")

### AIS
#### Cargo 2019
ais_cargo <- terra::rast(paste(raster_dir, "cargo_ais2019_normalized.grd", sep = "/"))
terra::ext(ais_cargo) <- terra::ext(gom_raster) # give the AIS cargo the same extent as the GOM raster

#### Fishing 2019
ais_fishing <- terra::rast(paste(raster_dir, "fishing_ais2019_normalized.grd", sep = "/"))
terra::ext(ais_fishing) <- terra::ext(gom_raster) # give the AIS fishing the same extent as the GOM raster

#### Passenger 2019
ais_passenger <- terra::rast(paste(raster_dir, "passenger_ais2019_normalized.grd", sep = "/"))
terra::ext(ais_passenger) <- terra::ext(gom_raster) # give the AIS passenger the same extent as the GOM raster

#### Pleasure 2019
ais_pleasure <- terra::rast(paste(raster_dir, "pleasure_ais2019_normalized.grd", sep = "/"))
terra::ext(ais_pleasure) <- terra::ext(gom_raster) # give the AIS pleasure the same extent as the GOM raster

#### Tanker 2019
ais_tanker <- terra::rast(paste(raster_dir, "tanker_ais2019_normalized.grd", sep = "/"))
terra::ext(ais_tanker) <- terra::ext(gom_raster) # give the AIS tanker the same extent as the GOM raster

#### Tugtow 2019
ais_tugtow <- terra::rast(paste(raster_dir, "tugtow_ais2019_normalized.grd", sep = "/"))
terra::ext(ais_tugtow) <- terra::ext(gom_raster) # give the AIS tug-tow the same extent as the GOM raster

#### Other 2019
ais_other <- terra::rast(paste(raster_dir, "other_ais2019_normalized.grd", sep = "/"))
terra::ext(ais_other) <- terra::ext(gom_raster) # give the AIS other the same extent as the GOM raster

## Fisheries
### Menhaden
menhaden <- terra::rast(paste(raster_dir, "menhaden_2000_2019_normalize.grd", sep = "/"))

## Economics
### NREL - Net Value 2015

## Logistics
### Depth / Bathymetry
bathymetry <- terra::rast(paste(raster_dir, "bathymetry_normalize.grd", sep = "/"))
terra::ext(bathymetry) <- terra::ext(gom_raster) # give the bathymetry the same extent as the GOM raster

### Slope
slope <- terra::rast(paste(raster_dir, "slope_normalize.grd", sep = "/"))
terra::ext(slope) <- terra::ext(gom_raster) # give the slope the same extent as the GOM raster

##### resample? alignExtent?

#####################################
#####################################

# Create costs layer
## cover any NA values of another raster with values from any other raster (all barrier cells)
cost_raster <- c(special_use_airspace,
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
  terra::app(sum, na.rm = T) %>%
  # remove land from cost layer
  terra::crop(gom_raster) %>%
  # mask to cost layer
  terra::mask(gom_raster)

## Cost raster without constraints
cost_rm_constraints <- c(cost_raster,
                         constraints) %>% 
  # sum the two layers while removing any NA values
  terra::app(sum, na.rm = T) %>%
  # add 0.01 so there are no 0 values
  sum(., 0.01)
plot(cost_rm_constraints)

# Make any values above 99 (where a constraint would be) to be set as NA to remove from analysis
cost_rm_constraints[cost_rm_constraints >= 99] <- NA
cost_rm_constraints[cost_rm_constraints == 0.01] <- NA
plot(cost_rm_constraints)

#####################################

## Inspect new raster
minmax(cost_rm_constraints)[1,] # 0.51
minmax(cost_rm_constraints)[2,] # maximum value = 6.162601
list(unique(cost_rm_constraints)) # list all unique values
res(cost_rm_constraints) # 100 x 100
hist(cost_rm_constraints) # show histogram of values (though mostly values near 1)
freq(cost_rm_constraints) # show frequency of values (though will round to 0 and 1)

#####################################
#####################################

# Export data
## Raster data
writeRaster(cost_raster, filename = file.path(least_cost_dir, "cost_raster.grd"), overwrite = T)

writeRaster(cost_rm_constraints, filename = file.path(least_cost_dir, "cost_rm_constraints.grd"), overwrite = T)
