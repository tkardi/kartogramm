/* BUILTUP */

truncate table vectiles.builtup restart identity;

/* insert e_302_ou_a */

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    etak_id, null as name,
    'area'::vectiles.type_builtup,
    case
        when tyyp = 10 then 'area.residential'
        when tyyp = 20 then 'area.industrial'
    end::vectiles.subtype_builtup as subtype
from vectiles_input.e_302_ou_a
;

/* insert e_401_hoone_ka*/
insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom), 0.1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    case
        when tyyp = 10 then 'building.main'
        when tyyp = 20 then 'building.barn'
        when tyyp = 30 then 'building.foundation'
        when tyyp = 40 then 'building.wreck'
        when tyyp = 50 then 'building.under_construction'
    end::vectiles.subtype_builtup as subtype
from vectiles_input.e_401_hoone_ka
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    'building.cover'::vectiles.subtype_builtup as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 20 -- Katusealune
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    'building.berth'::vectiles.subtype_builtup as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused) = any(array['sadamakai'])
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    'building.'::vectiles.subtype_builtup as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused) != all(array['paadisild', 'sadamakai', 'perroon', 'parkla', 'parkimismaja'])
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    'building.underground'::vectiles.subtype_builtup as subtype
from vectiles_input.e_404_maaalune_hoone_ka
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    case
        when tyyp = 30 then 'area'
        when tyyp = 50 then 'building'
        when tyyp = 60 then 'area'
        when tyyp = 90 then 'area'
        when tyyp = 100 then 'area'
    end::vectiles.type_builtup as type,
    case
        when tyyp = 30 then 'area.graveyard'
        when tyyp = 50 then 'building.berth'
        when tyyp = 60 then 'area.sports'
        when tyyp = 90 then 'area.dump'
        when tyyp = 100 then 'area.quarry'
    end::vectiles.subtype_builtup as subtype
from vectiles_input.e_301_muu_kolvik_ka
where tyyp not in (40)
;
