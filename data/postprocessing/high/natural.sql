/* NATURAL */

truncate table vectiles.natural restart identity;
/* insert  e_305_puittaimestik_a */
insert into vectiles.natural (
    geom, type, subtype
)
select st_subdivide((st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, 512) as geom,
    case
        when tyyp = 10 then 'high'
        else 'low'
    end::vectiles.type_natural as type,
    case
        when tyyp = 10 then 'high.mixed'
        else 'low.shrubs'
    end::vectiles.subtype_natural as subtype
from vectiles_input.e_305_puittaimestik_a
;

/* insert  e_304_lage_a */
insert into vectiles.natural (
    geom, originalid, name, type, subtype
)
select st_subdivide((st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, 512) as geom, etak_id, null as name,
    case
        when tyyp = 10 then 'low'
        when tyyp = 20 then 'bare'
        when tyyp = 30 then 'low'
        when tyyp = 40 then 'bare'
    end::vectiles.type_natural as type,
    case
        when tyyp = 10 then 'low.grass'
        when tyyp = 20 then 'bare.sand'
        when tyyp = 30 then 'low.grass' -- or bare.rock?
        when tyyp = 40 then 'bare.rock'
    end::vectiles.subtype_natural as subtype
from vectiles_input.e_304_lage_a
;

/* insert e_306_margala_a */

insert into vectiles.natural (
    geom, originalid, name, type, subtype
)
select st_subdivide((st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, 512) as geom, etak_id, null as name,
    case
        when tyyp in (10,20,30,40) and puis = 10 then 'low'
        else 'bare'
    end::vectiles.type_natural as type,
    case
        when tyyp in (10,20,30,40) and puis = 10 then 'low.wet'
        else 'bare.wet'
    end::vectiles.subtype_natural as subtype
from vectiles_input.e_306_margala_a
;


/* insert e_307_turbavali_a */
insert into vectiles.natural (
    geom, originalid, name, type, subtype
)
select
    st_subdivide((st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, 512) as geom, etak_id, null as name,
   'bare'::vectiles.type_natural as type,
   'bare.peat'::vectiles.subtype_natural as subtype
from vectiles_input.e_307_turbavali_a
;

/* insert e_301_muu_kolvik_a */
insert into vectiles.natural (
    geom, originalid, name, type, subtype
)
select
    st_subdivide((st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, 512) as geom, etak_id, null as name,
   'low'::vectiles.type_natural as type,
   'low.grass'::vectiles.subtype_natural as subtype
from vectiles_input.e_301_muu_kolvik_a
;
