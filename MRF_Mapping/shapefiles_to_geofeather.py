from geofeather import to_geofeather, from_geofeather
import geopandas as gpd
import os
import pandas as pd

#set the working directory
os.getcwd()
os.chdir('/Users/tphendrickson/Documents/Polymer Data etc./Plastics-MRF Mapping')

def main():
    print('Loading census data...')
    census_data = gpd.read_file('data/input/cb_2019_us_tract_500k/cb_2019_us_tract_500k.shp')
    print('Done')
    print('Re-projecting census tracts to EPSG:3488...')
    census_data = census_data.to_crs(epsg=3488)
    print('Done')

    to_geofeather(census_data, 'data/intermediate/cb_2019_us_tract_500k.feather')

if __name__ == '__main__':
    main()

