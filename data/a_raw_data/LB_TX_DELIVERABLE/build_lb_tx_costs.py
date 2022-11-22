from rex import Resource
import rasterio
import json
import numpy as np
import pandas as pd
import geopandas as gpd
from osgeo import gdal
from skimage.graph import route_through_array
from shapely.geometry import LineString
import time
import multiprocessing as mp
from tqdm import tqdm
from itertools import repeat



#looking at 1500MW costs
cost_1GW = rasterio.open("/shared-projects/rev/projects/goMexico/data/raster/costs_clipped_wea.tif")

#points on coastline
points = gpd.read_file("/shared-projects/rev/projects/goMexico/data/vector/wea_coast_points.gpkg")
points = points.to_crs(cost_1GW.crs)
points['id'] = points.index


poi = gpd.read_file("/shared-projects/rev/projects/goMexico/data/vector/prioritzed_poi_update_wea.gpkg")
poi = poi.to_crs(cost_1GW.crs)

#from https://gis.stackexchange.com/questions/28583/gdal-perform-simple-least-cost-path-analysis


#converts raster to array
def raster2array(rasterfn):
    raster = gdal.Open(rasterfn)
    band = raster.GetRasterBand(1)
    array = band.ReadAsArray()
    return array  
    

#offsets coordinates to match array indices
def coord2pixelOffset(rasterfn,x,y):
    raster = gdal.Open(rasterfn)
    geotransform = raster.GetGeoTransform()
    originX = geotransform[0]
    originY = geotransform[3] 
    pixelWidth = geotransform[1] 
    pixelHeight = geotransform[5]
    xOffset = int((x - originX)/pixelWidth)
    yOffset = int((y - originY)/pixelHeight)
    return xOffset,yOffset


#this needs to be run for all the poi, and then the minimal length, cost needs to be returned
def createPath(CostSurfacefn,costSurfaceArray,startCoordID,stopCoordID):   

    startCoord = points[points['id'] == startCoordID].geometry
    stopCoord = poi[poi['ID'] == stopCoordID].geometry


    # coordinates to array index
    startCoordX = startCoord.x
    startCoordY = startCoord.y
    startIndexX,startIndexY = coord2pixelOffset(CostSurfacefn,startCoordX,startCoordY)
    
    stopCoordX = stopCoord.x
    stopCoordY = stopCoord.y
    stopIndexX,stopIndexY = coord2pixelOffset(CostSurfacefn,stopCoordX,stopCoordY)
    
    # create path, no diagonal moves
    indices, weight = route_through_array(costSurfaceArray, (startIndexY,startIndexX), (stopIndexY,stopIndexX),geometric=False,fully_connected=False)
    
    #converting path to linestring in order to map
    indicesT = np.array(indices).T
    pts = rasterio.transform.xy(transform=cost_1GW.transform, rows=indicesT[0], cols=indicesT[1])
    path = gpd.GeoDataFrame(pd.DataFrame(), geometry=gpd.points_from_xy(x=pts[0], y=pts[1], crs=cost_1GW.crs))
    line = gpd.GeoDataFrame(pd.DataFrame(), geometry=path.apply(lambda x: LineString(x)), crs=cost_1GW.crs)
    line['len_km'] = (len(indices) * 90) / 1000 #km
    line['cost'] = weight
    line['startID'] = startCoordID
    line['endID'] = stopCoordID

    return line


# creates array from cost surface raster
costSurfaceArray = raster2array("/shared-projects/rev/projects/goMexico/data/raster/costs_clipped_wea.tif")
CostSurfacefn = "/shared-projects/rev/projects/goMexico/data/raster/costs_clipped_wea.tif"
overall_cost_table = gpd.GeoDataFrame(crs=cost_1GW.crs)


#iterates through all starting points and finds LCP for each
for i in points['id']:

    ind_cost_table = gpd.GeoDataFrame(crs=cost_1GW.crs)

    print(f"running for coast point {i} out of {max(points['id'])}")

    with mp.Pool(mp.cpu_count()) as pool:
        for o in tqdm(pool.starmap(createPath, zip(repeat(CostSurfacefn), repeat(costSurfaceArray), repeat(i), poi['ID'])), total=len(poi['ID'])):
            ind_cost_table = ind_cost_table.append(o)
    ind_cost_table = ind_cost_table.reset_index(drop=True)
    overall_cost_table = overall_cost_table.append(ind_cost_table.loc[ind_cost_table['cost'].idxmin()])
    print(f"done with coast point {i}; {100 * round(i/max(points['id']), 3)}% done")

#this is lines file, called paths.gpkg in deliverable, merged with the coast points in coast_point_costs.gpkg
gpd.GeoDataFrame(overall_cost_table.reset_index(drop=True)).to_file("/shared-projects/rev/projects/goMexico/data/vector/test_lcp.gpkg")