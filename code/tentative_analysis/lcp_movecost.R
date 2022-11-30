###########################################
### Least Cost Path -- movecost package ###
###########################################

# Clear environment
rm(list = ls())

# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr,
               fasterize,
               ggplot2,
               movecost,
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
starting_points <- sf::st_read(dsn = least_cost_gpkg, layer = "starting_site")
landing_points <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas")

cost_raster <- raster::raster(paste(least_cost_dir, "cost_raster.grd", sep = "/"))
barrier_raster <- raster::raster(paste(least_cost_dir, "constraints_raster.grd", sep = "/"))

#####################################
#####################################

# Move corridor

#####################################
#####################################

# Move cost
lcp <- movecost::movecost(dtm = cost_raster,
                          # origin are offshore wind border points
                          origin = starting_points,
                          # destination are the shore landing points
                          destin = landing_points,
                          funct = "t",
                          # barriers for areas not permitted
                          barrier = barrier_raster,
                          # have output as raster
                          outp = "r",
                          # number of directions possible (knight and queen's case)
                          # Suitability for cable? Maybe queen's case is more appropriate (8)
                          move = 16,
                          field = 0)
