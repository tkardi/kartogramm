/* Z_MED_NATURAL */

truncate table vectiles.z_med_natural restart identity;

drop index if exists vectiles.sidx__z_med_natural;
drop index if exists vectiles.ghidx__z_med_natural;

with
    data as (
        select
            st_subdivide(st_transform(geom, 4326), 1024) as geom,
            originalid, name, type, subtype
        from (
            select
                name, type, subtype, originalid,
                --(select st_buildarea(st_collect(case when d.path[1] = 1 then d.geom else st_reverse(d.geom) end)) from st_dumprings(f.geom) d where st_area(d.geom) > 10000) as geom
                geom
            from (
                select
                    st_simplifypreservetopology((st_dump(st_makevalid(st_snaptogrid(geom, 10)))).geom, 0.1) as geom, null as originalid, null as name,
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
             ) f
        where
            lower(geometrytype(geom)) = 'polygon'
        ) f
    )
insert into vectiles.z_med_natural (
    geom, originalid, name, type, subtype
)
select
    geom, originalid, name, type, subtype
from
    data
order by
    st_geohash(st_envelope(geom), 10) collate "C"
;


create index ghidx__z_med_natural on
    vectiles.z_med_natural
        (st_geohash(st_envelope(geom), 10))
;

cluster vectiles.z_med_natural using
    ghidx__z_med_natural
;

create index sidx__z_med_natural on
    vectiles.z_med_natural using
        gist (geom)
;
