#####################################
### 29. Menhaden Fishing Summary  ###
#####################################

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
menhaden_dir <- "data/a_raw_data/menhaden_fishing"
analysis_gpkg <- "data/c_analysis_data/gom_cable_study.gpkg"
raster_dir <- "data/d_raster_data"

### Output directories
#### Intermediate directory
menhaden_gpkg <- "data/b_intermediate_data/menhaden_fishing.gpkg"

#####################################
#####################################

# Load study area (to clip habitats to only that area)
study_area <- sf::st_read(dsn = analysis_gpkg, layer = "gom_study_area_marine")

# Load raster grid
gom_raster <- terra::rast(paste(raster_dir, "gom_study_area_marine_100m_raster.grd", sep = "/"))

#####################################
#####################################

# Clean functions
## Menhaden 2000 - 2004 function
clean_menhaden2000_2004 <- function(menhaden_data){
  menhaden_layer <- menhaden_data %>%
    # rename field "LOCATION" to "code"
    dplyr::rename("code" = "LOCATION") %>%
    # join data to the menhaden codebook using the code field
    dplyr::inner_join(menhaden_codebook,
                      by = "code") %>%
    # convert to simple feature
    sf::st_as_sf(coords = c("lon", "lat"),
                 # set the coordinate reference system to WGS84
                 crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
    # reproject the coordinate reference system
    sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
    # convert date fields from strings to date format (year is abbreviated [00 for 2000], hence lowercase)
    dplyr::mutate(SDATE = as.Date(SDATE, format = "%m/%d/%y"),
                  DDATE = as.Date(DDATE, format = "%m/%d/%y"),
                  RDATE = as.Date(SDATE, format = "%m/%d/%y")) %>%
    # fill in year field with next date if the previous one does not have one
    dplyr::mutate(year = coalesce(SDATE, DDATE, RDATE)) %>%
    # update year field (year is full, hence uppercase) so that it is only the year (can drop month and day)
    dplyr::mutate(year = format(as.Date(year, format="%d/%m/%Y"),"%Y")) %>%
    # group data by "locale" and "year" fields
    dplyr::group_by(locale,
                    year) %>%
    # summarise by counting the number per locale
    dplyr::summarise(count(locale)) %>%
    # select the important fields
    dplyr::select(locale,
                  year,
                  freq) %>%
    # rename the "freq" field" as "visits"
    dplyr::rename("visits" = "freq")
  return(menhaden_layer)
}

## Menhaden 2005 - 2008 function
clean_menhaden2005_2008 <- function(menhaden_data){
  menhaden_layer <- menhaden_data %>%
    # rename field "location" to "code"
    dplyr::rename("code" = "location") %>%
    # join data to the menhaden codebook using the code field
    dplyr::inner_join(menhaden_codebook,
                      by = "code") %>%
    # convert to simple feature
    sf::st_as_sf(coords = c("lon", "lat.y"),
                 # set the coordinate reference system to WGS84
                 crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
    # reproject the coordinate reference system
    sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
    # convert date fields from strings to date format (year is abbreviated, hence lowercase)
    dplyr::mutate(sdate = as.Date(SDATE, format = "%m/%d/%Y"),
                  rdate = as.Date(RDATE, format = "%m/%d/%Y")) %>%
    # fill in year field with next date if the previous one does not have one
    dplyr::mutate(year = coalesce(sdate, rdate)) %>%
    # create year field column from year field (year is full, hence uppercase)
    dplyr::mutate(year = format(as.Date(year, format="%d/%m/%Y"),"%Y")) %>%
    # group data by "locale" and "year" fields
    dplyr::group_by(locale,
                    year) %>%
    # summarise by counting the number per locale
    dplyr::summarise(count(locale)) %>%
    # select the important fields
    dplyr::select(locale,
                  year,
                  freq) %>%
    # rename the "freq" field" as "visits"
    dplyr::rename("visits" = "freq")
  return(menhaden_layer)
}

## Menhaden 2011 - 2018 function
clean_menhaden2011_2018 <- function(menhaden_data){
  menhaden_layer <- menhaden_data %>%
    # rename field "location" to "code"
    dplyr::rename("code" = "location") %>%
    # join data to the menhaden codebook using the code field
    dplyr::inner_join(menhaden_codebook,
                      by = "code") %>%
    # convert to simple feature
    sf::st_as_sf(coords = c("lon", "lat"),
                 # set the coordinate reference system to WGS84
                 crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
    # reproject the coordinate reference system
    sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
    # create year field column from SDATE field (month is abbreviated thus lowercase b; year is abbreviated, hence lowercase)
    dplyr::mutate(year = format(as.Date(sdate, format = "%d-%b-%y"),"%Y")) %>%
    # group data by "locale" and "year" fields
    dplyr::group_by(locale,
                    year) %>%
    # summarise by counting the number per locale
    dplyr::summarise(count(locale)) %>%
    # select the important fields
    dplyr::select(locale,
                  year,
                  freq) %>%
    # rename the "freq" field" as "visits"
    dplyr::rename("visits" = "freq")
  return(menhaden_layer)
}

#####################################
#####################################

# See files in Menhaden directory
list.files(menhaden_dir)

# Load grid codebook
menhaden_codebook <- read.csv(paste(menhaden_dir, "menhaden_grid_code.csv", sep = "/"))

# Load menhaden data
## 2000 fishing data
menhaden2000 <- read.csv(paste(menhaden_dir, "menhaden2000.csv", sep = "/")) %>%
  clean_menhaden2000_2004()

## 2001 fishing data
menhaden2001 <- read.csv(paste(menhaden_dir, "menhaden2001.csv", sep = "/")) %>%
  clean_menhaden2000_2004()

## 2002 fishing data
menhaden2002 <- read.csv(paste(menhaden_dir, "menhaden2002.csv", sep = "/")) %>%
  clean_menhaden2000_2004()

## 2003 fishing data
menhaden2003 <- read.csv(paste(menhaden_dir, "menhaden2003.csv", sep = "/")) %>%
  clean_menhaden2000_2004()

## 2004 fishing data
menhaden2004 <- read.csv(paste(menhaden_dir, "menhaden2004.csv", sep = "/")) %>%
  # rename fields so they conform to the clean function
  dplyr::rename("SDATE" = "sdate",
                "DDATE" = "ddate",
                "RDATE" = "rdate") %>%
  clean_menhaden2000_2004()

## 2005 fishing data  
menhaden2005 <- read.csv(paste(menhaden_dir, "menhaden2005.csv", sep = "/")) %>%
  clean_menhaden2005_2008()

## 2006 fishing data
menhaden2006 <- read.csv(paste(menhaden_dir, "menhaden2006.csv", sep = "/")) %>%
  # convert date fields from strings to date format (year is abbreviated, hence lowercase) so that they conform to clean function
  dplyr::mutate(SDATE = format(as.Date(SDATE, format = "%m/%d/%y"), "%m/%d/%Y"),
                RDATE = format(as.Date(RDATE, format = "%m/%d/%y"), "%m/%d/%Y")) %>%
  clean_menhaden2005_2008

## 2007 fishing data
menhaden2007 <- read.csv(paste(menhaden_dir, "menhaden2007.csv", sep = "/")) %>%
  clean_menhaden2005_2008()

## 2008 fishing data
menhaden2008 <- read.csv(paste(menhaden_dir, "menhaden2008.csv", sep = "/")) %>%
  # convert date fields from strings to date format (year is abbreviated, hence lowercase) so that they conform to clean function
  dplyr::mutate(SDATE = format(as.Date(SDATE, format = "%d%b%Y"), "%m/%d/%Y"),
                RDATE = format(as.Date(RDATE, format = "%d%b%Y"), "%m/%d/%Y")) %>%
  clean_menhaden2005_2008()

## 2009 fishing data
menhaden2009 <- read.csv(paste(menhaden_dir, "menhaden2009.csv", sep = "/")) %>%
  # rename field "location" to "code"
  dplyr::rename("code" = "location") %>%
  # join data to the menhaden codebook using the code field
  dplyr::inner_join(menhaden_codebook,
                    by = "code") %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("lon", "lat.y"),
               # set the coordinate reference system to WGS84
               crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
  # reproject the coordinate reference system
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # create year field column from SDATE field (month is abbreviated hence lowercase b; year is short, hence lowercase)
  dplyr::mutate(year = format(as.Date(sdate, format="%d-%b-%y"),"%Y")) %>%
  # group data by "locale" and "year" fields
  dplyr::group_by(locale,
                  year) %>%
  # summarise by counting the number per locale
  dplyr::summarise(count(locale)) %>%
  # select the important fields
  dplyr::select(locale,
                year,
                freq) %>%
  # rename the "freq" field" as "visits"
  dplyr::rename("visits" = "freq")

## 2010 fishing data
menhaden2010 <- read.csv(paste(menhaden_dir, "menhaden2010.csv", sep = "/")) %>%
  # rename field "location" to "code"
  dplyr::rename("code" = "location") %>%
  # join data to the menhaden codebook using the code field
  dplyr::inner_join(menhaden_codebook,
                    by = "code") %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("lon", "lat.y"),
               # set the coordinate reference system to WGS84
               crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
  # reproject the coordinate reference system
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # create year field column from SDATE field (month is abbreviated thus lowercase b; year is full, hence uppercase)
  dplyr::mutate(year = format(as.Date(sdate, format = "%d%b%Y"),"%Y")) %>%
  # group data by "locale" and "year" fields
  dplyr::group_by(locale,
                  year) %>%
  # summarise by counting the number per locale
  dplyr::summarise(count(locale)) %>%
  # select the important fields
  dplyr::select(locale,
                year,
                freq) %>%
  # rename the "freq" field" as "visits"
  dplyr::rename("visits" = "freq")

## 2011 fishing data
menhaden2011 <- read.csv(paste(menhaden_dir, "menhaden2011.csv", sep = "/")) %>%
  clean_menhaden2011_2018()

## 2012 fishing data
menhaden2012 <- read.csv(paste(menhaden_dir, "menhaden2012.csv", sep = "/")) %>%
  clean_menhaden2011_2018()

## 2013 fishing data
menhaden2013 <- read.csv(paste(menhaden_dir, "menhaden2013.csv", sep = "/")) %>%
  clean_menhaden2011_2018()

## 2014 fishing data
# ***Note: no data in study area
menhaden2014 <- read.csv(paste(menhaden_dir, "menhaden2014.csv", sep = "/")) %>%
  clean_menhaden2011_2018()

## 2015 fishing data
menhaden2015 <- read.csv(paste(menhaden_dir, "menhaden2015.csv", sep = "/")) %>%
  clean_menhaden2011_2018()

## 2016 fishing data
menhaden2016 <- read.csv(paste(menhaden_dir, "menhaden2016.csv", sep = "/")) %>%
  clean_menhaden2011_2018()

## 2017 fishing data
menhaden2017 <- read.csv(paste(menhaden_dir, "menhaden2017.csv", sep = "/")) %>%
  clean_menhaden2011_2018()

## 2018 fishing data
# ***Note: no data in study area
menhaden2018 <- read.csv(paste(menhaden_dir, "menhaden2018.csv", sep = "/")) %>%
  clean_menhaden2011_2018()

## 2019 fishing data
menhaden2019 <- read.csv(paste(menhaden_dir, "menhaden2019.csv", sep = "/")) %>%
  # rename field "location" to "code"
  dplyr::rename("code" = "location") %>%
  # join data to the menhaden codebook using the code field
  dplyr::inner_join(menhaden_codebook,
                    by = "code") %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("lon", "lat"),
               # set the coordinate reference system to WGS84
               crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
  # reproject the coordinate reference system
  sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
  # create year field column from SDATE field (year is full, hence uppercase)
  dplyr::mutate(year = format(as.Date(sdate, format = "%m/%d/%Y"),"%Y")) %>%
  # group data by "locale" and "year" fields
  dplyr::group_by(locale,
                  year) %>%
  # summarise by counting the number per locale
  dplyr::summarise(count(locale)) %>%
  # select the important fields
  dplyr::select(locale,
                year,
                freq) %>%
  # rename the "freq" field" as "visits"
  dplyr::rename("visits" = "freq")

#####################################
#####################################

# Combine menhaden fishing data
## 2000 - 2019
menhaden_2000_2019 <- menhaden2000 %>%
  # combine all the years
  rbind(menhaden2001,
        menhaden2002,
        menhaden2003,
        menhaden2004,
        menhaden2005,
        menhaden2006,
        menhaden2007,
        menhaden2008,
        menhaden2009,
        menhaden2010,
        menhaden2011,
        menhaden2012,
        menhaden2013,
        menhaden2014, # included despite no data being in study area
        menhaden2015,
        menhaden2016,
        menhaden2017,
        menhaden2018, # included despite no data being in study area
        menhaden2019) %>%
  # turn each unique year into a field and fill with the number of visits in that year at the location
  tidyr::spread(key = year,
                value = visits) %>%
  # create new field of total visits across all years
  dplyr::mutate(total_visits = rowSums(across(where(is.numeric)), na.rm = T)) %>%
  # recode locale to have them match
  dplyr::mutate(locale = recode(locale,
                                "Breeze Inn (Beach House)" = "Beach House (Breeze Inn)")) %>%
  # remove any duplicated rows (thus to remove double counting)
  distinct() %>%
  # recode locales to have matching names
  dplyr::mutate(locale= recode(locale,
                               "Cattle Pens" = "Beach House (Breeze Inn)",
                               "Refinery" = "Atlantic Richfield")) %>%
  # group by locale
  dplyr::group_by(locale) %>%
  # summarise total visits by locale
  dplyr::summarise(total_visits = sum(total_visits))

#####################################
#####################################

# Create grid around points
sf::st_crs(menhaden_2000_2019, parameters = TRUE)$units_gdal

square_grid <- sf::st_buffer(x = menhaden_2000_2019,
                             # distance is 18.5 km = 18500 meters (1 minute = 18.5km)
                             dist = 8000,
                             endCapStyle = "SQUARE") %>%
  # obtain menhaden fishing within study area
  rmapshaper::ms_clip(study_area) %>%
  # filter only areas of importance
  dplyr::filter(locale %in% c("Atlantic Richfield",
                              "Beach House (Breeze Inn)",
                              "Freeport (Brazos River)",
                              "High Island (County Line)")) # same data as "County Line (High Island)"

#####################################

g <- ggplot2::ggplot() + 
  ggplot2::geom_sf(data = study_area, fill = NA, color = "blue", linetype = "dashed") +
  ggplot2::geom_sf(data = square_grid, color = "orange") +
  #geom_sf(data = menhaden_2000_2019, color = "red")
g

#####################################
#####################################

# Convert to raster
menhaden_raster <- terra::rasterize(x = square_grid,
                                    y = gom_raster,
                                    field = "total_visits")

#####################################
#####################################

# Normalizing (low menhaden fishing gets low cost, higher value gets higher cost)
## Create s-shape membership function
### Adapted from https://www.mathworks.com/help/fuzzy/smf.html
smf_function <- function(raster){
  # calculate minimum value
  min <- terra::minmax(raster)[1,]
  
  # calculate maximum value
  max <- terra::minmax(raster)[2,]
  
  # calculate s-scores (more desired values get score of 0 while less desired will increase till 1)
  s_value <- ifelse(raster[] == min, 0, # if value is equal to minimum, score as 0
                    # if value is larger than minimum but lower than mid-value, calculate based on reduction equation
                    ifelse(raster[] > min & raster[] < (min + max) / 2, 2*((raster[] - min) / (max - min))**2,
                           # if value is larger than mid-value but lower than maximum, calculate based on equation
                           ifelse(raster[] >= (min + max) / 2 & raster[] < max, 1 - 2*((raster[] - max) / (max - min))**2,
                                  # if value is equal to maximum, score as 1; otherwise give NA
                                  ifelse(raster[] == max, 1, NA))))
  
  # set values back to the original raster
  slope_svalues <- terra::setValues(raster, s_value)
  
  # return the raster
  return(slope_svalues)
}

# Create menhaden normalization
menhaden_normalize <- menhaden_raster %>%
  smf_function() %>%
  # have data get limited to study area dimensions
  terra::crop(gom_raster,
              mask = T)

#####################################
#####################################

# Export data
## Analysis geopackage
sf::st_write(obj = menhaden_2000_2016, dsn = analysis_gpkg, "menhaden_fishing_2000_2016", append = F)

## Menhaden geopackage
sf::st_write(obj = menhaden_2000_2016, dsn = menhaden_gpkg, "menhaden_fishing_2000_2016", append = F)
sf::st_write(obj = menhaden_2017_2019, dsn = menhaden_gpkg, "menhaden_fishing_2017_2016", append = F)
sf::st_write(obj = menhaden_2000_2019, dsn = menhaden_gpkg, "menhaden_fishing_2000_2019", append = F)

## Raster data
terra::writeRaster(menhaden_normalize, filename = file.path(raster_dir, "menhaden_2000_2019_normalize.grd"), overwrite = T)
