##############################
### 31. Landing Locations  ###
##############################

# Clear environment
rm(list = ls())

# Load packages
pacman::p_load(dplyr,
               fasterize,
               ggplot2,
               lubridate,
               plyr,
               raster,
               rgdal,
               rgeos,
               rmapshaper,
               sf,
               sp,
               stringr,
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directories
landing_points_dir <- "data/a_raw_data/LB_TX_DELIVERABLE/coast_point_costs.gpkg"
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
raster_dir <- "data/d_raster_data"

### Output directories
least_cost_gpkg <- "data/e_least_cost_path/least_cost_path_analysis.gpkg"

#####################################
#####################################

# View layer names within geodatabase
sf::st_layers(dsn = landing_points_dir,
              do_count = TRUE)

#####################################

# Load coastal point data
coast_points <- sf::st_read(dsn = landing_points_dir, layer = "coast_point_costs")

study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

# View data
coast_points

#####################################
#####################################

# Obtain 10 cheapest landing locations
coast10 <- coast_points %>%
  # arrange costs
  dplyr::arrange(cost) %>%
  # select the bottom 10 percent (- signifies bottom)
  dplyr::top_frac(-0.05, cost)

coast10

g <- ggplot() + 
  geom_sf(data = study_area, fill = NA, color = "blue", linetype = "dashed") +
  geom_sf(data = coast10)
g
