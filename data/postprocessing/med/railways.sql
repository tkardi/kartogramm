/* Z_MED_RAILWAYS */

truncate table vectiles.z_med_railways restart identity;

/* k250_roobastee */

insert into vectiles.z_med_railways (
    geom, originalid, name,
    type, subtype, class,
    tunnel, bridge
)
select
    st_transform((st_dump(geom)).geom, 4326) as geom, null as originalid, null as name,
    'rail'::vectiles.type_railways as type,
    'rail.large_gauge'::vectiles.subtype_railways as subtype,
    'main'::vectiles.class_railways,
    false as tunnel, false as bridge
from
    vectiles_input.k250_roobastee
;

insert into vectiles.z_med_railways (
    geom, originalid, name,
    type, subtype, class,
    tunnel, bridge
)
select
    geom, null as originalid, null as name,
    'rail'::vectiles.type_railways as type,
    case
        when category = 1 then 'rail.large_gauge'
        else 'rail.narrow_gauge'
    end::vectiles.subtype_railways as subtype,
    'main'::vectiles.class_railways as class,
    false as tunnel, false as bridge
from vectiles_input.lv_railways
where disp_scale in( '1:40m','1:20m','1:10m')
;
