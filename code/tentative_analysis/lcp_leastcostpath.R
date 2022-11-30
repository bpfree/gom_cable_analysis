################################################
### Least Cost Path -- leastcostpath package ###
################################################

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

# load most recent version of "leastcostpath"
library(devtools)
install_github("josephlewis/leastcostpath")
library(leastcostpath)

sessionInfo()

#####################################

# Movecost Documentation
## Manual: https://cran.r-project.org/web/packages/leastcostpath/leastcostpath.pdf
## User Guide: https://cran.r-project.org/web/packages/leastcostpath/vignettes/leastcostpath-1.html
## GitHub: https://github.com/josephlewis/leastcostpath

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
  # convert to SpatialPointsDataFrame for use in movecoast()
  sf::as_Spatial()

## Landing point
### 300463
landing_points_300463 <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  dplyr::filter(endID == 300463) %>%
  # convert to SpatialPointsDataFrame for use in movecoast()
  sf::as_Spatial()

### 302357
landing_points_302357 <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  dplyr::filter(endID == 302357) %>%
  # convert to SpatialPointsDataFrame for use in movecoast()
  sf::as_Spatial()

### 303708
landing_points_303708 <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  dplyr::filter(endID == 303708) %>%
  # convert to SpatialPointsDataFrame for use in movecoast()
  sf::as_Spatial()

### 304846
landing_points_304846 <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  dplyr::filter(endID == 304846) %>%
  # convert to SpatialPointsDataFrame for use in movecoast()
  sf::as_Spatial()

cost_raster <- raster::raster(paste(least_cost_dir, "cost_raster.grd", sep = "/"))
barrier_raster <- raster::raster(paste(least_cost_dir, "constraints_raster.grd", sep = "/"))

#####################################
#####################################

# create slope cost surface
slope_cs <- leastcostpath::create_slope_cs(dem = cost_raster,
                                           # functions
                                           cost_function = "tobler",
                                           # neighbors = 4, 8, 16, 32, 48
                                           neighbours = 4)

# create barrier cost surface
barrier_cs <- leastcostpath::create_barrier_cs(raster = cost_raster,
                                               # barrier is the barrier raster
                                               barrier = barrier_raster,
                                               # neighbors = 4, 8, 16, 32, 48
                                               neighbours = 4,
                                               # get values of 0
                                               field = 0,
                                               # everything else gets value of 1
                                               background = 1)

# create cost surface
cs <- slope_cs * barrier_cs

#####################################
#####################################

# create least cost path
## 300463
lcp300463 <- leastcostpath::create_lcp(cost_surface = cs,
                                       origin = starting_points,
                                       destination = landing_points_300463,
                                       cost_distance = TRUE,
                                       directional = TRUE) %>%
  as("sf")

## 302357
lcp302357 <- leastcostpath::create_lcp(cost_surface = cs,
                                       origin = starting_points,
                                       destination = landing_points_302357,
                                       cost_distance = TRUE,
                                       directional = TRUE) %>%
  as("sf")

## 303708
lcp303708 <- leastcostpath::create_lcp(cost_surface = cs,
                                       origin = starting_points,
                                       destination = landing_points_303708,
                                       cost_distance = TRUE,
                                       directional = TRUE) %>%
  as("sf")

## 304846
lcp304846 <- leastcostpath::create_lcp(cost_surface = cs,
                                       origin = starting_points,
                                       destination = landing_points_304846,
                                       cost_distance = TRUE,
                                       directional = TRUE) %>%
  as("sf")

#####################################

study_area <- st_read(dsn = data_dir, layer = "gom_study_area_marine")

plot(lcp300463)
plot(lcp302357)
plot(lcp303708)
plot(lcp304846)

g <- ggplot() +
  geom_sf(data = lcp300463, color = "26596A") +
  geom_sf(data = lcp302357, color = "6E256E") +
  geom_sf(data = lcp303708, color = "552C00") +
  geom_sf(data = lcp304846, color = "91A437") +
  geom_sf(data = study_area, fill = NA, linetype = "dashed")
g
