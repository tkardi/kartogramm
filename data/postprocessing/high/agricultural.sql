/* AGRICULTURAL */

truncate table vectiles.agricultural restart identity;

/* insert e_303_haritav_maa_a */
insert into vectiles.agricultural (
    geom, originalid, name, type
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    etak_id, null as name,
    case
        when puis = 10 then 'arboriculture'
        else 'agriculture'
    end::vectiles.type_agricultural as type
from vectiles_input.e_303_haritav_maa_a
;

insert into vectiles.agricultural (
    geom, originalid, name, type
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    etak_id, null as name,
    'greenhouse'::vectiles.type_agricultural as type
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 10
;
