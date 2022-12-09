#####################
### 22. Pipelines ###
#####################

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
pipelines_dir <- "data/a_raw_data/Pipelines.gdb"

### Output directories
#### Analysis directory
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"

#### Intermediate directory
pipelines_gpkg <- "data/b_intermediate_data/pipelines.gpkg"

# View layer names within geodatabase
sf::st_layers(dsn = pipelines_dir,
              do_count = TRUE)
#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

#####################################

# Load pipelines data (data came from an 3 October 2022 update)
## Source: https://www.data.boem.gov/Mapping/Files/Pipelines.gdb.zip
## Options page: https://www.data.boem.gov/Main/Mapping.aspx#ascii
## Metadata: https://www.data.boem.gov/Mapping/Files/ppl_arcs_meta.html

## Field Definitions: https://www.data.boem.gov/Main/HtmlPage.aspx?page=pipelineMasters
### Product Codes
#### ACID- ACID
#### AIR- PNEUMATIC
#### BLGH- BULK GAS WITH TRACE LEVELS OF HYDROGEN SULFIDE
#### BLKG- BULK GAS - FULL WELL STREAM PRODUCTION FROM GAS WELL(S) PRIO
#### BLKO- BULK OIL - FULL WELL STREAM PRODUCTION FROM OIL WELL(S) PRIO
#### BLOH- BULK OIL WITH TRACE LEVELS OF HYDROGEN SULFIDE
#### CBLC- A NON-UMBILICAL CABLE SUCH AS FIBER OPTIC/COMMUNICATIONS
#### CBLP- POWER CABLE
#### CBLR- RENEWABLE ENERGY POWER CABLE
#### CHEM- CORROSION INHIBITOR OR OTHER CHEMICALS
#### CO2- CARBON DIOXIDE (SUPPORT ACTIVITY LEASE)
#### COND- CONDENSATE OR DISTILLATE TRANSPORTED DOWNSTREAM OF FIRST PRO
#### CSNG- PIPELINE USED AS A PROTECTIVE CASING (CSNG) FOR ANOTHER PIPELINE
#### FLG- FLARE GAS
#### G/C- GAS AND CONDENSATE SERVICE AFTER FIRST PROCESSING
#### G/CH- GAS AND CONDENSATE (H2S)
#### G/O- GAS AND OIL SERVICE AFTER FIRST PROCESSING
#### G/OH- GAS AND OIL (H2S)
#### GAS- GAS TRANSPORTED AFTER FIRST PROCESSING
#### GASH- PROCESSED GAS WITH TRACE LEVELS OF HYDROGEN SULFIDE
#### H2O- WATER
#### INJ- GAS INJECTION
#### LGER- LIQUID GAS ENHANCED RECOVERY
#### LIFT- GAS LIFT
#### LPRO- LIQUID PROPANE
#### METH- METHANOL / GLYCOL
#### NGER- NATURAL GAS ENHANCED RECOVERY
#### NGL- Natural Gas Liquids
#### O/W- OIL AND WATER TRANSPORTED AFTER FIRST PROCESSING
#### OIL- OIL TRANSPORTED AFTER FIRST PROCESSING
#### OILH- PROCESSED OIL WITH TRACE LEVELS OF HYDROGEN SULFIDE
#### PWTR- PRESSURIZED WATER (RENEWABLE ENERGY)
#### SERV- SERVICE OR UTILITY LINE USED FOR PIGGING AND PIPELINE MAINTE
#### SPLY- SUPPLY GAS
#### SPRE- SPARE
#### SULF- LIQUIFIED SULPHUR OR SLURRIED SULPHER
#### TEST- TEST
#### TOW- TOW ROUTE ONLY - NOT A PIPELINE
#### UBEH- ELECTRO /HYDRAULIC UMBILICAL
#### UMB- UMBILICAL LINE USUALLY INCLUDES PNEUMATIC OR HYDRAULIC CONT
#### UMBC- CHEMICAL UMBILICAL
#### UMBE- ELECTRICAL UMBILICAL
#### UMBH- HYDRAULIC UMBILICAL


### Status Codes
#### A/C- ABANDONED AND COMBINED
#### ABN- ABANDONED
#### ACT- ACTIVE
#### CNCL- CANCELLED
#### COMB- COMBINED
#### O/C- OUT AND COMBINED
#### OUT- OUT OF SERVICE
#### PABN- PROPOSE ABANDONMENT
#### PREM- PROPOSE REMOVAL
#### PROP- PROPOSED
#### R/A- RELINQUISHED AND ABANDONED
#### R/C- RELINQUISHED AND COMBINED
#### R/R- RELINQUISHED AND REMOVED
#### RELQ- RELINQUISHED
#### REM- REMOVED

pipelines <- st_read(dsn = pipelines_dir, layer = "Pipelines") %>%
  # reproject the coordinate reference system to match study area data (EPSG:5070)
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # filter for gas and oil pipelines
  dplyr::filter(PROD_CODE %in% c("BLGH", "BLKG", "BLKO", "BLOH",
                                "FLG",
                                "G/C", "G/CH", "G/O", "G/OH", "GAS", "GASH",
                                "INJ",
                                "LGER", "LIFT", "LPRO",
                                "METH",
                                "NGER", "NGL",
                                "O/W", "OIL", "OILH",
                                "SPLY") &
                  STATUS_CODE %in% c("A/C", "ACT",
                                     "COMB",
                                     "O/C",
                                     "PROP", "PABN", "PREM",
                                     "R/C", "RELQ")) %>%
  # obtain only pipelines in the study area
  sf::st_intersection(study_area) %>%
  # create field called "layer" and fill with "pipelines" for summary
  dplyr::mutate(layer = "pipelines") %>%
  #  add a setback (buffer) distance of 500 meters
  sf::st_buffer(dist = 500) %>%
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
st_write(obj = pipelines, dsn = analysis_gpkg, "pipelines", append = F)

## Pipelines geopackage
st_write(obj = pipelines, dsn = pipelines_gpkg, "pipelines", append = F)
