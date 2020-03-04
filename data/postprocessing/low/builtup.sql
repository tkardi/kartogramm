/* Z_LOW_BUILTUP */

truncate table vectiles.z_low_builtup restart identity;

insert into vectiles.z_low_builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(geom)).geom, null as originalid, null as name,
    'area'::vectiles.type_builtup as type,
    'area.'::vectiles.subtype_builtup as subtype
from
    vectiles_input.ne_10m_urban_areas
where
    st_area(geom, true)> 10000
;
