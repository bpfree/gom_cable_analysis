############################################
### Least Cost Path -- gdistance package ###
############################################

# Clear environment
rm(list = ls())

# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr,
               fasterize,
               gdistance,
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
least_cost_dir <- "data/e_least_cost_path"
least_cost_gpkg <- "data/e_least_cost_path/least_cost_path_analysis.gpkg"
raster_dir <- "data/d_raster_data"

### Output directories
tentative_analysis <- "code/tentative_analysis"
final_data_dir <- "data/f_final_data"

#####################################

# View layer names within geodatabase
sf::st_layers(dsn = data_dir,
              do_count = TRUE)

sf::st_layers(dsn = least_cost_gpkg,
              do_count = TRUE)

#####################################
#####################################

# Load data
## Starting point
starting_points <- sf::st_read(dsn = least_cost_gpkg, layer = "starting_site") %>%
  sf::as_Spatial()

## Landing points
landing_points <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  sf::as_Spatial()

## Cost raster
cost_raster <- raster::raster(paste(least_cost_dir, "arcgis_cost_raster.grd", sep = "/"))

#####################################
#####################################

# create transition raster
tr <- gdistance::transition(cost_raster, transitionFunction=mean, directions=8)

tr_corr <- gdistance::geoCorrection(tr,
                                    type = "c",
                                    multpl=FALSE)

test <- gdistance::costDistance(tr_corr,
                                starting_points,
                                landing_points)

plot(raster(test))

test2 <- gdistance::shortestPath(x = tr_corr,
                                origin = starting_points,
                                goal = landing_points)
