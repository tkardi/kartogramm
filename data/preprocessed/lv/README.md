## lv_landuse
Is an excerpt of LV landuse features from the
[geofabrik.de LV download](http://download.geofabrik.de/europe/latvia.html)
page.

The layer is composed by
```
select
    distinct on (osm_id, geom)
    *
from (
    select
        osm_id, code, fclass, name, (st_dump(geom)).geom as geom
    from
        landuse
    where
        fclass = any(
            array[
                'cemetary', 'commercial', 'industrial', 'quarry',
                'recreation_ground', 'residential', 'retail'
            ]
        )
) f
```

This layer is downloadable from
[https://tkardi.ee/kartogramm/data/lv/lv_landuse.json](https://tkardi.ee/kartogramm/data/lv/lv_landuse.json)
and shared under the [Open Database License (ODbL) v1.0](https://opendatacommons.org/licenses/odbl/1.0/)
as required by [OpenStreetMap](https://www.openstreetmap.org/copyright).


## lv_roads
Is an excerpt of LV roads features from the
[geofabrik.de LV download](http://download.geofabrik.de/europe/latvia.html)
page.

The layer is composed by
```
select
    distinct on (osm_id, geom)
    *
from (
    select
        osm_id, code, fclass, name, ref, oneway, bridge, tunnel, geom
    from
        roads
    where
        fclass = any(
            array[
                'primary','secondary','trunk','primary_link','secondary_link',
                'tertiary','tertiary_link','trunk_link'
            ]
        )
) f
```

Further the layer is hand-edited so features from this layer and roads from
[Estonian Land Board](https://maaamet.ee)'s [Topographic Database](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=618)
road features in `E_501_tee_j` would be snapped and not duplicate each other.

This layer is downloadable from
[https://tkardi.ee/kartogramm/data/lv/lv_roads.json](https://tkardi.ee/kartogramm/data/lv/lv_roads.json)
and shared under the [Open Database License (ODbL) v1.0](https://opendatacommons.org/licenses/odbl/1.0/)
as required by [OpenStreetMap](https://www.openstreetmap.org/copyright).


## lv_waterline
Is an excerpt of LV waterways features from the
[geofabrik.de LV download](http://download.geofabrik.de/europe/latvia.html)
page.

The layer is composed by
```
select
    distinct on (osm_id, geom)
    *
from (
    select
        osm_id, code, fclass, width, name, (st_dump(geom)).geom
    from
        waterways
    where
        fclass != 'drain';
) f
```

This layer is downloadable from
[https://tkardi.ee/kartogramm/data/lv/lv_waterline.json](https://tkardi.ee/kartogramm/data/lv/lv_waterline.json)
and shared under the [Open Database License (ODbL) v1.0](https://opendatacommons.org/licenses/odbl/1.0/)
as required by [OpenStreetMap](https://www.openstreetmap.org/copyright).


## lv_water
Is an excerpt of LV water areas features from the
[geofabrik.de LV download](http://download.geofabrik.de/europe/latvia.html)
page.

The layer is composed by
```
select
    distinct on (osm_id, geom)
    *
from (
    select
        osm_id, code, fclass, name, (st_dump(geom)).geom
    from
        water
) f
```

This layer is downloadable from
[https://tkardi.ee/kartogramm/data/lv/lv_water.json](https://tkardi.ee/kartogramm/data/lv/lv_water.json)
and shared under the [Open Database License (ODbL) v1.0](https://opendatacommons.org/licenses/odbl/1.0/)
as required by [OpenStreetMap](https://www.openstreetmap.org/copyright).


## lv_railways
Is an excerpt of NaturalEarth ne_10m_railroads layer from
[NaturalEarth](https://www.naturalearthdata.com/downloads/)
page.

The layer is composed by
```
select
    *
from (
    select
        category, disp_scale, (st_dump(geom)).geom
    from
        ne_10m_railroads, latvia
    where
        st_intersects(ne_10m_railroads.geom, latvia.geom)
) f
```

And then hand-modified to snap and remove overlaps with railroads from
[Estonian Land Board](https://maaamet.ee)'s [Topographic Database](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=618)
in `E_502_roobastee_j`.

This layer is downloadable from
[https://tkardi.ee/kartogramm/data/lv/lv_railwayss.json](https://tkardi.ee/kartogramm/data/lv/lv_railways.json)
and shared under the [NaturalEarth terms and conditions](https://www.naturalearthdata.com/about/terms-of-use/)
