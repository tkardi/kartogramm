/* build "bridges_for_roads" */
drop table if exists vectiles_input.bridges;
create table vectiles_input.bridges as
select
    v.etak_ids as water_etak_ids, r.etak_ids as rail_etak_ids,
    ka.etak_id, ka.tyyp, ka.tyyp_t, ka.nimetus, ka.geom,
    st_force2d(v.geom) as water_geoms, st_force2d(r.geom) as rail_geoms
from
    vectiles_input.e_505_liikluskorralduslik_rajatis_ka ka
        left join lateral (
            select array_agg(etak_id) as etak_ids, st_union(geom) as geom
            from (
                select
                    j.etak_id as etak_id, st_intersection(ka.geom, j.geom) as geom
                from vectiles_input.e_203_vooluveekogu_j j
                where st_intersects(ka.geom, j.geom)
                union all
                select
                    etak_id, st_boundary(geom) as geom
                from (
                    select
                        a.etak_id as etak_id, (st_dump(st_intersection(ka.geom, a.geom))).geom as geom
                    from vectiles_input.e_202_seisuveekogu_a a
                    where st_intersects(ka.geom, a.geom)
                ) b
            ) f
        ) v on true
    left join lateral(
        select array_agg(etak_id) etak_ids, st_union(st_intersection(ka.geom, j.geom)) as geom
        from vectiles_input.e_502_roobastee_j j
        where st_intersects(ka.geom, j.geom)
    ) r on true
where
    ka.tyyp = 30
;

insert into vectiles_input.bridges(
    water_etak_ids, rail_etak_ids,
    etak_id, tyyp, tyyp_t, nimetus, geom,
    water_geoms, rail_geoms
)
select
    v.etak_ids as water_etak_ids, r.etak_ids as rail_etak_ids,
    ka.etak_id, ka.tyyp, ka.tyyp_t, null as nimetus, st_force4d(g) as geom,
    st_force2d(v.geom) as water_geoms, st_force2d(r.geom) as rail_geoms
from
    vectiles_input.e_505_liikluskorralduslik_rajatis_j ka
        join lateral st_buffer(ka.geom, 1.5, 'endcap=flat join=mitre mitre_limit=5.0') g on true
        left join lateral (
            select array_agg(etak_id) as etak_ids, st_union(geom) as geom
            from (
                select
                    j.etak_id as etak_id, st_intersection(g, j.geom) as geom
                from vectiles_input.e_203_vooluveekogu_j j
                where st_intersects(ka.geom, j.geom)
                union all
                select
                    etak_id, st_boundary(geom) as geom
                from (
                    select
                        a.etak_id as etak_id, (st_dump(st_intersection(g, a.geom))).geom as geom
                    from vectiles_input.e_202_seisuveekogu_a a
                    where st_intersects(ka.geom, a.geom)
                ) b
            ) f
        ) v on true
    left join lateral(
        select array_agg(etak_id) etak_ids, st_union(st_intersection(g, j.geom)) as geom
        from vectiles_input.e_502_roobastee_j j
        where st_intersects(ka.geom, j.geom)
    ) r on true
where
    ka.tyyp = 40
;

alter table vectiles_input.bridges add column gid serial not null;
alter table vectiles_input.bridges add constraint pk__bridges primary key (gid);
create index sidx__bridges on vectiles_input.bridges using gist (geom);
create index sidx__bridges__water_geoms on vectiles_input.bridges using gist (water_geoms);
create index sidx__bridges__rail_geoms on vectiles_input.bridges using gist (rail_geoms);
create index idx__bridges__water_etak_ids on vectiles_input.bridges using gin (water_etak_ids);
create index idx__bridges__rail_etak_ids on vectiles_input.bridges using gin (rail_etak_ids);
create unique index uidx__bridges__etak_id on vectiles_input.bridges (etak_id);
