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
               ggspatial,
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

# Movecost Documentation
## Manual: https://cran.r-project.org/web/packages/movecost/movecost.pdf
## Github: https://github.com/cran/movecost
## Paper: https://www.sciencedirect.com/science/article/pii/S2352711019302341

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
starting_points <- sf::st_read(dsn = least_cost_gpkg, layer = "starting_site") %>%
  # convert to SpatialPointsDataFrame for use in movecoast()
  sf::as_Spatial()
landing_points <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  # convert to SpatialPointsDataFrame for use in movecoast()
  sf::as_Spatial()

cost_raster <- raster::raster(paste(least_cost_dir, "cost_raster.grd", sep = "/"))
arc_cost_raster <- raster::raster(paste(least_cost_dir, "arcgis_cost_raster.grd", sep = "/"))
barrier <- sf::st_read(dsn = least_cost_gpkg, "all_constraints") %>%
  # convert to SpatialPolygonsDataFrame for use in movecoast()
  sf::as_Spatial()

#####################################

# when as sf
g <- ggplot() + 
  ggspatial::geom_spatial(data = starting_points, color = "blue") +
  geom_sf(data = landing_points, color = "red") +
  geom_sf(data = barrier, fill = NA, linetype = "dashed")
g

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
                          funct = "ree",
                          # barriers for areas not permitted
                          barrier = barrier,
                          # have output as raster
                          outp = "r",
                          # number of directions possible (knight and queen's case)
                          # Suitability for cable? Maybe queen's case is more appropriate (8)
                          move = 8,
                          field = 0,
                          # do not return to starting point
                          return.base = FALSE,
                          # export graphic
                          export = TRUE)

lcp2 <- movecost::movecost(dtm = arc_cost_raster,
                          # origin are offshore wind border points
                          origin = starting_points,
                          # destination are the shore landing points
                          destin = landing_points,
                          funct = "t",
                          # barriers for areas not permitted
                          barrier = barrier,
                          # have output as raster
                          outp = "r",
                          # number of directions possible (knight and queen's case)
                          # Suitability for cable? Maybe queen's case is more appropriate (8)
                          move = 8,
                          # do not return to starting point
                          return.base = FALSE,
                          # export graphic
                          export = FALSE)
