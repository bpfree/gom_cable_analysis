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
least_cost_dir <- "data/e_least_cost_path"
least_cost_gpkg <- "data/e_least_cost_path/least_cost_path_analysis.gpkg"

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

#### a cost surface with barriers removed from overall data
costs_barriers_extracted <- terra::rast(paste(least_cost_dir, "cost_rm_constraints.grd", sep = "/")) %>%
  # reclassify the values to have values only between 0 and maximum (6.242341)
  terra::classify(., cbind(terra::minmax(.)[1], 0.01, NA))

#####################################

## Swapping values
max <- minmax(costs_barriers_extracted)[2,]

new_value <- max - costs_barriers_extracted

#####################################

# create slope cost surface
cs4 <- leastcostpath::create_cs(x = new_value,
                               # neighbors = 4, 8, 16, 32, 48
                               neighbours = 4)

cs8 <- leastcostpath::create_cs(x = new_value,
                               # neighbors = 4, 8, 16, 32, 48
                               neighbours = 8)

cs16 <- leastcostpath::create_cs(x = new_value,
                                # neighbors = 4, 8, 16, 32, 48
                                neighbours = 16)

cs32 <- leastcostpath::create_cs(x = new_value,
                                # neighbors = 4, 8, 16, 32, 48
                                neighbours = 32)

cs48 <- leastcostpath::create_cs(x = new_value,
                                 # neighbors = 4, 8, 16, 32, 48
                                 neighbours = 48)

#####################################
#####################################

# create least cost path
lcp4 <- leastcostpath::create_lcp(x = cs4,
                                  origin = starting_points,
                                  destination = landing_points,
                                  cost_distance = TRUE) %>%
  dplyr::mutate(neighbors = 4)

lcp8 <- leastcostpath::create_lcp(x = cs8,
                                  origin = starting_points,
                                  destination = landing_points,
                                  cost_distance = TRUE) %>%
  dplyr::mutate(neighbors = 8)

lcp16 <- leastcostpath::create_lcp(x = cs16,
                                  origin = starting_points,
                                  destination = landing_points,
                                  cost_distance = TRUE) %>%
  dplyr::mutate(neighbors = 16)

lcp32 <- leastcostpath::create_lcp(x = cs32,
                                  origin = starting_points,
                                  destination = landing_points,
                                  cost_distance = TRUE) %>%
  dplyr::mutate(neighbors = 32)

lcp48 <- leastcostpath::create_lcp(x = cs48,
                                  origin = starting_points,
                                  destination = landing_points,
                                  cost_distance = TRUE) %>%
  dplyr::mutate(neighbors = 48)

#####################################
#####################################

tile_raster <- costs_barriers_extracted %>%
  as.data.frame(xy=T) %>%
  setNames(c("longitude", "latitude", "cost"))

g <- ggplot() +
  geom_tile(data = tile_raster, aes(x = longitude, y = latitude, fill = cost)) +
  geom_sf(data = starting_points, color = "red", size = 2) +
  geom_sf(data = landing_points, size = 2, color = "black") +
  geom_sf(data = lcp4, color = "yellow") +
  geom_sf(data = lcp8, color = "green") +
  geom_sf(data = lcp16, color = "orange") +
  geom_sf(data = lcp32, color = "purple")
g

#####################################
#####################################

# Combine lines
lcp_lines <- lcp4 %>%
  rbind(lcp8,
        lcp16,
        lcp32,
        lcp48)

#####################################
#####################################

# Export data
## Cost paths
st_write(obj = lcp_lines, dsn = least_cost_gpkg, "gom_lcp_lines", append = F)