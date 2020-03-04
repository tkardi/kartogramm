/* Z_MED_BUILTUP */

truncate table vectiles.z_med_builtup restart identity;

insert into vectiles.z_med_builtup (
    geom,
    originalid, name, type, subtype
)
select
    st_transform(st_simplifypreservetopology((st_dump(st_makevalid(geom))).geom, 0.00001), 4326) as geom,
    null as originalid, nimetus as name,
    'area'::vectiles.type_builtup as type,
    'area.'::vectiles.subtype_builtup as subtype
from
    vectiles_input.k250_kolvik
where
    tyyp = 'Asustus'
;

insert into vectiles.z_med_builtup (
    geom, originalid, name, type, subtype
)
select
    st_simplifypreservetopology((st_dump(st_union(geom))).geom, 0.00001) as geom,
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
