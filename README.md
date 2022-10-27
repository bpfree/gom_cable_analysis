# Gulf of Mexico Cable Prioritization Modelling

This is the GitHub repository that details the cable site prioritization for the Gulf of Mexico offshore wind energy areas.

#### **Repository Structure**
* **data**
  - **raw_data:** the raw data integrated in the analysis
  - **intermediate_data:** disaggregated processed data
  - **analysis_data:** processed data for analyzing
  - **raster_data:** raster data 
  - **final_data:**
* **code:** scripts for cleaning, processing, and analyzing data
* **figures:** figures generated to visualize analysis

The full data repository is accessible on [Google Drive](https://drive.google.com/drive/folders/1AGuMCNFLcqwIMokV9GzwFpY74GubB1lb). You may need to request access to the folder.

**__Note for PC users:__** The code was written on a Mac so to run the scripts replace "/" in the pathnames for directories with "\\".

Please contact Brian Free (brian.free@noaa.gov) with any questions.

#### **Data sources**
| Layer | Data Source | Data Name | Metadata |
| ------------- | ------------- | ------------- | ------------- |
| Landmasses | United States Geological Survey | [Global Islands](https://rmgsc.cr.usgs.gov/outgoing/ecosystems/Global/USGSEsriWCMC_GlobalIslands_v3.mpk) | [Global Island Explorer](https://rmgsc.cr.usgs.gov/gie/)
| Seagreass | MarineCadastre | [Seagrasses](https://marinecadastre.gov/downloads/data/mc/Seagrass.zip) | [Seagrass](https://www.fisheries.noaa.gov/inport/item/56960/)
| Seagrass | Texas Park and Wildlife Department | [Seagrass (2012)](https://tpwd.texas.gov/gis/resources/tpwd-seagrass.zip)
| Seagrass | Texas Park and Wildlife Department | [Christmas Bay / West Bay (2015)](https://tpwd.texas.gov/gis/resources/tpwd-seagrass.zip)
| Seagrass | Texas Park and Wildlife Department | [NOAA (2012)](https://tpwd.texas.gov/gis/resources/tpwd-seagrass.zip)
| Seagrass | NOAA NCEI | [Gulfwide Subaquatic Vegetation](https://www.ncei.noaa.gov/waf/data-atlas-waf/biotic/documents/GulfwideSAV.zip)
| Oyster | Texas Park and Wildlife Department | [Copano Bay](https://tpwd.texas.gov/landwater/water/habitats/coastal-fisheries-habitat-assessment-team/resources/copano-bay-habitat-classification-shapefiles.zip)
| Oyster | Texas Park and Wildlife Department | [Espiritu Santo](https://tpwd.texas.gov/landwater/water/habitats/coastal-fisheries-habitat-assessment-team/resources/espiritu-santo-oyster-habitat-shapefiles.zip)
| Oyster | Texas Park and Wildlife Department | [Galveston Bay](https://tpwd.texas.gov/landwater/water/habitats/coastal-fisheries-habitat-assessment-team/resources/galveston-bay-habitat-classification-shapefiles.zip)
| Oyster | Texas Park and Wildlife Department | [Lavaca Tres Palacios](https://tpwd.texas.gov/landwater/water/habitats/coastal-fisheries-habitat-assessment-team/resources/lavaca-tres-palacios-habitat-shapefile.zip)
| Oyster | Texas Park and Wildlife Department | [West Galveston Bay](https://tpwd.texas.gov/landwater/water/habitats/coastal-fisheries-habitat-assessment-team/resources/west-galveston-bay-habitat-classification-shapefiles.zip)
| Oyster | Texas Park and Wildlife Department | [Oyster restoration sites](https://tpwd.texas.gov/landwater/water/habitats/coastal-fisheries-habitat-assessment-team/resources/tpwd-oyster-restoration-sites.zip)
| Oyster | United States Geological Survey | [Oysters 2011 - Gulf of Mexico](https://www.sciencebase.gov/catalog/item/594830afe4b062508e344418)
| Oyster | Unknown | Lavaca Oysters Harper (2002)
| Oyster | Unknown | Oyster Reefs NOAA (2007)
| Oyster | Unknown | Powell (1995) | Appear to be data from the [Texas GLO Coastal Research Map viewer](https://cgis.glo.texas.gov/rmc/index.html)
| Oyster | Unknown | Oyster Lease Areas (2018) | Appear to be data from the [Texas HHS Shellfish ArcMap page](https://txdshsea.maps.arcgis.com/apps/webappviewer/index.html?id=801ef406eada4f88b19d960b57d5d680)
| Oyster | Unknown | Oyster Lease (Texas)
| Bathymetry | NOAA NCEI | [Western Gulf of Mexico Coastal Relief Model](https://www.ngdc.noaa.gov/mgg/coastal/crm.html) | [Coastal Relief Model](https://www.ngdc.noaa.gov/mgg/coastal/crm.html)
| Shipping Lanes | NOAA | [Shipping Lanes](http://encdirect.noaa.gov/theme_layers/data/shipping_lanes/shippinglanes.zip)
| Shipping Lanes | Texas Railroad Commission | [Shipping Channels](https://mft.rrc.texas.gov/link/7a5577fc-e325-4d7b-bc41-daf23f4b6e80) | [User Guide](https://www.rrc.texas.gov/media/kmld3uzj/digital-map-information-user-guide.pdf)
| Conservation Areas | Texas Parks and Wildlife Department | [Texas Wildlife Management Areas](https://tpwd.texas.gov/gis/resources/wildlife-management-areas.zip)
| Conservation Areas | Texas Parks and Wildlife Department | [Texas State Parks](https://tpwd.texas.gov/gis/resources/tpwd-statepark-boundaries.zip)
| Conservation Areas | United States Fish and Wildlife | [National Realty Boundaries](https://gis-fws.opendata.arcgis.com/datasets/fws::fws-national-realty-boundaries/explore?location=5.461953%2C0.000000%2C1.93) | [About](https://gis-fws.opendata.arcgis.com/datasets/fws::fws-national-realty-boundaries/about)
| Lightering Zones | NOAA | [Lightering Zones](https://marinecadastre.gov/downloads/data/mc/LighteringZone.zip) | [Metadata](https://www.fisheries.noaa.gov/inport/item/66149) and [additional information](https://www.govinfo.gov/content/pkg/CFR-2018-title33-vol2/xml/CFR-2018-title33-vol2-part156.xml#seqnum156.300)
| Aritificial Reefs | Texas Parks and Wildlife Department | [Artificial Reefs](https://tpwd.texas.gov/gis/resources/tpwd-artificial-reef-data.zip)
| Fish Haven (Obstruction) | NOAA | Obstruction Areas | [ENC Direct](https://encdirect.noaa.gov/)
| Unexploded Ordnance | NOAA | [Unexploded Ordnance Areas](https://marinecadastre.gov/downloads/data/mc/UnexplodedOrdnance.zip) | [MarineCadastre](https://www.fisheries.noaa.gov/inport/item/66206)
| Unexploded Ordnance | NOAA | [Unexploded Ordnance Locations](https://marinecadastre.gov/downloads/data/mc/UnexplodedOrdnance.zip) | [MarineCadastre](https://www.fisheries.noaa.gov/inport/item/66208)
| Oil and Gas Leases | BOEM | [Active Blocks](https://www.data.boem.gov/Mapping/Files/ActiveLeasePolygons.gdb.zip) | [Metadata](https://www.data.boem.gov/Mapping/Files/actlease_meta.html)
| Sediment | BOEM | [Significiant Sediment Blocks](https://www.data.boem.gov/Mapping/Files/actlease_meta.html) | [Metadata](https://mmis.doi.gov/BOEMMMIS/metadata/WAF/GOMSigSedBlocks.xml)
| Wells and Boreholes | BOEM / BSEE | [Oil and Gas Boreholes](https://www.data.boem.gov/Well/Borehole/Default.aspx) | [Field Definitions](https://www.data.boem.gov/Main/HtmlPage.aspx?page=borehole) and [Field Values](https://www.data.boem.gov/Main/HtmlPage.aspx?page=boreholeFields)
| No Activity Zones | BOEM | No Activity Zones | [Map package information](https://www.boem.gov/sites/default/files/oil-and-gas-energy-program/Leasing/Regional-Leasing/Gulf-of-Mexico-Region/Topographic-Features-Stipulation-Map-Package.pdf)
| Anchorage Areas | NOAA | [Anchorage Areas](https://marinecadastre.gov/downloads/data/mc/Anchorage.zip) | [MarineCadastre](https://www.fisheries.noaa.gov/inport/item/48849)
| Drilling Platforms | BOEM / BSEE | [Oil and Gas Drilling Platforms](https://www.data.bsee.gov/Platform/PlatformStructures/Default.aspx) | [Metadata](https://www.data.bsee.gov/Main/Platform.aspx)
| Submarine Cables | NOAA | [Submarine Cable Areas](https://marinecadastre.gov/downloads/data/mc/SubmarineCableArea.zip) | [MarineCadastre](https://www.fisheries.noaa.gov/inport/item/66190)
| Submarine Cables | NOAA | [NOAA Charted Submarine Cables](https://marinecadastre.gov/downloads/data/mc/SubmarineCable.zip) | [MarineCadastre](https://www.fisheries.noaa.gov/inport/item/57238)
| Submarine Cables | Confidential | Geocables
| Aids to Navigation | NOAA | [Aids to Navigation](https://marinecadastre.gov/downloads/data/mc/AtoN.zip) | [MarineCadastre](https://www.fisheries.noaa.gov/inport/item/56120)
| Environmental Sensors | NDBC | [Observation Locations](https://www.ndbc.noaa.gov/kml/marineobs_by_pgm.kml) | [Site page](ttps://www.ndbc.noaa.gov/obs.shtml)
| Environmental Sensors | GCOOS | [Federal Assets](https://data.gcoos.org/inventory.php#tabs-3) | [Site page](https://data.gcoos.org/)
| Environmental Sensors | GCOOS | [Regional Assets](https://data.gcoos.org/inventory.php#tabs-2) | [Site page](https://data.gcoos.org/)
| Environmental Sensors | IOOS | [2020 - 2021 Raw Assets](https://data.gcoos.org/inventory.php#tabs-3) | [Metadata](http://erddap.ioos.us/erddap/info/raw_asset_inventory/index.html) and [background information](https://github.com/ioos/ioos-asset-inventory/blob/main/README.md)
| Pipelines | BOEM | [Pipelines](https://www.data.boem.gov/Mapping/Files/Pipelines.gdb.zip) | [Metadata](https://www.data.boem.gov/Mapping/Files/ppl_arcs_meta.html) and [field definitions](https://www.data.boem.gov/Mapping/Files/ppl_arcs_meta.html)

#### Known issues
