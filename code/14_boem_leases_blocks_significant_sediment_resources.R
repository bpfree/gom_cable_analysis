#################################################################
### 14. BOEM Lease Blocks with Significant Sediment Resources ###
#################################################################

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
sediment_dir <- "data/a_raw_data/significant_sediment/MMIS.gdb"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
sediment_gpkg <- "data/b_intermediate_data/sediment.gpkg"

# View layer names within geodatabase
sf::st_layers(dsn = sediment_dir,
              do_count = TRUE)

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Load significant sediment data
## ***Note: There are a few ways to obtain the data
### 1.) BOEM Marine Mineral Mapping and Data page: https://www.boem.gov/marine-minerals/marine-minerals-mapping-and-data
### Here you can download the geodatabase or shapefile for the Gulf of Mexico or the Atlantic
###   - Geodatabase download link: https://mmis.doi.gov/boemmmis/downloads/layers/GOMSigSedBlocks_fgdb.zip
###   - Shapefile download link: https://mmis.doi.gov/boemmmis/downloads/layers/GOMSigSedBlocks_shp.zip
###   - Metadata: https://mmis.doi.gov/boemmmis/metadata/PlanningAndAdministration/GOMSigSedBlocks.xml

### 2.) Gulf of Mexico: https://www.boem.gov/marine-minerals/managing-multiple-uses-gulf-mexico
###   - Shapefile download link: https://mmis.doi.gov/boemmmis/downloads/layers/GOMSigSedBlocks_shp.zip

### 3.) Marine Minerals Information System (https://mmis.doi.gov/BOEMMMIS/) -- interactive data and map portal
### Metadata: https://mmis.doi.gov/BOEMMMIS/metadata/WAF/GOMSigSedBlocks.xml
###   a.) Click the "Layers" option on the top left of the page
###   b.) Expand the "Administrative & Planning"
###   c.) Mark the "Gulf of Mexico OCS Blocks with Significant Sediment Resources"
###     ***Note: If the layer name is greyed out, zoom in further on the map till the layer name becomes black.
###              Now you can mark the layer and it should appear.
###   d.) Click the "Downloads" option on the top left of the page
###     ***Note: If too far zoomed out, page will notify you to zoom in further before being able to draw a boundary box
###   e.) Click "Select Area to Download"
###   f.) Mark boundary on the map for download area
###     ***Note: Click points on map and closing by clicking on first point.
###   g.) Once area has been chosen, choose file format (e.g., shapefile, geodatabase)
###   h.) Select "Download"
### ***NOTE: If entire dataset is desired, on layers page click the "Download Layer GDB" icon next to layer name

significant_sediment <- st_read(dsn = sediment_dir, layer = "Gulf_of_Mexico_OCS_Blocks_with_Significant_Sediment_Resources") %>%
  # change multipolygon Z to multipolygon
  sf::st_cast(to = "MULTIPOLYGON") %>%
  # make sure all geometries are valid
  sf::st_make_valid() %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain only lease blocks with significant sediment in the study area
  sf::st_intersection(study_area) %>%
  # create field called "layer" and fill with "significant sediment" for summary
  dplyr::mutate(layer = "significant sediment") %>%
  # group all features by the "layer" and "value" fields to then have a single feature
  # "value" will get pulled in from the study area layer
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = significant_sediment, dsn = analysis_gpkg, "boem_significant_sediments", append = F)

## Significant Sediments geopackage
st_write(obj = significant_sediment, dsn = sediment_gpkg, "boem_significant_sediments", append = F)
