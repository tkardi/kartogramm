# Benchmarking geometric unioning using [shapely](https://github.com/Toblerity/Shapely) and [turf](https://github.com/Turfjs/turf)

## Excercise

Given a directory of GeoJSON files, merge the files therein into one 
`FeatureCollection` dissolving features over `id` value.

## Data

4 different datasets were used, all are Polygon/Multipolygon features. All 
datasets are tiled using the Estonian 1:10K map sheets (with the map sheet 
index as the filename) and all individual tiles are in GeoJSON format as 
`FeatureCollection`s. Background information on the 1:10K map sheet index
is available on the [Estonian Land Board's website](http://geoportaal.maaamet.ee/eng/Maps-and-Data/Coordinate-Systems-and-Map-Sheet-Indexes/Map-Sheet-Indexes-p359.html)

1:10K Map sheets themselves as GeoJSON are available [here](https://raw.githubusercontent.com/tkardi/data/master/base/epk10k.json)

__NB!__ 
Datasets are not fully conformant with the latest [GeoJSON draft](https://tools.ietf.org/html/draft-butler-geojson-05) 
as the geometries are represented in EPSG:3301 coordinate reference system 
(L-EST'97, the Estonian national crs), with a named CRS object specified for
each `FeatureCollection`.

The datasets are summarized in the following table

Dataset | Max vertices/object | Min vertices/object | Avg vertices/object | Total vertices/layer | Objects/layer
:-------|-----------------:|-----------------:|-----------------:|------------------:|-------------:
asustusyksus|17266|7|336.216|1584249|4712
omavalitsus|66858|32|5479.991|1167238|213
maakond|321257|3622|66108.533|991628|15
katastriyksus|1934|4|12.905|7952239|616199

[asustusyksus](https://github.com/tkardi/data/tree/master/ehak/asustusyksus) - Estonian 
3rd level administrative division.

[omavalitsus](https://github.com/tkardi/data/tree/master/ehak/omavalitsus) - Estonian
2nd level administrative division.

[maakond](https://github.com/tkardi/data/tree/master/ehak/omavalitsus/maakond) - Estonian 1st level
administrative division.

[katastriyksus](https://) - cadastral parcels. Data not available for download
because of data licensing conditions by the Estonian Land Board. Nevertheless 
this is an exquisite dataset for testing purposes because of the amount of
features present.

The administrative divison data can also be downloaded in a multitude of formats
from the [Estonian Land Board's website](http://geoportaal.maaamet.ee/eng/Maps-and-Data/Administrative-and-Settlement-Division-p312.html)

## Environment

### System

Win 8.1, 4GB RAM, Intel Core i5-3320M @ 2.6 GHz x64

### Python and shapely

    d:\kahhelgramm\benchmarks>python
    Python 2.7.5 (default, May 15 2013, 22:44:16) [MSC v.1500 64 bit (AMD64)] on win32
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import shapely
    >>> shapely.__version__
    '1.3.0'
    >>> from shapely.geos import geos_version
    >>> geos_version
    (3, 3, 9)
    >>>

### Node and turf

    d:\kahhelgramm\benchmarks>node -v
    v0.12.7

    d:\kahhelgramm\benchmarks>npm list turf
    d:\kahhelgramm\benchmarks
    └── turf@2.0.2


## Results

### Shapely

Python's [timeit](https://docs.python.org/2/library/timeit.html) library is 
used for benchmarking. Here we make use of the [`shapely.speedups`](http://toblerity.org/shapely/manual.html#performance) 
optimizations and [`shapely.ops.unary_union`](http://toblerity.org/shapely/manual.html#shapely.ops.unary_union)
Any pointers for optimization are welcome!

    D:\repos\kahhelgramm\benchmarks>python -m timeit -n 10 -s "import benchmark_shapely as s" "s.main('d:/andmeladu/data/ehak/asustusyksus')"
    10 loops, best of 3: 18.1 sec per loop

    D:\repos\kahhelgramm\benchmarks>python -m timeit -n 10 -s "import benchmark_shapely as s" "s.main('d:/andmeladu/data/ehak/omavalitsus')"
    10 loops, best of 3: 13.3 sec per loop

    D:\repos\kahhelgramm\benchmarks>python -m timeit -n 10 -s "import benchmark_shapely as s" "s.main('d:/andmeladu/data/ehak/maakond')"
    10 loops, best of 3: 14.4 sec per loop

    D:\repos\kahhelgramm\benchmarks>python -m timeit -n 10 -s "import benchmark_shapely as s" "s.main('d:/andmeladu/data/maainfo/katastriyksus')"
    10 loops, best of 3: 140 sec per loop

Code for benchmark_shapely.py can be found [here](benchmark_shapely.py)

### Turf

First off I have to admit that I do not feel very comfortable 
in JavaScript in general, so any pointers as to how to optimize 
the code in benchmark_turf.js are welcome.

Note to self - RTFM! Turf.js requires geometries to be WGS84 geographic 
coordinates ([here](http://turfjs.org/static/docs/)). This means that all 
coordinates need to be recalculated using [these](http://spatialreference.org/ref/epsg/3301/proj4/) 
proj4 parameters.

The general idea for processing the data is the same as with the Shapely 
version - the only difference being that [`turf.union`](http://turfjs.org/static/docs/module-turf_union.html)
accepts only two features at a time, therefore once we have read all
the features with a given `id`, we need to call `turf.union(geomA, geomB)`
`n` times where `n` equals the number of features to be unioned minus one (
because for unioning two features you call the operation only one time).

    D:\repos\kahhelgramm\benchmarks>node benchmark_turf.js 10 d:\andmeladu\data\ehak\asustusyksus\
    10 loops, best: 22.983294142 sec per loop

    D:\repos\kahhelgramm\benchmarks>node benchmark_turf.js 10 d:\andmeladu\data\ehak\omavalitsus\
    10 loops, best: 86.754970093 sec per loop

    D:\repos\kahhelgramm\benchmarks>node benchmark_turf.js 10 d:\andmeladu\data\ehak\maakond\
    10 loops, best: 465.425804572 sec per loop

    D:\repos\kahhelgramm\benchmarks>node benchmark_turf.js 10 d:\andmeladu\data\maainfo\katastriyksus\
    10 loops, best: 108.17799765800001 sec per loop

To account for the possible overhead that the coordinate calculations 
(`EPSG:3301`->`EPSG:4326`) might give for the hole process, let's run 
another set of benchmarks, only this time not really doing the
dissolving (i.e [L51](benchmark_turf.js#L51) commented out):

    D:\repos\kahhelgramm\benchmarks>node benchmark_turf.js 10 d:\andmeladu\data\ehak\asustusyksus\
    10 loops, best: 6.077955144 sec per loop

    D:\repos\kahhelgramm\benchmarks>node benchmark_turf.js 10 d:\andmeladu\data\ehak\omavalitsus\
    10 loops, best: 4.394277747 sec per loop

    D:\repos\kahhelgramm\benchmarks>node benchmark_turf.js 10 d:\andmeladu\data\ehak\maakond\
    10 loops, best: 3.7089712529999996 sec per loop

    D:\repos\kahhelgramm\benchmarks>node benchmark_turf.js 10 d:\andmeladu\data\maainfo\katastriyksus\
    10 loops, best: 73.28946438699995 sec per loop

Code for benchmark_turf.js can be found [here](benchmark_turf.js)

### Summary

Benchmarking results (measured in seconds) are presented in the following table

                  | asustusyksus | omavalitsus | maakond | katastriyksus 
:-----------------|-------------:|------------:|--------:|-------------:
shapely           |         18.1 |        13.3 |    14.4 |         140.0
turf (union:yes)  |         23.0 |        86.8 |   465.4 |         108.2 
turf (union:no)   |          6.1 |         4.4 |     3.7 |          73.3
__*no of union ops needed*__| _9142_ | _3592_ | _2408_ | _66145_ 

__*Shapely*__ seems to perform in a rather stable manner in cases of high 
number of geometric unions (e.g maakond layer which has only a total of 15 
objects but is represented as 2073 separate tiles) even for objects with 
a high number of vertices (e.g the maakond layer which has approximately 66K
vertices per object on average). There is a 10fold time difference for a layer 
with a lot of objects (i.e a lot of loops) although these geometries are much
simpler-shaped (on average only 13 vertices per Polygon). Maybe more advanced
looping techniques like `map` would be of help here.

__*Turf*__ on the other hand seems to perform rather well on simple (as in 
_not excessively many vertices_) geometries, e.g katastriyksus where Turf's 
union accounts to approximately 35 seconds for 66K union operations. Still 
the processing time for layers with objects with relatively high number of
vertices is huge compared to shapely's performance (e.g maakond ~ 460 
seconds). 

One thing that was not measured in case of Turf was the time it would take 
to calculate the coordinates back to the whatever system you were using 
before. Although considering the time it takes to do the calculations one
way it should not really pose a threat doing it the other way aswell.
