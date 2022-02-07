/* RAILWAYS */

truncate table vectiles.railways restart identity;
/* insert e_502_roobastee_j */

-- splits of rail on top of bridges
insert into vectiles.railways (
    geom, originalid, name, type, subtype, class, bridge
)
select
    st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(bar.geom), 0.1)))).geom, 1) as geom,
    r.etak_id, null as name,
    case
        when r.tyyp = 40 then 'tram'
        else 'rail'
    end::vectiles.type_railways as type,
    case
        when r.tyyp = 10 then 'rail.large_gauge'
        when r.tyyp = 20 then 'rail.narrow_gauge'
        when r.tyyp = 30 then 'rail.funicular'
        when r.tyyp = 40 then 'tram.'
        else 'rail.other'
    end::vectiles.subtype_railways as subtype,
    case
        when r.tahtsus = 10 then 'main'
        when r.tahtsus = 20 then 'side'
        when r.tahtsus = 30 then 'branch'
        else null
    end::vectiles.class_railways as class,
    case
        when has_roads=false and st_contains=true then true
        when st_contains=true and (st_intersects_a_road=true or st_intersects_water=true) then true
        when st_contains=true and (st_intersects_a_road=false and st_intersects_water=false) then false
        else false
    end as bridge
from vectiles_input.e_502_roobastee_j  r, (
    select
        foo.gid,
        split as geom,
        coalesce(st_intersects(vectiles_input.st_extend(split, 30, 0), t.geom), false) as st_intersects_a_road,
        coalesce(st_intersects(vectiles_input.st_extend(split, 30, 0), b.water_geoms), false) as st_intersects_water,
        st_contains(st_buffer(b.bridge, 0.5), split),
        t.geom is not null as has_roads
    from (
        select r.gid, (st_dump(st_split(r.geom, b.bridges))).geom as split, b.bridge_gids
        from vectiles_input.e_502_roobastee_j r, (
            select r.gid as rail_gid, st_union(b.geom) as bridges, array_agg(b.gid) as bridge_gids
            from
                vectiles_input.e_502_roobastee_j r,
                vectiles_input.bridges b
                    left join
                        vectiles_input.rail_road_inter_calc c on
                            b.gid = c.bridge_gid
            where
                st_intersects(b.geom, r.geom) and
                (coalesce(c.for_rail,false) = true or b.water_geoms is not null) and
                r.tyyp != 40
            group by r.gid
        ) b
        where  b.rail_gid = r.gid
    ) foo
        left join lateral (
            select b.geom as bridge, b.water_geoms
            from vectiles_input.bridges b
            where b.gid = any(foo.bridge_gids) and st_within(foo.split, st_buffer(b.geom, 0.5))
        ) b on true
        left join lateral (
            select st_union(st_intersection(j.geom, b.bridge)) as geom
            from vectiles.roads j
            where
                st_intersects(j.geom, b.bridge) and
                j.relative_height <= 0
        ) t on true
) bar
where r.gid = bar.gid
;


insert into vectiles.railways (
    geom, originalid, name, type, subtype, class, bridge
)
select
    st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(geom), 0.1)))).geom, 1) as geom,
    etak_id, null as name,
    case
        when tyyp = 40 then 'tram' --tyyp_t = 'Trammitee'
        else 'rail'
    end::vectiles.type_railways as type,
    case
        when tyyp = 10 then 'rail.large_gauge'
        when tyyp = 20 then 'rail.narrow_gauge'
        when tyyp = 30 then 'rail.funicular'
        when tyyp = 40 then 'tram.'
        else 'rail.other'
    end::vectiles.subtype_railways as subtype,
    case
        when tahtsus = 10 then 'main'
        when tahtsus = 20 then 'side'
        when tahtsus = 30 then 'branch'
        else null
    end::vectiles.class_railways as class,
    false as bridge
from vectiles_input.e_502_roobastee_j
where
    not exists (
        select f.* from vectiles.railways f where f.originalid::int = e_502_roobastee_j.etak_id
    ) and tyyp != 40
;

/* tramlines intersecting bridges. */
/* roads and trams are usually either both z=0 or z=1 if intersects a railway */
insert into vectiles.railways (
    geom, originalid, name, type, subtype, class, bridge, tunnel
)
select
    st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(bar.geom), 0.1)))).geom, 1) as geom,
    r.etak_id, null as name,
    case
        when r.tyyp = 40 then 'tram'
        else 'rail'
    end::vectiles.type_railways as type,
    case
        when r.tyyp = 10 then 'rail.large_gauge'
        when r.tyyp = 20 then 'rail.narrow_gauge'
        when r.tyyp = 30 then 'rail.funicular'
        when r.tyyp = 40 then 'tram.'
        else 'rail.other'
    end::vectiles.subtype_railways as subtype,
    case
        when r.tahtsus = 10 then 'main'
        when r.tahtsus = 20 then 'side'
        when r.tahtsus = 30 then 'branch'
        else null
    end::vectiles.class_railways as class,
    case
        when st_contains_bridge=true and (st_intersects_a_railway=true or st_intersects_water=true) then true
        when st_contains_bridge=true and (st_intersects_a_railway=false and st_intersects_water=false) then false
        else false
    end as bridge,
    case
        when tunnel_has_railroads=true and st_contains_tunnel=true then true
        else false
    end as tunnel
from vectiles_input.e_502_roobastee_j  r, (
    select
        foo.gid,
        split as geom,
        /*coalesce(st_intersects(vectiles_input.st_extend(split, 30, 0), t.geom), false) as st_intersects_a_road,*/
        coalesce(st_intersects(vectiles_input.st_extend(split, 30, 0), rail.geom), false) as st_intersects_a_railway,
        coalesce(st_intersects(vectiles_input.st_extend(split, 30, 0), b.water_geoms), false) as st_intersects_water,
        st_contains(st_buffer(b.bridge, 0.5), split) as st_contains_bridge,
        st_contains(st_buffer(t.tunnel, 0.5), split) as st_contains_tunnel,
        t.rail_geoms is not null as tunnel_has_railroads
    from (
        select r.gid, (st_dump(st_split(r.geom, b.bridges))).geom as split
        from vectiles_input.e_502_roobastee_j r, (
            select r.gid as rail_gid, st_union(b.geom) as bridges
            from
                vectiles_input.e_502_roobastee_j r
                    join lateral (
                        select
                            b.geom from vectiles_input.bridges b
                        where
                            st_intersects(b.geom, r.geom)
                        union
                        select
                            t.geom from vectiles_input.tunnels t
                        where
                            st_intersects(t.geom, r.geom)
                    ) b on true

            where
                r.tyyp = 40 --and r.gid=3808
            group by r.gid
        ) b
        where  b.rail_gid = r.gid
    ) foo
        left join lateral (
            select b.geom as bridge, b.water_geoms
            from vectiles_input.bridges b
            where st_within(foo.split, st_buffer(b.geom, 0.5))
        ) b on true
        left join lateral (
            select t.geom as tunnel, t.rail_geoms
            from vectiles_input.tunnels t
            where st_within(foo.split, st_buffer(t.geom, 0.5))
        ) t on true
        left join lateral(
            select st_union(st_intersection(j.geom, b.bridge)) as geom
            from vectiles.railways j
            where
                st_intersects(j.geom, b.bridge) and
                j.bridge = false
        ) rail on true
) bar
where
    r.gid = bar.gid and
    not exists (
        select f.* from vectiles.railways f where f.originalid::int = r.etak_id
    )
;

insert into vectiles.railways (
    geom, originalid, name, type, subtype, class, bridge, tunnel
)
select
    st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(geom), 0.1)))).geom, 1) as geom,
    etak_id, null as name,
    case
        when tyyp = 40 then 'tram' --tyyp_t = 'Trammitee'
        else 'rail'
    end::vectiles.type_railways as type,
    case
        when tyyp = 10 then 'rail.large_gauge'
        when tyyp = 20 then 'rail.narrow_gauge'
        when tyyp = 30 then 'rail.funicular'
        when tyyp = 40 then 'tram.'
        else 'rail.other'
    end::vectiles.subtype_railways as subtype,
    case
        when tahtsus = 10 then 'main'
        when tahtsus = 20 then 'side'
        when tahtsus = 30 then 'branch'
        else null
    end::vectiles.class_railways as class,
    false as bridge,
    false as tunnel
from vectiles_input.e_502_roobastee_j
where
    not exists (
        select f.* from vectiles.railways f where f.originalid::int = e_502_roobastee_j.etak_id
    ) and tyyp = 40
;
