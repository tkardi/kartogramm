"""
Benchmarking shapely for unioning features.
Details at https://github.com/tkardi/kahhelgramm/blob/master/benchmarks/README.md
"""
import json
import os
from shapely import speedups
from shapely.geometry import asShape
from shapely.ops import unary_union

if speedups.available:
    speedups.enable()

feature_dump = {}
merged = {
    "type":"FeatureCollection",
    "crs":{"type":"name","properties":{"name":"urn:ogc:def:crs:EPSG::3301"}},
    "features":[]
    }

def listFiles(in_folder):
    """Lists all tile-gram files in the specified folder"""
    for (dirpath, dirnames, filenames) in os.walk(in_folder):
        for filename in filenames:
            if filename not in ['index.json', 'merged.json']:
                yield os.path.join(dirpath, filename)

def getFeatures(file_path):
    """Returns features from the specified GeoJSON file"""
    with open(file_path) as src:
        feature_collection = json.loads(src.read())
    return feature_collection.get('features', [])

def getIndex(in_folder):
    """Returns the tile-gram index"""
    with open(os.path.join(in_folder, 'index.json')) as src:
        index = json.loads(src.read())
    return index

def groupFeatureById(feature, index):
    """Dissolves GeoJSON feature elements by their "id" value."""
    feature_id = feature['id']
    if feature_id not in feature_dump:
        feature_dump[feature_id] = {
            'geometry':[],
            'properties':feature['properties'],
            'id':feature_id}
    feature_dump[feature_id]['geometry'].append(asShape(feature['geometry']))
    if len(feature_dump[feature_id]['geometry']) == len(index[feature_id]):
        feature_dump[feature_id]['geometry'] = unary_union(
            feature_dump[feature_id]['geometry']).__geo_interface__
        #merged['features'].append(feature_dump[feature_id])
        # this is the place we'd write this feature from dump to disk
        # ...
        # and then remove it from dump
        del feature_dump[feature_id]

def main(in_folder):
    """Main entry point to process a folder of tile-gram files"""
    merged['features'] = []
    index = getIndex(in_folder)
    for file_path in listFiles(in_folder):
        [groupFeatureById(feature, index) for feature in getFeatures(
            file_path)]


if __name__ == '__main__':
    import sys
    in_folder = sys.argv[1]
    main(in_folder)
