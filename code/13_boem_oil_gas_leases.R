#####################################
### 13. Active Oil and Gas Leases ###
#####################################

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
oilgas_lease_dir <- "data/a_raw_data/ActiveLeasePolygons.gdb"

### Output directories
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
oilgas_lease_gpkg <- "data/b_intermediate_data/boem_oilgas_lease.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# View layer names within geodatabase
sf::st_layers(dsn = oilgas_lease_dir,
              do_count = TRUE)

#####################################

# Load BOEM active oil and gas lease data (source: https://www.data.boem.gov/Main/Mapping.aspx#ascii)
## Geodatabase download link: https://www.data.boem.gov/Mapping/Files/ActiveLeasePolygons.gdb.zip
## Shapefile download link: https://www.data.boem.gov/Mapping/Files/actlease.zip

## Metadata: https://www.data.boem.gov/Mapping/Files/actlease_meta.html
### Status codes:
#### 1.) PROD = A lease held by production of a mineral
#### 2.) UNIT = Lease (or portion thereof) included in an approved unit agreement
#### 3.) SOP = Initial term extended due to ordering or appro by Dir of SOP
#### 4.) OPERNS = Initial term extended because of activity on the leased area
#### 5.) DSO = Operations/activities on all or part of lease suspended/temp prohibited on Reg Sup initiative. Lease term extended
#### 6.) PRIMRY = A lease within the initial term of the contract (5, 8, or 10 years)

### Note: data are updated each month near the first of the month
### These data were updated as of 3 October 2022
oil_gas_lease_areas <- st_read(dsn = oilgas_lease_dir, layer = "al_20221003") %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # obtain only active oil and gas lease blocks in the study area
  sf::st_intersection(study_area) %>%
  # create field called "layer" and fill with "active oil and gas lease" for summary
  dplyr::mutate(layer = "active oil and gas lease") %>%
  # group by layer to later summarise data
  dplyr::group_by(layer,
                  value) %>%
  # summarise data to obtain single feature
  dplyr::summarise()

#####################################
#####################################

# Export data
## Analysis geopackage
st_write(obj = oil_gas_lease_areas, dsn = analysis_gpkg, "oil_gas_lease_areas", append = F)

## Active oil and gas lease blocks geopackage
st_write(obj = oil_gas_lease_areas, dsn = oilgas_lease_gpkg, "oil_gas_lease_areas", append = F)
