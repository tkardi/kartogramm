/* Z_MED_ROADS */

truncate table vectiles.z_med_roads restart identity;

drop index if exists vectiles.sidx__z_med_roads;
drop index if exists vectiles.ghidx__z_med_roads;
drop table if exists vectiles_input.tmp_z_med_roads;

create table vectiles_input.tmp_z_med_roads as
select
    *
from
    vectiles.z_med_roads
where
    1=0
;

/* k250_tee */
insert into vectiles_input.tmp_z_med_roads (
    geom,
    originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    st_subdivide(st_transform((st_dump(geom)).geom, 4326), 512) as geom,
    null as originalid, nimetus,
    case
        when tyyp = 'Põhimaantee' then 'highway' --põhimaantee
        when tyyp = 'Tugimaantee' then 'main'  --tugimaantee
        when tyyp = 'Kõrvalmaantee' then 'secondary' -- kõrvalmaantee,
        when tyyp = 'Ramp või ühendustee' then 'secondary' --ramp või ühendustee
        when tyyp = 'Tänav' then 'local' --tänav,
        when tyyp = 'Muu tee' then 'local' --muu tee
    end::vectiles.type_roads as type,
    'permanent'::vectiles.class_roads as class, false as tunnel, false as bridge,
    false as oneway, tee_nr as road_number, 0 as relative_height
from
    vectiles_input.k250_tee
;


insert into vectiles_input.tmp_z_med_roads (
    geom,
    originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    st_subdivide(
        case
            when oneway='T' then st_reverse(geom)
            else geom
        end,
        512
    ) as geom,
    null as originalid, name,
    case
        when fclass = any(array['trunk', 'trunk_link']) then 'highway'
        when fclass = any(array['primary', 'primary_link']) then 'main'
        when fclass = any(array['secondary', 'secondary_link']) then 'secondary'
        when fclass = any(array['tertiary', 'tertiary_link']) then 'local'
    end::vectiles.type_roads as type,
    'permanent'::vectiles.class_roads as class,
    case
        when tunnel = 'F' then false
        else true
    end as tunnel,
    case
        when bridge = 'F' then false
        else true
    end as bridge,
    case
        when oneway=any(array['T','F']) then true
        else false
    end as oneway,
    ref as road_number, 0 as relative_height
from
    vectiles_input.lv_roads
where
    fclass = any(
        array['primary','secondary','trunk','primary_link',
            'secondary_link','tertiary','tertiary_link','trunk_link']
    )
;


insert into vectiles.z_med_roads(
    geom, originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    geom, originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
from
    vectiles_input.tmp_z_med_roads
order by
    st_geohash(st_envelope(geom), 10) collate "C"
;

create index ghidx__z_med_roads on
    vectiles.z_med_roads
        (st_geohash(st_envelope(geom),10))
;

cluster vectiles.z_med_roads using
    ghidx__z_med_roads
;

create index sidx__z_med_roads on
    vectiles.z_med_roads using
        gist (geom)
;

drop table if exists
    vectiles_input.tmp_z_med_roads
;
