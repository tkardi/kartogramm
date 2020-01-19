# Kartogramm
_Kartogramm_ is a vector tiles scheme for serving data from the
[Estonian Land Board](https://www.maaamet.ee/en)'s 1:10K national topographic
vector dataset (ETAK). It incorporates some other data sources aswell, listed
[here](#Data-sources). The datasets are transformed to unified schema discussed
in more detail [here](#layers). The main focus is still on high level zooms for
Estonia, with additional sources only meant as background information on medium
and low levels.

The data model is based on [Cartiqo](https://github.com/webmapper/cartiqo-documentation) by
[Webmapper](https://www.webmapper.net/) licensed under
[CC BY-SA 4.0](https://github.com/webmapper/cartiqo-documentation/blob/master/LICENSE)
with some country-specific changes to codelists (wetlands, peat mining areas)
and other more general changes as regards to the availability of data. But
this here is still a work in progress so further changes might come about.


## Data sources
- [NaturalEarth](https://www.naturalearthdata.com/downloads/) v 4.1.0 large
scale cultural and physical under [terms of use](https://www.naturalearthdata.com/about/terms-of-use/).
- [OpenStreetMap](https://openstreetmap.org) data for Latvia via
[geofabrik.de](geofabrik.de) under [ODbL v 1.0](https://opendatacommons.org/licenses/odbl/1-0/index.html).
- 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554)
by [Estonian Land Board](https://www.maaamet.ee/en) under _Maa-ameti avatud ruumiandmete litsents, 01.09.2016_
(verbatim copy of the license incl. in the zip file).
- 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html)
under [Land Board Open Data License](https://geoportaal.maaamet.ee/docs/Avaandmed/Licence-of-open-data-of-Estonian-Land-Board.pdf).
- [Estonian administrative division](https://geoportaal.maaamet.ee/eng/Spatial-Data/Administrative-and-Settlement-Division-p312.html)
(EHAK) by [Estonian Land Board](https://www.maaamet.ee/en) under
[Land Board Open Data License](https://geoportaal.maaamet.ee/docs/Avaandmed/Licence-of-open-data-of-Estonian-Land-Board.pdf).
- 1:1.2M generalized Latvian administrative division (as of January 2018) by
[Statistics Latvia](https://www.csb.gov.lv/en/sakums) via
[Latvia Open Data Portal](https://data.gov.lv) via
[Open Data Portal Watch](https://data.wu.ac.at/schema/data_gov_lv/ZTNkNjA2ZjItNmQzOC00NDRkLWI3NjctMTE5ZmRjYzQzNWZl)
under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
- Unofficial urban districts for city of Tartu from the [city govt
open data page](https://www.tartu.ee/et/avaandmed) under
[CC-BY 3.0](https://creativecommons.org/licenses/by/3.0/).
- Unofficial urban districts for city of Tallinn from the [city geoportal](https://www.tallinn.ee/est/ehitus/Tallinna-linnaosade-ja-asumite-piirid)
under [Tallinn's open spatial data simple licence agreement](https://www.tallinn.ee/eng/geoportal/Licence-agreement).
- [Estonian address data](https://xgis.maaamet.ee/adsavalik/extracts) (ADS) by
[Estonian Land Board](https://www.maaamet.ee/en) under
[CC0](https://creativecommons.org/share-your-work/public-domain/cc0).


## Layers
### Agricultural
Areas used for agricultural purposes. ETAK does not specifically distinguish
between types of agricultural land. In order to achieve this would have to do
some extra processing based on data from the
[Agricultural Registers and Information Board](http://www.pria.ee/en/).
`type == greenhouse` requires separate attention as it is a _collateral_ area
taken from _other buildings_. This means it will overlap other types of landcover
areas.

#### enums

| type_agricultural |
|-------------------|
| agriculture       |
| arboriculture     |
| pasture           |
| greenhouse        |
| fallow            |

#### properties

| property name | datatype in DB    |
|---------------|-------------------|
| oid           | serial            |
| geom          | geometry(Polygon) |
| originalid    | varchar(50)       |
| name          | varchar(500)      |
| type          | type_agricultural |


### Boundaries
Boundaries between administrative units are represented as single `LineString`s
with sidedness information, i.e. the name of administrative unit and country
identifier on either side of the vector.

#### enums

| type_boundaries |
|-----------------|
| country         |
| province        |
| municipality    |
| settlement      |


| subtype_boundaries |
|--------------------|
| country.foreign    |
| country.domestic   |
| province.          |
| municipality.      |
| settlement.        |

#### properties

| property name | datatype in DB       |
|---------------|----------------------|
| oid           | serial               |
| geom          | geometry(LineString) |
| originalid    | varchar(50)          |
| name_left     | varchar(500)         |
| name_right    | varchar(500)         |
| country_left  | varchar(50)          |
| country_right | varchar(50)          |
| type          | type_boundaries      |
| subtype       | subtype_boundaries   |
| on_water      | boolean              |

### Builtup
Urban areas and buildings. Except for subtypes `area.industrial` and
`area.residential` all of these are _collateral_ meaning they can overlap other
landcover types, e.g. building polygons situated on top of residential area
polygons.

#### enums

| type_builtup    |
|-----------------|
| area            |
| building        |
| wall            |


| subtype_builtup             |
|-----------------------------|
| area.                       |
| area.courtyard              |
| area.industrial             |
| area.residential            |
| area.graveyard              |
| area.quarry                 |
| area.dump                   |
| area.sports                 |
| building.                   |
| building.industry           |
| building.main               |
| building.barn               |
| building.entrance           |
| building.waterbasin         |
| building.cover              |
| building.pitch              |
| building.berth              |
| building.under_construction |
| building.wreck              |
| building.foundation         |
| building.underground        |
| wall.                       |


#### properties

| property name | datatype in DB    |
|---------------|-------------------|
| oid           | serial            |
| geom          | geometry(Polygon) |
| originalid    | varchar(50)       |
| name          | varchar(500)      |
| type          | type_builtup      |
| subtype       | subtype_builtup   |

### Infrastructure
Infrastructure areas, such as road surfaces, bridges and tunnels.

#### enums

| type_infrastructure |
|---------------------|
| parking             |
| road                |
| railway             |
| jetty               |
| tunnel              |
| bridge              |
| runway              |
| pavement            |


| subtype_infrastructure |
|------------------------|
| parking.               |
| road.motorway          |
| road.transit           |
| road.bike              |
| road.driveway          |
| road.bridle_way        |
| road.crossing          |
| road.secondary         |
| road.highway           |
| road.local             |
| road.path              |
| railway.track_surface  |
| railway.platform       |
| jetty.                 |
| tunnel.                |
| bridge.                |
| runway.                |
| pavement.              |


#### properties

| property name | datatype in DB         |
|---------------|------------------------|
| oid           | serial                 |
| geom          | geometry(Polygon)      |
| originalid    | varchar(50)            |
| name          | varchar(500)           |
| type          | type_infrastructure    |
| subtype       | subtype_infrastructure |


### Labels
Point locations for displaying text labels. Has a `hierarchy` property which
can be used to filter between _more important_ and _less important_ labels, e.g.
city names for different zoom levels. And `rotation` for rotating address
labels _feet downwards_ so their base can be shown on a styled map towards the
street they're associated with.

#### enums

| type_labels         |
|---------------------|
| place               |
| admin               |
| water               |
| nature              |
| address             |


| subtype_labels           |
|--------------------------|
| place.urban_district     |
| place.settlement         |
| admin.country.foreign    |
| admin.country.domestic   |
| admin.province           |
| admin.municipality       |
| admin.settlement         |
| admin.district           |
| admin.neighborhood       |
| address.building         |
| address.parcel           |
| water.                   |
| nature.                  |

#### properties

| property name | datatype in DB         |
|---------------|------------------------|
| oid           | serial                 |
| geom          | geometry(Point)        |
| originalid    | varchar(50)            |
| name          | varchar(500)           |
| type          | type_labels            |
| subtype       | subtype_labels         |
| hierarchy     | int                    |
| rotation      | numeric                |

### Natural
Areas of natural vegetation divided into 3 types - `high` (treecover), `low` (
grass, shrubs, marshes) and `bare` (no significant vegetation present or
bare ground).

#### enums

| type_natural        |
|---------------------|
| high                |
| low                 |
| bare                |


| subtype_natural          |
|--------------------------|
| high.mixed               |
| high.deciduous           |
| high.coniferous          |
| low.heath                |
| low.grass                |
| low.shrubs               |
| low.wet                  |
| bare.sand                |
| bare.rock                |
| bare.dune                |
| bare.wet                 |
| bare.peat                |

#### properties

| property name | datatype in DB         |
|---------------|------------------------|
| oid           | serial                 |
| geom          | geometry(Polygon)      |
| originalid    | varchar(50)            |
| name          | varchar(500)           |
| type          | type_natural           |
| subtype       | subtype_natural        |


### Railways
LineString features for railroad tracks. In addition to `type` and `subtype`
has also `class` which defines if this is a `main`, `side` or `branch` rail
line.

#### enums

| type_railways        |
|----------------------|
| rail                 |
| tram                 |
| metro                |
| industrial           |
| touristic            |
| light_rail           |


| subtype_railways     |
|----------------------|
| rail.large_gauge     |
| rail.narrow_gauge    |
| rail.funicular       |
| rail.other           |
| tram.                |
| metro.               |
| industrial.          |
| touristic.           |
| light_rail.          |


| class_railways       |
|----------------------|
| main                 |
| side                 |
| branch               |

#### properties

| property name | datatype in DB         |
|---------------|------------------------|
| oid           | serial                 |
| geom          | geometry(LineString)   |
| originalid    | varchar(50)            |
| name          | varchar(500)           |
| type          | type_railways          |
| subtype       | subtype_railways       |
| class         | class_railways         |
| tunnel        | boolean                |
| bridge        | boolean                |


### Roads
Roads as linestrings. `type` encodes the functional class, and in addition
`class` represents the kind of cover for the road. Z-levels in
`relative_height` are recalculated from the original data _z-at-the-beginning_,
_z-at-the-end_ of vector to _z-for-linestring_. `relative_height` is encoded
as
- `-1` - road passes under another road (at z-level `0`),
- `0` - road on the same (usually ground) level
- `1` - road passes over another road (at z-level `0`)

`bridge` and `tunnel` are booleans meant to denote if this section of the road
passes over a bridge or goes through a tunnel.

Boolean `oneway` denotes if this section of the road is meant for oneway car
traffic only. `True` means traffic only in the road vector direction, `False`
that traffic is allowed in both directions.

#### enums

| type_roads           |
|----------------------|
| highway              |
| motorway             |
| main                 |
| secondary            |
| local                |
| bike                 |
| path                 |
| ferry                |


| class_roads          |
|----------------------|
| stone                |
| gravel               |
| dirt                 |
| wood                 |
| permanent            |
| other                |

#### properties

| property name   | datatype in DB         |
|-----------------|------------------------|
| oid             | serial                 |
| geom            | geometry(LineString)   |
| originalid      | varchar(50)            |
| name            | varchar(500)           |
| type            | type_roads             |
| class           | class_roads            |
| tunnel          | boolean                |
| bridge          | boolean                |
| oneway          | boolean                |
| road_number     | varchar(250)           |
| relative_height | int                    |

### Water
Areas under water as polygons. Includes `sea`, `lake` for standing water as well
as `water_way` for larger rivers which are mapped as polygons at 1:10K.

#### enums

| type_water           |
|----------------------|
| sea                  |
| tidal_flat           |
| lake                 |
| water_way            |

#### properties

| property name   | datatype in DB         |
|-----------------|------------------------|
| oid             | serial                 |
| geom            | geometry(Polygon)      |
| originalid      | varchar(50)            |
| name            | varchar(500)           |
| type            | type_water             |


### Waterline
Different types of flow water bodies as linestrings. `type` denotes a recoded
waterline length. `class` for the official classification of the flowing
water body.

#### enums

| type_waterline       |
|----------------------|
| 1m                   |
| 3m                   |
| 6m                   |
| 8m                   |
| 12m                  |
| 50m                  |
| 125m                 |


| class_waterline      |
|----------------------|
| river                |
| channel              |
| stream               |
| ditch                |
| mainditch            |

#### properties

| property name   | datatype in DB         |
|-----------------|------------------------|
| oid             | serial                 |
| geom            | geometry(LineString)   |
| originalid      | varchar(50)            |
| name            | varchar(500)           |
| type            | type_waterline         |
| class           | class_waterline        |
| underground     | boolean                |

## Composition
### Low-level zooms
Low level zooms are defined as zooms 0-5 (_incl_).

| Layer      | Data sources |
|------------|--------------|
| waterline  | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [OpenStreetMap](https://openstreetmap.org) (LV) |
| water      | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [OpenStreetMap](https://openstreetmap.org) (LV), [NaturalEarth](https://www.naturalearthdata.com/downloads/) oceans |
| railways   | [NaturalEarth](https://www.naturalearthdata.com/downloads/) railroads |
| roads      |  1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [OpenStreetMap](https://openstreetmap.org) (LV) |
| builtup    | [NaturalEarth](https://www.naturalearthdata.com/downloads/) urban areas |
| boundaries | [NaturalEarth](https://www.naturalearthdata.com/downloads/) admin0 boundary lines |
| labels     | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554), [OpenStreetMap](https://openstreetmap.org), [NaturalEarth](https://www.naturalearthdata.com/downloads/) |

### Med-level zooms
Medium level zooms are defined as zooms 6-10 (_incl_).

| Layer      | Data sources |
|------------|--------------|
| waterline  | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [OpenStreetMap](https://openstreetmap.org) (LV) |
| water      | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [OpenStreetMap](https://openstreetmap.org) (LV), [NaturalEarth](https://www.naturalearthdata.com/downloads/) oceans |
| railways   | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [NaturalEarth](https://www.naturalearthdata.com/downloads/) railroads (LV) |
| roads      | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [OpenStreetMap](https://openstreetmap.org) (LV) |
| builtup    | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [OpenStreetMap](https://openstreetmap.org) (LV)
| boundaries | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554), [Estonian administrative division](https://geoportaal.maaamet.ee/eng/Spatial-Data/Administrative-and-Settlement-Division-p312.html), 1:1.2M generalized Latvian administrative division |
| natural    | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [OpenStreetMap](https://openstreetmap.org) (LV) |
| labels     | 1:250K [Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554) (EE), [Estonian address data](https://xgis.maaamet.ee/adsavalik/extracts) (EE), [OpenStreetMap](https://openstreetmap.org) (LV), 1:1.2M generalized Latvian administrative division (LV) |

### High-level zooms
High level zooms are defined as zooms 11+. The following table lists available
layers and their respective source data for these zooms

| Layer          | Data sources |
|----------------|--------------|
| waterline      | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html) |
| water          | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html), [NaturalEarth](https://www.naturalearthdata.com/downloads/) oceans |
| railways       | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html) |
| roads          | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html) |
| builtup        | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html) |
| boundaries     | [Estonian administrative division](https://geoportaal.maaamet.ee/eng/Spatial-Data/Administrative-and-Settlement-Division-p312.html), 1:1.2M generalized Latvian administrative division |
| infrastructure | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html) |
| natural        | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html) |
| agricultural   | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html) |
| labels         | 1:10K [Estonian Topographic Database](https://geoportaal.maaamet.ee/eng/Spatial-Data/Estonian-Topographic-Database-p305.html), [Estonian address data](https://xgis.maaamet.ee/adsavalik/extracts) (from zooms 14+), Unofficial urban districts for city of Tartu, Unofficial urban districts for city of Tallinn |

## License
This database schema is released under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
