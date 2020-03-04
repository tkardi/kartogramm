/* Z_LOW_RAILWAYS */

truncate table vectiles.z_low_railways restart identity;

insert into vectiles.z_low_railways (
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
from vectiles_input.ne_10m_railroads
where disp_scale in( '1:40m','1:20m','1:10m')
;
