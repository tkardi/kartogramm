/* Z_MED_NATURAL */

truncate table vectiles.z_med_natural restart identity;

insert into vectiles.z_med_natural (
    geom, originalid, name, type, subtype
)
select
    st_transform(st_simplifypreservetopology((st_dump(st_makevalid(geom))).geom, 0.00001), 4326), null as originalid, null as name,
    case
        when tyyp = 'Lage ala' then 'low'
        when tyyp = 'Märgala' then 'bare'
        when tyyp = 'Mets ja põõsastik' then 'high'
    end::vectiles.type_natural as type,
    case
        when tyyp = 'Lage ala' then 'low.grass'
        when tyyp = 'Märgala' then 'bare.wet'
        when tyyp = 'Mets ja põõsastik' then 'high.mixed'
    end::vectiles.subtype_natural as subtype
from
    vectiles_input.k250_kolvik
where
    tyyp = any(array['Lage ala', 'Märgala', 'Mets ja põõsastik'])
;
