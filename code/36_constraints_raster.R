############################
### 36. Constraints Data ###
############################

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
#### Least Cost Path directories
least_cost_dir <- "data/e_least_cost_path"
least_cost_gpkg <- "data/e_least_cost_path/least_cost_path_analysis.gpkg"

#### Intermediate directory
intermediate_dir <- "data/b_intermediate_data"

# View layer names within geodatabase
sf::st_layers(dsn = data_dir,
              do_count = TRUE)

#####################################
#####################################

# Load raster grid
gom_raster <- terra::rast(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

#####################################

# Load vector data
## Environmental
seagrass <- sf::st_read(dsn = data_dir, layer = "seagrass")
oyster <- sf::st_read(dsn = data_dir, layer = "oyster")

## Geophysical
conservation_area <- sf::st_read(dsn = data_dir, layer = "conservation_areas")
artificial_reef <- sf::st_read(dsn = data_dir, layer = "artificial_reefs")
significant_sediment <- sf::st_read(dsn = data_dir, layer = "boem_significant_sediments")

# Navigational
unexploded_ordnance <- sf::st_read(dsn = data_dir, layer = "unexploded_ordnance")
no_activity_zone <- sf::st_read(dsn = data_dir, layer = "boem_no_activity_zones")
anchorage_area <- sf::st_read(dsn = data_dir, layer = "anchorage_areas")

## Industry
borehole <- sf::st_read(dsn = data_dir, layer = "borehole")
oil_gas_lease_area <- sf::st_read(dsn = data_dir, layer = "oil_gas_lease_areas")
drilling_platform <- sf::st_read(dsn = data_dir, layer = "drilling_platforms")
environmental_sensor <- sf::st_read(dsn = data_dir, layer = "environmental_sensor")

#####################################
#####################################

# Create constraints layers
all_constraints <- seagrass %>%
  # combine constraints datasets so that each is an unique row
  rbind(oyster,
        conservation_area,
        artificial_reef,
        significant_sediment,
        unexploded_ordnance,
        no_activity_zone,
        anchorage_area,
        borehole,
        oil_gas_lease_area,
        drilling_platform,
        environmental_sensor) %>%
  # create field called "layer" and fill with "barrier" for summary
  dplyr::mutate(barrier = "barrier") %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  dplyr::group_by(barrier,
                  value) %>%
  # summarise data to obtain single feature that will act as a barrier
  dplyr::summarise()

# Convert to rasters
## Environmental
seagrass_raster <- terra::rasterize(x = seagrass,
                                    y = gom_raster,
                                    field = "value")

oyster_raster <- terra::rasterize(x = oyster,
                                  y = gom_raster,
                                  field = "value")

## Geophysical
conservation_area_raster <- terra::rasterize(x = conservation_area,
                                             y = gom_raster,
                                             field = "value")

artificial_reef_raster <- terra::rasterize(x = artificial_reef,
                                           y = gom_raster,
                                           field = "value")

significant_sediment_raster <- terra::rasterize(x = significant_sediment,
                                                y = gom_raster,
                                                field = "value")

## Navigational
unexploded_ordnance_raster <- terra::rasterize(x = unexploded_ordnance,
                                               y = gom_raster,
                                               field = "value")

no_activity_zone_raster <- terra::rasterize(x = no_activity_zone,
                                            y = gom_raster,
                                            field = "value")

anchorage_area_raster <- terra::rasterize(x = anchorage_area,
                                          y = gom_raster,
                                          field = "value")

## Industry
borehole_raster <- terra::rasterize(x = borehole,
                                    y = gom_raster,
                                    field = "value")

oil_gas_lease_area_raster <- terra::rasterize(x = oil_gas_lease_area,
                                              y = gom_raster,
                                              field = "value")

drilling_platform_raster <- terra::rasterize(x = drilling_platform,
                                             y = gom_raster,
                                             field = "value")

environmental_sensor_raster <- terra::rasterize(x = environmental_sensor,
                                                y = gom_raster,
                                                field = "value")

#####################################
#####################################

# Create constraints layer
## cover any NA values of another raster with values from any other raster (all barrier cells)
constraints <- terra::cover(x = seagrass_raster,
                            y = oyster_raster) %>%
  # cover with conservation area raster
  terra::cover(y = conservation_area_raster) %>%
  # cover with artificial reef raster
  terra::cover(y = artificial_reef_raster) %>%
  # cover with significant sediment raster
  terra::cover(y = significant_sediment_raster) %>%
  # cover with unexploded ordnance raster
  terra::cover(y = unexploded_ordnance_raster) %>%
  # cover with no activity zone raster
  terra::cover(y = no_activity_zone_raster) %>%
  # cover with anchorage area raster
  terra::cover(y = anchorage_area_raster) %>%
  # cover with borehole raster
  terra::cover(y = borehole_raster) %>%
  # cover with active oil and gas lease area raster
  terra::cover(y = oil_gas_lease_area_raster) %>%
  # cover with drilling platform raster
  terra::cover(y = drilling_platform_raster) %>%
  # cover with environmental sensore raster
  terra::cover(y = environmental_sensor_raster)

## Set values of 0 to be 99 for later cost analysis
constraints[constraints == 0] <- 99

#####################################
#####################################

# Export data
## Least cost geopackage
st_write(obj = all_constraints, dsn = least_cost_gpkg, "all_constraints", append = F)

## Raster data
writeRaster(constraints, filename = file.path(least_cost_dir, "constraints_raster.grd"), overwrite = T)