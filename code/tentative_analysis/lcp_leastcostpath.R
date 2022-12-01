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
final_data_gpkg <- "data/f_final_data/gom_cable_final.gpkg"

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
starting_points <- sf::st_read(dsn = least_cost_gpkg, layer = "starting_site")

## Landing point
landing_points <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas")

### 300463
landing_points_300463 <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  dplyr::filter(endID == 300463)

### 302357
landing_points_302357 <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  dplyr::filter(endID == 302357)

### 303708
landing_points_303708 <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  dplyr::filter(endID == 303708)

### 304846
landing_points_304846 <- sf::st_read(dsn = least_cost_gpkg, layer = "landing_areas") %>%
  dplyr::filter(endID == 304846)

cost_raster <- terra::rast(paste(least_cost_dir, "cost_raster.grd", sep = "/"))
cost_raster2 <- terra::rast(paste(least_cost_dir, "arcgis_cost_raster.grd", sep = "/"))
barrier_raster <- raster::raster(paste(least_cost_dir, "constraints_raster.grd", sep = "/"))

#####################################
#####################################

# create slope cost surface
slope_cs <- leastcostpath::create_slope_cs(x = cost_raster2,
                                           # functions
                                           cost_function = "tobler",
                                           # neighbors = 4, 8, 16, 32, 48
                                           neighbours = 8)

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

cs <- leastcostpath::create_cs(x = cost_raster2,
                               neighbours = 8)

#####################################
#####################################

# create least cost path
## Option 1
## 300463
lcp300463 <- leastcostpath::create_lcp(x = slope_cs,
                                       origin = starting_points,
                                       destination = landing_points_300463,
                                       cost_distance = TRUE)

## 302357
lcp302357 <- leastcostpath::create_lcp(x = slope_cs,
                                       origin = starting_points,
                                       destination = landing_points_302357,
                                       cost_distance = TRUE)

## 303708
lcp303708 <- leastcostpath::create_lcp(x = slope_cs,
                                       origin = starting_points,
                                       destination = landing_points_303708,
                                       cost_distance = TRUE)

## 304846
lcp304846 <- leastcostpath::create_lcp(x = slope_cs,
                                       origin = starting_points,
                                       destination = landing_points_304846,
                                       cost_distance = TRUE)

#####################################

## Option 2
## 300463
lcp300463b <- leastcostpath::create_lcp(x = cs,
                                       origin = starting_points,
                                       destination = landing_points_300463,
                                       cost_distance = TRUE)

## 302357
lcp302357b <- leastcostpath::create_lcp(x = cs,
                                       origin = starting_points,
                                       destination = landing_points_302357,
                                       cost_distance = TRUE)

## 303708
lcp303708b <- leastcostpath::create_lcp(x = cs,
                                       origin = starting_points,
                                       destination = landing_points_303708,
                                       cost_distance = TRUE)

## 304846
lcp304846b <- leastcostpath::create_lcp(x = cs,
                                       origin = starting_points,
                                       destination = landing_points_304846,
                                       cost_distance = TRUE)

#####################################

study_area <- st_read(dsn = data_dir, layer = "gom_study_area_marine")
offshore_area <- st_read(dsn = data_dir, layer = "gom_wind_area_i")
barriers <- st_read(dsn = least_cost_gpkg , layer = "all_constraints")

g <- ggplot() +
  geom_sf(data = lcp300463, color = "26596A") +
  geom_sf(data = lcp302357, color = "6E256E") +
  geom_sf(data = lcp303708, color = "552C00") +
  geom_sf(data = lcp304846, color = "91A437") +
  geom_sf(data = barriers, alpha = 0.2, color = "purple", fill = NA, size = 0.1) +
  geom_sf(data = study_area, fill = NA, linetype = "dashed") +
  geom_sf(data = offshore_area, fill = NA, color = "red") +
  geom_sf(data = starting_points)
g

g2 <- ggplot() +
  geom_sf(data = lcp300463b, color = "26596A") +
  geom_sf(data = lcp302357b, color = "6E256E") +
  geom_sf(data = lcp303708b, color = "552C00") +
  geom_sf(data = lcp304846b, color = "91A437") +
  geom_sf(data = barriers, alpha = 0.5, color = "purple", fill = NA, size = 0.2) +
  geom_sf(data = study_area, fill = NA, linetype = "dashed") +
  geom_sf(data = offshore_area, fill = NA, color = "red") +
  geom_sf(data = starting_points)
g2

#####################################
#####################################

# Combine lines
lcp_lines <- lcp300463 %>%
  rbind(lcp302357,
        lcp303708,
        lcp304846)

lcp_lines_b <- lcp300463b %>%
  rbind(lcp302357b,
        lcp303708b,
        lcp304846b)

#####################################
#####################################

# Export data
## Cost paths
st_write(obj = lcp_lines, dsn = final_data_gpkg, "gom_lcp_lines", append = F)
st_write(obj = lcp_lines_b, dsn = final_data_gpkg, "gom_lcp_lines_b", append = F)

## Graphic