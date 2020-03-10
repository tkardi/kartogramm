/* Z_MED_RAILWAYS */

truncate table vectiles.z_med_railways restart identity;

drop index if exists vectiles.sidx__z_med_railways;
drop index if exists vectiles.ghidx__z_med_railways;
drop table if exists vectiles_input.tmp_z_med_railways;

create table vectiles_input.tmp_z_med_railways as
select
    *
from
    vectiles.z_med_railways
where
    1=0
;

/* k250_roobastee */

insert into vectiles_input.tmp_z_med_railways (
    geom,
    originalid, name,
    type, subtype, class,
    tunnel, bridge
)
select
    st_subdivide(st_transform((st_dump(geom)).geom, 4326), 512) as geom,
    null as originalid, null as name,
    'rail'::vectiles.type_railways as type,
    'rail.large_gauge'::vectiles.subtype_railways as subtype,
    'main'::vectiles.class_railways,
    false as tunnel, false as bridge
from
    vectiles_input.k250_roobastee
;

insert into vectiles_input.tmp_z_med_railways (
    geom,
    originalid, name,
    type, subtype, class,
    tunnel, bridge
)
select
    st_subdivide(geom, 512),
    null as originalid, null as name,
    'rail'::vectiles.type_railways as type,
    case
        when category = 1 then 'rail.large_gauge'
        else 'rail.narrow_gauge'
    end::vectiles.subtype_railways as subtype,
    'main'::vectiles.class_railways as class,
    false as tunnel, false as bridge
from
    vectiles_input.lv_railways
where
    disp_scale in( '1:40m','1:20m','1:10m')
;


insert into vectiles.z_med_railways(
    geom, originalid, name,
    type, subtype, class,
    tunnel, bridge
)
select
    geom, originalid, name,
    type, subtype, class,
    tunnel, bridge
from
    vectiles_input.tmp_z_med_railways
order by
    st_geohash(st_envelope(geom), 10) collate "C"
;

create index ghidx__z_med_railways on
    vectiles.z_med_railways
        (st_geohash(st_envelope(geom),10))
;

cluster vectiles.z_med_railways using
    ghidx__z_med_railways
;

create index sidx__z_med_railways on
    vectiles.z_med_railways using
        gist (geom)
;

drop table if exists
    vectiles_input.tmp_z_med_railways
;
