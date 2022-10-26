########################################################
### 15. Oil and Gas Boreholes, Test Wells, and Wells ###
########################################################

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
borehole_dir <- "data/a_raw_data/borehole"

### Output directories
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
borehole_gpkg <- "data/b_intermediate_data/borehole.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Load borehole data (source: https://www.data.boem.gov/Well/Borehole/Default.aspx)
## Query Definitions: https://www.data.boem.gov/Well/Borehole/Default.aspx
## Metadata / Field Definitions: https://www.data.boem.gov/Main/HtmlPage.aspx?page=borehole
## Field Values: https://www.data.boem.gov/Main/HtmlPage.aspx?page=boreholeFields
### Borehole Status Code
####   1.) APD -- Application for permit to drill
####   2.) AST -- Approved sidetrack
####   3.) BP -- Bypass
####   4.) CNL -- Borehole is cancelled. The request to drill the well is cancelled after the APD or sundry has been approved. The status date of the borehole was cancelled.
####   5.) COM -- Borehole completed
####   6.) CT -- Core test well
####   7.) DRL -- Drilling active
####   8.) DSI -- Drilling suspended
####   9.) PA -- Permanently abandoned
####   10.) ST -- Borehole side tracked
####   11.) TA -- temporarily abandoned
####   12.) VCW -- Volume chamber well

### Type Code
####   1.) C -- Core test
####   2.) D -- Development
####   3.) E -- Exploratory
####   4.) N -- Non-operation
####   5.) O -- Other
####   6.) R -- Relief
####   7.) S -- Strat test

borehole <- read.csv(paste(borehole_dir, "Borehole.csv", sep = "/")) %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("Surface.Longitude", "Surface.Latitude"),
               # According to BSEE, coordinate data are in NAD27 (EPSG:4267)
               crs = 4267) %>% # EPSG:4267 (https://epsg.io/4267)
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # remove any boreholes that have been side tracked or permanently abandoned
  dplyr::filter(!Status.Code %in% c("CNL", "PA", "ST")) %>% # return all not status codes CNL, PA and ST
  # # obtain only active oil and gas lease blocks in the study area
  sf::st_intersection(study_area) %>%
  # create buffer of 60.96 meters (200 feet) around the boreholes
  sf::st_buffer(dist = 60.96) %>%
  # create field called "layer" and fill with "borehole" for summary
  dplyr::mutate(layer = "borehole") %>%
  # group by layer to later summarise data
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = borehole, dsn = analysis_gpkg, "borehole", append = F)

## Borehole geopackage
st_write(obj = borehole, dsn = borehole_gpkg, "boreholes", append = F)
