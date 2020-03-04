/* Z_LOW_WATER */

truncate table vectiles.z_low_water restart identity;

insert into vectiles.z_low_water(
    geom, originalid, name, type
)
select
    st_transform((st_dump(st_union(ring))).geom, 4326) as geom, null as originalid, name, type
from (
    select
        (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 1000))).geom as ring,
        nimetus as name,
        case
            when tyyp = 'Seisuveekogu' then 'lake'
            when tyyp = 'Vooluveekogu' then 'water_way'
        end::vectiles.type_water as type
    from vectiles_input.k250_kolvik
    where
        tyyp = any(array['Vooluveekogu', 'Seisuveekogu']) and
        nullif(nimetus, 'nimetu') is not null
) foo
where
    st_area(foo.ring) > 10000000
group by
    name, type
;

insert into vectiles.z_low_water(
    geom, originalid, name, type
)
select
    (st_dump(st_union(ring))).geom as geom, null as originalid, name, type
from (
    select
        (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 0.00001))).geom as ring,
        name,
        'lake'::vectiles.type_water as type
    from
        vectiles_input.lv_water
    where
        fclass in ('reservoir','water') and
        name like '%ezers'
) foo
where
    st_area(foo.ring, true) > 10000000
group by
    name, type
;

insert into vectiles.z_low_water(
    geom, originalid, name, type
)
select
    (st_dump(st_buildarea(st_collect(ring)))).geom as geom, null as originalid, name, type
from (
    select
        oid, (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 0.00001))).geom as ring,
        null as etak_id, null as name,
        'sea'::vectiles.type_water as type
    from
        vectiles_input.oceans
) foo
where
    st_area(foo.ring, true) > 10000000
group by
    oid, name, type
;

insert into vectiles.z_low_water(
    geom, originalid, name, type
)
select
    (st_dump(geom)).geom, null as originalid, name,
    'lake'::vectiles.type_water as type
from
    vectiles_input.ne_10m_lakes
where
    st_area(geom, true)> 1000000 and
    name not in ('Lake Peipus', 'Võrtsjärv', 'Pskoyskoye Ozero')
union all
select
    (st_dump(geom)).geom, null as originalid, name,
    'lake'::vectiles.type_water as type
from
    vectiles_input.ne_10m_lakes_europe
where
    st_area(geom, true)> 100000 and
    name not in ('Lake Peipus', 'Võrtsjärv', 'Pskoyskoye Ozero', 'Lake Usma', 'Engure', 'Babīte Ezers', 'Pljavinjas')
;
