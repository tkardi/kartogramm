/* Z_MED_WATER */

truncate table vectiles.z_med_water restart identity;

drop index if exists vectiles.sidx__z_med_water;
drop index if exists vectiles.ghidx__z_med_water;
drop table if exists vectiles_input.tmp_z_med_water;

create table vectiles_input.tmp_z_med_water as
select
    *
from
    vectiles.z_med_water
where
    1=0
;

insert into vectiles_input.tmp_z_med_water(
    geom,
    originalid, name,
    type
)
select
    st_subdivide((st_dump((geom))).geom, 512) as geom,
    null as etak_id, null as name,
    'sea'::vectiles.type_water
from vectiles_input.oceans
;

insert into vectiles_input.tmp_z_med_water(
    geom,
    originalid, name,
    type
)
select
    st_subdivide((st_dump(st_transform(geom,4326))).geom, 512) as geom,
    null as etak_id, null as name,
    'sea'::vectiles.type_water
from vectiles_input.sea
;

insert into vectiles_input.tmp_z_med_water(
    geom,
    originalid,
    name, type
)
select
    st_subdivide(st_transform((st_dump((geom))).geom, 4326), 512) as geom,
    null as etak_id, nimetus as name,
    case
        when tyyp = 'Seisuveekogu' then 'lake'
        when tyyp = 'Vooluveekogu' then 'water_way'
    end::vectiles.type_water as type
from
    vectiles_input.k250_kolvik
where
    tyyp = any(array['Vooluveekogu', 'Seisuveekogu'])
;


insert into vectiles_input.tmp_z_med_water(
    geom,
    originalid,
    name, type
)
select
    st_subdivide((st_dump(st_union(ring))).geom, 512) as geom,
    null as originalid,
    name, type
from
    (
        select
            (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 0.00001))).geom as ring,
            name,
            'lake'::vectiles.type_water as type
        from
            vectiles_input.lv_water
        where
            fclass in ('reservoir', 'water') and
            (lower((string_to_array(name, ' / '))[1]) like '%ezers' or lower((string_to_array(name, ' / '))[1]) like 'ez. %')
    ) foo
where
    st_area(foo.ring, true) > 250000
group by
    name, type
;


insert into vectiles_input.tmp_z_med_water(
    geom,
    originalid,
    name, type
)
select
    st_subdivide((st_dump(st_union(st_buffer(ring, 0.00005)))).geom, 512) as geom,
    null as originalid,
    name, type
from (
    select
        w.oid, foo.oids,
        (st_dumprings(
            st_simplifypreservetopology(
                (st_dump(st_union(array[foo.geom, coalesce(w.geom, foo.geom)]))).geom,
                0.00001
            )
        )).geom as ring,
        foo.name as name,
        case
            when foo.name = any(
                array['Gauja', 'Daugava', 'Ogre', 'Venta', 'Iecava', 'Pededze',
                    'Abava', 'Lielupe', 'Rēzekne', 'Mēmele', 'Aiviekste',
                    'Bērze', 'Dubna' ]
            ) then 'water_way'
            else 'lake'
        end::vectiles.type_water as type
    from (
        select
            array_agg(oid) as oids, (string_to_array(name, ' / '))[1] as name, st_union(geom) as geom
        from
            vectiles_input.lv_water
        where
            (
                (
                    "fclass" not in ('wetland', 'river') and
                    st_area(geom, true) > 250000 and
                    lower((string_to_array(coalesce(name, 'a'), ' / '))[1]) not like '%ezers' and
                    lower((string_to_array(coalesce(name, 'a'), ' / '))[1]) not like 'ez. %'
                ) or
                    (string_to_array(name, ' / '))[1] = any(
                        array['Gauja', 'Daugava', 'Ogre', 'Venta', 'Iecava', 'Pededze',
                            'Abava', 'Lielupe', 'Rēzekne', 'Mēmele', 'Aiviekste',
                            'Bērze', 'Dubna' ]
                    )
            ) and
            name is not null
        group by
            (string_to_array(name, ' / '))[1]
    ) foo
        left join vectiles_input.lv_water w on
            st_intersects(w.geom, foo.geom) and
            w.name is null and
            w.oid != all(foo.oids) and
            w.fclass not in ('wetland')
) f
group by
    name, type
;


insert into vectiles.z_med_water(
    geom, originalid, name, type
)
select
    geom, originalid, name, type
from
    vectiles_input.tmp_z_med_water
order by
    st_geohash(st_envelope(geom), 10) collate "C"
;

create index ghidx__z_med_water on
    vectiles.z_med_water
        (st_geohash(st_envelope(geom), 10))
;

cluster vectiles.z_med_water using
    ghidx__z_med_water
;

create index sidx__z_med_water on
    vectiles.z_med_water using
        gist (geom)
;

drop table if exists
    vectiles_input.tmp_z_med_water
;
