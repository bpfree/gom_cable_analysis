#################################
### X. Define Ending Point(s) ###
#################################

## Coastline boundary
coastline <- rnaturalearth::ne_coastline(scale = 10, returnclass = "sf") %>%
  sf::st_transform("EPSG:5070")