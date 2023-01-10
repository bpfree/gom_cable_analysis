################################
### 12. Unexploded Ordnances ###
################################

# Clear environment
rm(list = ls())

# Load packages
pacman::p_load(dplyr,
               ggplot2,
               plyr,
               raster,
               rgdal,
               rgeos,
               sf,
               sp,
               stringr,
               tidyr)

#####################################
#####################################

# Set directories
## Define data directory (as this is an R Project, pathnames are simplified)
### Input directories
uxo_dir <- "data/a_raw_data/UnexplodedOrdnance/UnexplodedOrdnance.gdb"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
uxo_gpkg <- "data/b_intermediate_data/gom_uneploded_ordnance.gpkg"

# View layer names within geodatabase
sf::st_layers(dsn = uxo_dir,
              do_count = TRUE)

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- sf::st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

# Load unexploded ordnance point data (source: https://marinecadastre.gov/downloads/data/mc/UnexplodedOrdnance.zip)
## Metadata: https://www.fisheries.noaa.gov/inport/item/66208
unexploded_ordnance_points <- sf::st_read(dsn = uxo_dir, layer = "UnexplodedOrdnanceLocations") %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain only unexploded ordnance sites in the study area
  sf::st_intersection(study_area) %>%
  # add a buffer of 500 meters around sites
  sf::st_buffer(dist = 500) %>%
  # create field called "layer" and fill with "unexploded ordnance" for summary
  dplyr::mutate(layer = "unexploded ordnance") %>%
  # select the "layer" and "value" fields for later data summary
  dplyr::select(layer,
                value)

sf::st_crs(unexploded_ordnance_points, parameters = TRUE)$units_gdal

# Load unexploded ordnance area data
## ***Note: Unexploded Ordnance Areas data (https://marinecadastre.gov/downloads/data/mc/UnexplodedOrdnanceArea.zip)
## has one fewer area than the location dataset (https://marinecadastre.gov/downloads/data/mc/UnexplodedOrdnance.zip)
unexploded_ordnance_areas <- sf::st_read(dsn = uxo_dir, layer = "UnexplodedOrdnanceAreas") %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform(5070) %>%
  # obtain only unexploded ordnance sites in the study area
  sf::st_intersection(study_area) %>%
  # create field called "layer" and fill with "unexploded ordnance" for summary
  dplyr::mutate(layer = "unexploded ordnance") %>%
  # select the "layer" and "value" fields for later data summary
  dplyr::select(layer,
                value)

#####################################

# Inspect the point and polygon data for unexploded ordnances
g <- ggplot2::ggplot() + 
  ggplot2::geom_sf(data = unexploded_ordnance_areas, color = "red", fill = NA) +
  ggplot2::geom_sf(data = unexploded_ordnance_points, color = "blue") +
  ggplot2::geom_sf(data = study_area, color = "black", linetype = "dashed", fill = NA)
g

#####################################
#####################################

# Combine data
unexploded_ordnance <- unexploded_ordnance_points %>%
  # Combine site data with area data
  rbind(unexploded_ordnance_areas) %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  dplyr::group_by(layer,
                  value) %>%
  # summarise the data to get single feature
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
sf::st_write(obj = unexploded_ordnance, dsn = analysis_gpkg, "unexploded_ordnance", append = F)

## Unexploded ordnance geopackage
sf::st_write(obj = unexploded_ordnance, dsn = uxo_gpkg, "unexploded_ordnance", append = F)
sf::st_write(obj = unexploded_ordnance_points, dsn = uxo_gpkg, "unexploded_ordnance_point", append = F)
sf::st_write(obj = unexploded_ordnance_areas, dsn = uxo_gpkg, "unexploded_ordnance_areas", append = F)
