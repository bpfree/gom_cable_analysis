####################################################
### 38. Least Cost Path -- leastcostpath package ###
####################################################

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

# Inspect the versions of the packages
sessionInfo()

#####################################

# leastcostpath Documentation
## Manual: https://cran.r-project.org/web/packages/leastcostpath/leastcostpath.pdf
## User Guide: https://cran.r-project.org/web/packages/leastcostpath/vignettes/leastcostpath-1.html
## GitHub: https://github.com/josephlewis/leastcostpath

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directories
least_cost_dir <- "leastcostpath_temp/data"
least_cost_gpkg <- "leastcostpath_temp/data/least_cost_path_analysis.gpkg"

#####################################

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

#### a cost surface with barriers removed from overall data
costs_barriers_extracted <- terra::rast(paste(least_cost_dir, "costs.grd", sep = "/"))

#####################################

## Swapping values
max <- minmax(costs_barriers_extracted)[2,]

new_value <- max - costs_barriers_extracted

new_value[new_value <= 0] <- NA

# create slope cost surface
cs <- leastcostpath::create_cs(x = new_value,
                               # neighbors = 4, 8, 16, 32, 48
                               neighbours = 8)

# create least cost path
## Option 1
## 300463
lcp300463 <- leastcostpath::create_lcp(x = cs,
                                       origin = starting_points,
                                       destination = landing_points_300463,
                                       cost_distance = TRUE)

## 302357
lcp302357 <- leastcostpath::create_lcp(x = cs,
                                       origin = starting_points,
                                       destination = landing_points_302357,
                                       cost_distance = TRUE)

## 303708
lcp303708 <- leastcostpath::create_lcp(x = cs,
                                       origin = starting_points,
                                       destination = landing_points_303708,
                                       cost_distance = TRUE)

## 304846
lcp304846 <- leastcostpath::create_lcp(x = cs,
                                       origin = starting_points,
                                       destination = landing_points_304846,
                                       cost_distance = TRUE)


tile_raster <- costs_barriers_extracted %>%
  as.data.frame(xy=T) %>%
  setNames(c("longitude", "latitude", "cost"))

g <- ggplot() +
  geom_tile(data = tile_raster, aes(x = longitude, y = latitude, fill = cost)) +
  geom_sf(data = starting_points, color = "red", size = 2) +
  geom_sf(data = landing_points, size = 2, color = "black") +
  geom_sf(data = lcp300463, color = "yellow") +
  geom_sf(data = lcp302357, color = "green") +
  geom_sf(data = lcp303708, color = "orange") +
  geom_sf(data = lcp304846, color = "purple")
g

#####################################
#####################################

# Combine lines
lcp_lines <- lcp300463 %>%
  rbind(lcp302357,
        lcp303708,
        lcp304846)

#####################################
#####################################

# Export data
## Cost paths
st_write(obj = lcp_lines, dsn = least_cost_gpkg, "gom_lcp_lines", append = F)