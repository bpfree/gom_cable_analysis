##############################
### 33. Landing Locations  ###
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
#### Least Cost Path directory
least_cost_gpkg <- "data/e_least_cost_path/least_cost_path_analysis.gpkg"

#### Intermediate directory
landing_sites_gpkg <-"data/b_intermediate_data/landing_sites.gpkg"

# View layer names within geodatabase
sf::st_layers(dsn = landing_points_dir,
              do_count = TRUE)

#####################################
#####################################

# Load coastal point data
coast_points <- terra::st_read(dsn = landing_points_dir, layer = "coast_point_costs")

study_area <- terra::st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

# View data
coast_points

#####################################
#####################################

# Obtain 100 cheapest landing locations
coast100 <- coast_points %>%
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # arrange costs  by cost
  dplyr::arrange(cost) %>%
  # select the cheapest 50 (- signifies bottom) to get cheapest locations
  dplyr::top_n(-100, cost) %>%
  # clip the data to the study area
  rmapshaper::ms_clip(study_area)

coast100
list(unique(coast1000$endID))

#####################################

g <- ggplot2::ggplot() + 
  ggplot2::geom_sf(data = study_area, fill = NA, color = "blue", linetype = "dashed") +
  ggplot2::geom_sf(data = coast100)
g

#####################################
#####################################

# Subset 4 landing option locations
## This will use endID location [list(unique(coast50$endID)) --> 303708, 302357, 304846, 300463]
landing_area_303708 <- coast100 %>%
  # filter by endID "303708"
  dplyr::filter(endID == 303708) %>%
  # randomly sample one of the points
  dplyr::sample_n(1)

landing_area_302357 <- coast100 %>%
  # filter by endID "302357"
  dplyr::filter(endID == 302357) %>%
  # randomly sample one of the points
  dplyr::sample_n(1)

landing_area_304846 <- coast100 %>%
  # filter by endID "304846"
  dplyr::filter(endID == 304846) %>%
  # randomly sample one of the points
  dplyr::sample_n(1)

landing_area_300463 <- coast100 %>%
  # filter by endID "300463"
  dplyr::filter(endID == 300463) %>%
  # randomly sample one of the points
  dplyr::sample_n(1)

#####################################

g <- ggplot2::ggplot() + 
  ggplot2::geom_sf(data = study_area, fill = NA, color = "blue", linetype = "dashed") +
  ggplot2::geom_sf(data = coast100) +
  ggplot2::geom_sf(data = landing_area_303708, color = "red") +
  ggplot2::geom_sf(data = landing_area_302357, color = "orange") +
  ggplot2::geom_sf(data = landing_area_304846, color = "yellow") +
  ggplot2::geom_sf(data = landing_area_300463, color = "darkred")
g

#####################################
#####################################

# Combine landing sites
landing_areas <- landing_area_300463 %>%
  rbind(landing_area_302357,
        landing_area_303708,
        landing_area_304846)

#####################################
#####################################

# Export data
## Least cost geopackage
sf::st_write(obj = landing_areas, dsn = least_cost_gpkg, "landing_areas", append = F)

## Landing sites geopackage
sf::st_write(obj = landing_areas, dsn = landing_sites_gpkg, "landing_areas", append = F)
sf::st_write(obj = landing_area_300463, dsn = landing_sites_gpkg, "landing_area_300463", append = F)
sf::st_write(obj = landing_area_302357, dsn = landing_sites_gpkg, "landing_area_302357", append = F)
sf::st_write(obj = landing_area_303708, dsn = landing_sites_gpkg, "landing_area_303708", append = F)
sf::st_write(obj = landing_area_304846, dsn = landing_sites_gpkg, "landing_area_304846", append = F)
