########################
### Constraints Data ###
########################

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
intermediate_dir <- "data/b_intermediate_data"
tentative_dir <- "code/tentative_analysis"
least_cost_dir <- "data/e_least_cost_path"

#####################################

# View layer names within geodatabase
sf::st_layers(dsn = data_dir,
              do_count = TRUE)

#####################################
#####################################

# Load raster grid
gom_raster <- raster::raster(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

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
navigation_aid <- sf::st_read(dsn = data_dir, layer = "aids_to_navigation")

## Industry
borehole <- sf::st_read(dsn = data_dir, layer = "borehole")
oil_gas_lease_area <- sf::st_read(dsn = data_dir, layer = "oil_gas_lease_areas")
drilling_platform <- sf::st_read(dsn = data_dir, layer = "drilling_platforms")
environmental_sensor <- sf::st_read(dsn = data_dir, layer = "environmental_sensor")
pipeline <- sf::st_read(dsn = data_dir, layer = "pipelines")

#####################################
#####################################

# Convert to rasters
## Environmental
seagrass_raster <- fasterize(sf = seagrass,
                             raster = gom_raster,
                             field = "value")

oyster_raster <- fasterize(sf = oyster,
                           raster = gom_raster,
                           field = "value")

## Geophysical
conservation_area_raster <- fasterize(sf = conservation_area,
                                      raster = gom_raster,
                                      field = "value")

artificial_reef_raster <- fasterize(sf = artificial_reef,
                                    raster = gom_raster,
                                    field = "value")

significant_sediment_raster <- fasterize(sf = significant_sediment,
                                         raster = gom_raster,
                                         field = "value")

## Navigational
unexploded_ordnance_raster <- fasterize(sf = unexploded_ordnance,
                                        raster = gom_raster,
                                        field = "value")

no_activity_zone_raster <- fasterize(sf = no_activity_zone,
                                     raster = gom_raster,
                                     field = "value")

anchorage_area_raster <- fasterize(sf = anchorage_area,
                                   raster = gom_raster,
                                   field = "value")

navigation_aid_raster <- fasterize(sf = navigation_aid,
                                   raster = gom_raster,
                                   field = "value")

## Industry
borehole_raster <- fasterize(sf = borehole,
                             raster = gom_raster,
                             field = "value")

oil_gas_lease_area_raster <- fasterize(sf = oil_gas_lease_area,
                                       raster = gom_raster,
                                       field = "value")

drilling_platform_raster <- fasterize(sf = drilling_platform,
                                      raster = gom_raster,
                                      field = "value")

environmental_sensor_raster <- fasterize(sf = environmental_sensor,
                                         raster = gom_raster,
                                         field = "value")

pipeline_raster <- fasterize(sf = pipeline,
                             raster = gom_raster,
                             field = "value")

#####################################
#####################################

# Create constraints layer
## cover any NA values of another raster with values from any other raster (all barrier cells)
constraints <- raster::cover(seagrass_raster,
                             oyster_raster,
                             conservation_area_raster,
                             artificial_reef_raster,
                             significant_sediment_raster,
                             unexploded_ordnance_raster,
                             no_activity_zone_raster,
                             anchorage_area_raster,
                             navigation_aid_raster,
                             borehole_raster,
                             oil_gas_lease_area_raster,
                             drilling_platform_raster,
                             environmental_sensor_raster)

#####################################
#####################################

# Export data
## Raster data
writeRaster(constraints, filename = file.path(tentative_dir, "constraints_raster.grd"), overwrite = T)
writeRaster(constraints, filename = file.path(least_cost_dir, "constraints_raster.grd"), overwrite = T)
