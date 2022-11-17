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

#####################################
#####################################

# Clean functions
## Menhaden 2000 - 2003 function
clean_menhaden2000_2003 <- function(menhaden_data){
  menhaden_layer <- menhaden_data %>%
    dplyr::rename("code" = "LOCATION") %>%
    dplyr::inner_join(menhaden_codebook,
                      by = "code") %>%
    # convert to simple feature
    sf::st_as_sf(coords = c("lon", "lat"),
                 # set the coordinate reference system to WGS84
                 crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
    # reproject the coordinate reference system to match BOEM call areas
    sf::st_transform("EPSG:5070") %>% # EPSG 5070 (https://epsg.io/5070)
    # convert date fields from strings to date format (year is abbreviated, hence lowercase)
    dplyr::mutate(SDATE = as.Date(SDATE, format = "%m/%d/%y"),
                  DDATE = as.Date(DDATE, format = "%m/%d/%y"),
                  RDATE = as.Date(SDATE, format = "%m/%d/%y")) %>%
    dplyr::mutate(year = coalesce(SDATE, DDATE, RDATE)) %>%
    # create year field column from SDATE field (year is full, hence uppercase)
    dplyr::mutate(year = format(as.Date(SDATE, format="%d/%m/%Y"),"%Y")) %>%
    dplyr::group_by(locale,
                    year) %>%
    dplyr::summarise(count(locale)) %>%
    dplyr::select(locale,
                  year,
                  freq) %>%
    dplyr::rename("visits" = "freq")
  return(menhaden_layer)
}

clean_menhaden2005_2008 <- function(menhaden_data){
  menhaden_layer <- menhaden_data %>%
    dplyr::rename("code" = "location") %>%
    dplyr::inner_join(menhaden_codebook,
                      by = "code") %>%
    # convert to simple feature
    sf::st_as_sf(coords = c("lon", "lat.y"),
                 # set the coordinate reference system to WGS84
                 crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
    # reproject the coordinate reference system to match BOEM call areas
    sf::st_transform("EPSG:5070") %>%
    # convert date fields from strings to date format (year is abbreviated, hence lowercase)
    dplyr::mutate(sdate = as.Date(SDATE, format = "%m/%d/%y"),
                  rdate = as.Date(RDATE, format = "%m/%d/%y")) %>%
    dplyr::mutate(year = coalesce(sdate, rdate)) %>%
    # create year field column from SDATE field (year is full, hence uppercase)
    dplyr::mutate(year = format(as.Date(year, format="%d/%m/%Y"),"%Y")) %>%
    dplyr::group_by(locale,
                    year) %>%
    dplyr::summarise(count(locale)) %>%
    dplyr::select(locale,
                  year,
                  freq) %>%
    dplyr::rename("visits" = "freq")
  return(menhaden_layer)
}

clean_menhaden2011_2019 <- function(menhaden_data){
  menhaden_layer <- menhaden_data %>%
    dplyr::rename("code" = "location") %>%
    dplyr::inner_join(menhaden_codebook,
                      by = "code") %>%
    # convert to simple feature
    sf::st_as_sf(coords = c("lon", "lat"),
                 # set the coordinate reference system to WGS84
                 crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
    # reproject the coordinate reference system to match BOEM call areas
    sf::st_transform("EPSG:5070") %>%
    # create year field column from SDATE field (month is abbreviated thus lowercase b; year is abbreviated, hence lowercase)
    dplyr::mutate(year = format(as.Date(sdate, format = "%d-%b-%y"),"%Y")) %>%
    dplyr::group_by(locale,
                    year) %>%
    dplyr::summarise(count(locale)) %>%
    dplyr::select(locale,
                  year,
                  freq) %>%
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
menhaden2000 <- read.csv(paste(menhaden_dir, "menhaden2000.csv", sep = "/")) %>%
  clean_menhaden2000_2003()

menhaden2001 <- read.csv(paste(menhaden_dir, "menhaden2001.csv", sep = "/")) %>%
  clean_menhaden2000_2003()

menhaden2002 <- read.csv(paste(menhaden_dir, "menhaden2002.csv", sep = "/")) %>%
  clean_menhaden2000_2003()

menhaden2003 <- read.csv(paste(menhaden_dir, "menhaden2003.csv", sep = "/")) %>%
  clean_menhaden2000_2003()

menhaden2004 <- read.csv(paste(menhaden_dir, "menhaden2004.csv", sep = "/")) %>%
  dplyr::rename("code" = "LOCATION") %>%
  dplyr::inner_join(menhaden_codebook,
                    by = "code") %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("lon", "lat"),
               # set the coordinate reference system to WGS84
               crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
  # reproject the coordinate reference system to match BOEM call areas
  sf::st_transform("EPSG:5070") %>%
  # convert date fields from strings to date format (year is abbreviated, hence lowercase)
  dplyr::mutate(sdate = as.Date(sdate, format = "%m/%d/%y"),
                ddate = as.Date(ddate, format = "%m/%d/%y"),
                rdate = as.Date(rdate, format = "%m/%d/%y")) %>%
  dplyr::mutate(year = coalesce(sdate, ddate, rdate)) %>%
  # create year field column from SDATE field (year is full, hence uppercase)
  dplyr::mutate(year = format(as.Date(year, format="%d/%m/%Y"),"%Y")) %>%
  dplyr::group_by(locale,
                  year) %>%
  dplyr::summarise(count(locale)) %>%
  dplyr::select(locale,
                year,
                freq) %>%
  dplyr::rename("visits" = "freq")
  
menhaden2005 <- read.csv(paste(menhaden_dir, "menhaden2005.csv", sep = "/")) %>%
  clean_menhaden2005_2008()

menhaden2006 <- read.csv(paste(menhaden_dir, "menhaden2006.csv", sep = "/")) %>%
  clean_menhaden2005_2008()

menhaden2007 <- read.csv(paste(menhaden_dir, "menhaden2007.csv", sep = "/")) %>%
  clean_menhaden2005_2008()

menhaden2008 <- read.csv(paste(menhaden_dir, "menhaden2008.csv", sep = "/")) %>%
  clean_menhaden2005_2008()

menhaden2009 <- read.csv(paste(menhaden_dir, "menhaden2009.csv", sep = "/")) %>%
  dplyr::rename("code" = "location") %>%
  dplyr::inner_join(menhaden_codebook,
                    by = "code") %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("lon", "lat.y"),
               # set the coordinate reference system to WGS84
               crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
  # reproject the coordinate reference system to match BOEM call areas
  sf::st_transform("EPSG:5070") %>%
  # create year field column from SDATE field (month is abbreviated hence lowercase b; year is short, hence lowercase)
  dplyr::mutate(year = format(as.Date(sdate, format="%d-%b-%y"),"%Y")) %>%
  dplyr::group_by(locale,
                  year) %>%
  dplyr::summarise(count(locale)) %>%
  dplyr::select(locale,
                year,
                freq) %>%
  dplyr::rename("visits" = "freq")

menhaden2010 <- read.csv(paste(menhaden_dir, "menhaden2010.csv", sep = "/")) %>%
  dplyr::rename("code" = "location") %>%
  dplyr::inner_join(menhaden_codebook,
                    by = "code") %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("lon", "lat.y"),
               # set the coordinate reference system to WGS84
               crs = 4326) %>% # EPSG 4326 (https://epsg.io/4326)
  # reproject the coordinate reference system to match BOEM call areas
  sf::st_transform("EPSG:5070") %>%
  # create year field column from SDATE field (month is abbreviated thus lowercase b; year is full, hence uppercase)
  dplyr::mutate(year = format(as.Date(sdate, format = "%d%b%Y"),"%Y")) %>%
  dplyr::group_by(locale,
                  year) %>%
  dplyr::summarise(count(locale)) %>%
  dplyr::select(locale,
                year,
                freq) %>%
  dplyr::rename("visits" = "freq")

menhaden2011 <- read.csv(paste(menhaden_dir, "menhaden2011.csv", sep = "/")) %>%
  clean_menhaden2011_2019()
  
menhaden2012 <- read.csv(paste(menhaden_dir, "menhaden2012.csv", sep = "/")) %>%
  clean_menhaden2011_2019()

menhaden2013 <- read.csv(paste(menhaden_dir, "menhaden2013.csv", sep = "/")) %>%
  clean_menhaden2011_2019()

menhaden2014 <- read.csv(paste(menhaden_dir, "menhaden2014.csv", sep = "/")) %>%
  clean_menhaden2011_2019()

menhaden2015 <- read.csv(paste(menhaden_dir, "menhaden2015.csv", sep = "/")) %>%
  clean_menhaden2011_2019()

menhaden2016 <- read.csv(paste(menhaden_dir, "menhaden2016.csv", sep = "/")) %>%
  clean_menhaden2011_2019()

menhaden2017 <- read.csv(paste(menhaden_dir, "menhaden2017.csv", sep = "/")) %>%
  clean_menhaden2011_2019()

menhaden2018 <- read.csv(paste(menhaden_dir, "menhaden2018.csv", sep = "/")) %>%
  clean_menhaden2011_2019()

menhaden2019 <- read.csv(paste(menhaden_dir, "menhaden2019.csv", sep = "/")) %>%
  clean_menhaden2011_2019()
