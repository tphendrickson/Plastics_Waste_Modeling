#!/usr/bin/env python
# coding: utf-8

import geopandas as gpd
import pandas as pd

import os
from geofeather import from_geofeather
from shapely.ops import nearest_points
from shapely.geometry import Point, MultiPoint

# Set the working directory
os.getcwd()
os.chdir('/Users/tphendrickson/Documents/Plastics Data/Plastics-MRF Mapping')

def main():
    # Import tl_2017_06_tabblock10.shp from zip file tl_2017_06_tabblock10 of census block information
    # column with polygon information is named geometry
    print('Loading census tract data...')
    census_data = from_geofeather('data/intermediate/cb_2019_us_tract_500k.feather') #change path if needed
    print(f'Loaded {len(census_data)} census tracts')
    print('Done')

    # Store columns containing geoids and polygons of census blocks
    census_tracts = census_data[['GEOID', 'geometry']]
    census_tracts['Centroid'] = census_tracts.centroid

    print('Loading MRF data...')
    MRF_sites = pd.read_csv('US_MRF_Compilation.csv') #this is MRF survey data for purchase from Governmental Advisory Associates
    print('Done')

    # Make geodataframe of MRF sites
    sites_gdf = gpd.GeoDataFrame(
        MRF_sites,
        geometry=gpd.points_from_xy(MRF_sites.lon, MRF_sites.lat),
    )
    # Define long lat CRS for points
    sites_gdf = sites_gdf.set_crs(epsg=4326)
    # Re-project site buffer to same CRS as census tracts
    print('Re-projecting GeoSeries...')
    sites_gdf = sites_gdf.to_crs(epsg=3488)

    #census_tracts_sample = census_tracts.head(20)

    print('Finding nearest MRF for each census tract...')
    tracts_with_nearest_MRFs = get_nearest_MRF(census_tracts, sites_gdf)
    print('Done')
    out_fpath = 'data/output/tracts_with_nearest_mrfs.csv'
    print(f'Saving to CSV at relative filepath: {out_fpath}')
    tracts_with_nearest_MRFs.to_csv(out_fpath)
    print('Finished')

def get_nearest_MRF(tract_gdf, MRF_gdf, tract_column='Centroid', MRF_geom_column='geometry'):
    # Find nearest MRF to each census tract centroid
    # Code adapted from https://autogis-site.readthedocs.io/en/latest/notebooks/L3/04_nearest-neighbour.html

    nearest_MRF_gdf_rows = []

    for index, row in tract_gdf.iterrows():
        print(f'Working on tract {index} of {tract_gdf.shape[0]}...')

        # transpose and reset index of the current row for cleaner processing
        new_row = row.to_frame().T.reset_index()

        # Create an union of the MRF sites geometries:
        MRF_points = MRF_gdf['geometry'].unary_union

        # Find the nearest MRF to current tract centroid
        nearest_geoms = nearest_points(new_row.at[0, tract_column], MRF_points)

        # Get corresponding values from the MRF df
        nearest_mrf_data = MRF_gdf.loc[MRF_gdf['geometry'] == nearest_geoms[1]]
        nearest_mrf_data = nearest_mrf_data.reset_index()

        for col in nearest_mrf_data.columns:
            new_colname = f'nearest_mrf_{col}'
            new_row[new_colname] = nearest_mrf_data.at[0, col]

        nearest_MRF_gdf_rows.append(new_row)

    res = pd.concat(nearest_MRF_gdf_rows, axis=0)
    return res


if __name__ == '__main__':
    main()




