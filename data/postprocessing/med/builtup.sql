/* Z_MED_BUILTUP */

truncate table vectiles.z_med_builtup restart identity;

drop index if exists vectiles.sidx__z_med_builtup;
drop index if exists vectiles.ghidx__z_med_builtup;
drop table if exists vectiles_input.tmp_z_med_builtup;

create table vectiles_input.tmp_z_med_builtup as
select
    *
from
    vectiles.z_med_builtup
where
    1=0
;

insert into vectiles.z_med_builtup (
    geom,
    originalid, name, type, subtype
)
select
    st_subdivide(st_transform(st_simplifypreservetopology((st_dump(st_makevalid(geom))).geom, 0.00001), 4326), 256) as geom,
    null as originalid, nimetus as name,
    'area'::vectiles.type_builtup as type,
    'area.'::vectiles.subtype_builtup as subtype
from
    vectiles_input.k250_kolvik
where
    tyyp = 'Asustus'
;

insert into vectiles.z_med_builtup (
    geom,
    originalid, name, type, subtype
)
select
    st_subdivide(st_simplifypreservetopology((st_dump(st_union(geom))).geom, 0.00001), 256) as geom,
    null as originalid, null as name, type, subtype
from (
    select
        geom as geom,
        'area'::vectiles.type_builtup as type,
        'area.'::vectiles.subtype_builtup as subtype
    from
        vectiles_input.lv_landuse
    where
        fclass = any(array['cemetary', 'commercial', 'industrial', 'quarry', 'recreation_ground', 'residential', 'retail'])
) foo
group by
    type, subtype
;

insert into vectiles.z_med_builtup(
    geom, originalid, name, type, subtype
)
select
    geom, originalid, name, type, subtype
from
    vectiles_input.tmp_z_med_builtup
order by
    st_geohash(st_envelope(geom), 10) collate "C"
;

create index ghidx__z_med_builtup on
    vectiles.z_med_builtup
        (st_geohash(st_envelope(geom), 10))
;

cluster vectiles.z_med_builtup using
    ghidx__z_med_builtup
;

create index sidx__z_med_builtup on
    vectiles.z_med_builtup using
        gist (geom)
;

drop table if exists
    vectiles_input.tmp_z_med_builtup
;
