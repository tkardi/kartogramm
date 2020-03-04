/* INFRASTRUCTURE */

truncate table vectiles.infrastructure restart identity;

/* insert e_501_tee_a */

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    etak_id, null as name,
    case
        when tyyp = 10 then 'road'
        when tyyp = 20 then 'parking'
        when tyyp = 30 then 'pavement'
        when tyyp = 40 then 'runway'
        when tyyp = 50 then 'pavement'
        when tyyp = 60 then 'pavement'
        when tyyp = 997 then 'pavement'
        when tyyp = 999 then 'pavement'
    end::vectiles.type_infrastructure as type,
    case
        when tyyp = 10 then 'road.motorway'
        when tyyp = 20 then 'parking.'
        when tyyp = 30 then 'pavement.'
        when tyyp = 40 then 'runway.'
        when tyyp = 50 then 'pavement.'
        when tyyp = 60 then 'pavement.'
        when tyyp = 997 then 'pavement.'
        when tyyp = 999 then 'pavement.'
    end::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_501_tee_a
;




insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom,
    etak_id, nullif(nimetus, ''),
    case
        when tyyp = 60 then 'tunnel'
        when tyyp = 30 then 'bridge'
    end::vectiles.type_infrastructure as type,
    case
        when tyyp = 60 then 'tunnel.'
        when tyyp = 30 then 'bridge.'
    end::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_505_liikluskorralduslik_rajatis_ka --OK. Kuid probleem siin: sildade puhul on meil vaja z-levelit tegelt, hetkel suht kasutud, sest me ei tea, kuhu seda joonistada.
;

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, etak_id, null,
    'parking'::vectiles.type_infrastructure as type,
    'parking.'::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused)=any(array['parkla', 'parkimismaja'])
;

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, etak_id, null,
    'railway'::vectiles.type_infrastructure as type,
    'railway.platform'::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused)=any(array['perroon'])
;

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, etak_id, null,
    'jetty'::vectiles.type_infrastructure as type,
    'jetty.'::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused)=any(array['paadisild'])
;

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, etak_id, null,
    'runway'::vectiles.type_infrastructure as type,
    'runway.'::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_301_muu_kolvik_ka
where tyyp = (40)
;
