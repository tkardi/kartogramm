/* Z_LOW_ROADS */

truncate table vectiles.z_low_roads restart identity;

/* k250_tee */
insert into vectiles.z_low_roads (
    geom, originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    st_transform((st_dump(st_linemerge(st_collect(st_simplifypreservetopology(geom, 100000))))).geom, 4326) as geom, null as originalid, nimetus,
    'highway'::vectiles.type_roads as type,
    'permanent'::vectiles.class_roads as class, false as tunnel, false as bridge,
    false as oneway, tee_nr as road_number, 0 as relative_height
from vectiles_input.k250_tee
where tyyp = 'Põhimaantee'
group by nimetus, tee_nr, tyyp
;

/* OSM roads from lv_roads */
insert into vectiles.z_low_roads (
    geom, originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    (st_dump(st_linemerge(st_collect(st_simplifypreservetopology(geom, 0.00001))))).geom as geom, null as originalid, name,
    'highway'::vectiles.type_roads as type,
    'permanent'::vectiles.class_roads as class, false as tunnel, false as bridge,
    false as oneway, ref as road_number, 0 as relative_height
from vectiles_input.lv_roads
where fclass = 'trunk'
group by name, ref, fclass
;
