########################################
### 34. Wind Farm Starting Location  ###
########################################

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
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

### Output directories
least_cost_gpkg <- "data/e_least_cost_path/least_cost_path_analysis.gpkg"
wind_start_gpkg <- "data/b_intermediate_data/wind_farm_start_point.gpkg"

#####################################
#####################################

# View layer names within geodatabase
sf::st_layers(dsn = analysis_gpkg,
              do_count = TRUE)

#####################################

# Load wind farm data
wind_area <- sf::st_read(dsn = analysis_gpkg, layer = "gom_wind_area_i")

g <- ggplot() +
  geom_sf(data = wind_area, color = "blue") +
  # Label wind areas
  geom_sf_label(data=wind_area, mapping=aes(label=PROTRACTION_NUMBER), show.legend = F, size=2.5)
g

#####################################
#####################################

# Create starting point
wind_area_points <- wind_area %>%
  # transform coordinate system to be in decimal degrees for limiting area of interest
  sf::st_transform("EPSG:4326") %>%
  # create wind area as an object composed of points
  sf::st_cast("POINT") %>%
  # create new fields from the geometry 
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2]) %>%
  # limit to the boundaries (dd = 28.8 N, -94.5 W)
  dplyr::filter(lat >= 28.8 &
                lon <= -94.5) %>%
  # transform coordinate system back to EPSG:5070 to match all other data
  sf::st_transform("EPSG:5070")

#####################################

g <- ggplot() +
  geom_sf(data = wind_area, color = "blue") +
  geom_sf(data = wind_area_points, color = "red")
g

#####################################
#####################################

# Randomly sample a point to set as starting point
wind_starting_point <- wind_area_points %>%
  dplyr::sample_n(1)

#####################################

g <- ggplot() +
  geom_sf(data = wind_area, color = "blue") +
  geom_sf(data = wind_area_points, color = "red") +
  geom_sf(data = wind_starting_point, color = "black")
g

#####################################
#####################################

# Export data
## Least cost geopackage
st_write(obj = wind_starting_point, dsn = least_cost_gpkg, "starting_site", append = F)

## Landing sites geopackage
st_write(obj = wind_starting_point, dsn = wind_start_gpkg, "starting_site", append = F)
st_write(obj = wind_area_points, dsn = wind_start_gpkg, "wind_area_points", append = F)
