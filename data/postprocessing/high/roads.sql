/* ROADS */

truncate table vectiles.roads restart identity;
/* insert e_501_tee_j */

-- roads that have (possibly) correct z-level > 0 at either end and the end is on a bridge
insert into vectiles.roads (
    geom, originalid, name, road_number,
    type, class, relative_height, oneway, bridge
)
select
    case
        when f.liiklus = 30 then st_reverse(f.geom)
        else f.geom
    end as geom,
    f.etak_id, f.name, f.road_number, f.type, f.class, f.relative_height,
    f.oneway, f.bridge
from (
    select
        st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(bar.geom), 0.1)))).geom, 1) as geom,
        s.liiklus,
        s.etak_id,
        case
            when s.tyyp=40 then null -- ramp või ühendustee
            when s.tahtsus=40 and nullif(s.karto_nimi, '') is null then null -- kvartalisisene tn, puudub karto_nimi
            else nullif(s.karto_nimi, '')
        end as name, s.tee::varchar as road_number,
        case
            when s.tyyp = 10 then 'highway' --põhimaantee
            /*'motorway', --"kiirtee", pole üldse*/
            when s.tyyp = 20 then 'main'  --tugimaantee
            when s.tyyp = 30 then 'secondary' -- kõrvalmaantee,
            when s.tyyp = 40 then 'secondary' --ramp või ühendustee
            when s.tyyp = 45 then 'secondary' --muu riigimaantee,
            when s.tyyp = 50 then 'local' --tänav,
            when s.tyyp = 60 then 'local' --muu tee
            when s.tyyp = 70 then 'path' --rada
            when s.tyyp = 80 then 'bike' -- kergliiklustee
        end::vectiles.type_roads as type,
        case
            when s.teekate = 10 then 'permanent' --kruusakate
            when s.teekate = 20 then 'gravel' --kruusakate
            when s.teekate = 30 then 'stone' -- kivikate
            when s.teekate = 40 then 'dirt' -- pinnas
            when s.teekate = 50 then 'wood' --puit
            when s.teekate = 999 then 'other' -- muu
            else 'other'
        end::vectiles.class_roads as class,
        bar.z as relative_height,
        case
            when s.liiklus = 10 then false --kahesuunaline
            when s.liiklus in (30, 20) then true -- päri- või vastassuunaline
            else false
        end as oneway,
        bar.has_bridge as bridge
    from vectiles_input.e_501_tee_j s, (
        select
            gid,
            case when st_contains(st_buffer(bridge, 0.5), split) then greatest(l_tasand, a_tasand) else least(a_tasand, l_tasand) end as z,
            case when st_contains(st_buffer(bridge, 0.5), split) then true else false end as has_bridge,
            split as geom
        from (
            select s.gid, s.a_tasand, s.l_tasand , (st_dump(st_split(s.geom, st_boundary(b.geom)))).geom as split, b.geom as bridge
            from vectiles_input.e_501_tee_j s, vectiles_input.bridges  b
            where (
                (a_tasand > 0 and l_tasand != a_tasand and st_within(st_startpoint(s.geom), b.geom)) or
                (l_tasand > 0 and a_tasand != l_tasand and st_within(st_endpoint(s.geom), b.geom))
            ) and
                st_intersects(b.geom, s.geom) --and s.etak_id = 8163331
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;

-- z_level and bridges (roads that have z-level set to 0 but they still pass a bridge, wut gives?)
insert into vectiles.roads (
    geom, originalid, name, road_number, type, class, relative_height, oneway, bridge
)
select
    case
        when liiklus = 30 then st_reverse(f.geom)
        else f.geom
    end as geom,
    f.etak_id, f.name, f.road_number, f.type, f.class, f.relative_height,
    f.oneway, f.bridge
from (
    select
        st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(bar.geom), 0.1)))).geom, 1) as geom,
        s.etak_id,
        s.liiklus,
        case
            when s.tyyp=40 then null -- ramp või ühendustee
            when s.tahtsus=40 and nullif(s.karto_nimi, '') is null then null -- kvartalisisene tn, puudub karto_nimi
            else nullif(s.karto_nimi, '')
        end as name, s.tee::varchar as road_number,
        case
            when s.tyyp = 10 then 'highway' --põhimaantee
            /*'motorway', --"kiirtee", pole üldse*/
            when s.tyyp = 20 then 'main'  --tugimaantee
            when s.tyyp = 30 then 'secondary' -- kõrvalmaantee,
            when s.tyyp = 40 then 'secondary' --ramp või ühendustee
            when s.tyyp = 45 then 'secondary' --muu riigimaantee,
            when s.tyyp = 50 then 'local' --tänav,
            when s.tyyp = 60 then 'local' --muu tee
            when s.tyyp = 70 then 'path' --rada
            when s.tyyp = 80 then 'bike' -- kergliiklustee
        end::vectiles.type_roads as type,
        case
            when s.teekate = 10 then 'permanent' --kruusakate
            when s.teekate = 20 then 'gravel' --kruusakate
            when s.teekate = 30 then 'stone' -- kivikate
            when s.teekate = 40 then 'dirt' -- pinnas
            when s.teekate = 50 then 'wood' --puit
            when s.teekate = 999 then 'other' -- muu
            else 'other'
        end::vectiles.class_roads as class,
        bar.z as relative_height,
        case
            when s.liiklus = 10 then false --kahesuunaline
            when s.liiklus in (30, 20) then true -- päri- või vastassuunaline
            else false
        end as oneway,
        bar.has_bridge as bridge
    from vectiles_input.e_501_tee_j s, (
        select
            gid,
            case when st_contains(st_buffer(bridge, 0.5), split) then coalesce(nullif(greatest(l_tasand, a_tasand), 0), 1) else least(a_tasand, l_tasand) end as z,
            case when st_contains(st_buffer(bridge, 0.5), split) then true else false end as has_bridge,
            split as geom
        from (
            select s.gid, s.a_tasand, s.l_tasand , (st_dump(st_split(s.geom, b.geom))).geom as split, b.bridge as bridge
            from vectiles_input.e_501_tee_j s, (
                select s.gid as street_gid, st_union(st_boundary(b.buff_geom)) as geom, st_union(b.buff_geom) as bridge
                from (select *, st_buffer(geom, 0.1) as buff_geom from vectiles_input.bridges) b, vectiles_input.e_501_tee_j s
                where st_intersects(b.geom, s.geom)
                group by s.gid
            )  b
        where
            b.street_gid = s.gid and
            (
                (st_within(st_startpoint(s.geom), b.bridge) and s.a_tasand>0 and exists (select 1 from vectiles_input.tee_tmp tmp where tmp.xyz = s.xyz_from and tmp.z < s.a_tasand)) or
                (st_within(st_endpoint(s.geom), b.bridge)  and s.l_tasand>0 and exists (select 1 from vectiles_input.tee_tmp tmp where tmp.xyz = s.xyz_to and tmp.z < s.l_tasand))
            ) and
                not exists (select 1 from vectiles.roads f where f.originalid::int = s.etak_id)
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;


-- roads that have (possibly) correct z-level < 0 at either end and the end is on a tunnel
insert into vectiles.roads (
    geom, originalid, name, road_number, type, class, relative_height, oneway, tunnel
)
select
    case
        when liiklus = 30 then st_reverse(f.geom)
        else f.geom
    end as geom,
    f.etak_id, f.name, f.road_number, f.type, f.class, f.relative_height,
    f.oneway, f.tunnel
from (
    select
        st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(bar.geom), 0.1)))).geom, 1) as geom,
        s.etak_id,
        s.liiklus,
        case
            when s.tyyp=40 then null -- ramp või ühendustee
            when s.tahtsus=40 and nullif(s.karto_nimi, '') is null then null -- kvartalisisene tn, puudub karto_nimi
            else nullif(s.karto_nimi, '')
        end as name, s.tee::varchar as road_number,
        case
            when s.tyyp = 10 then 'highway' --põhimaantee
            /*'motorway', --"kiirtee", pole üldse*/
            when s.tyyp = 20 then 'main'  --tugimaantee
            when s.tyyp = 30 then 'secondary' -- kõrvalmaantee,
            when s.tyyp = 40 then 'secondary' --ramp või ühendustee
            when s.tyyp = 45 then 'secondary' --muu riigimaantee,
            when s.tyyp = 50 then 'local' --tänav,
            when s.tyyp = 60 then 'local' --muu tee
            when s.tyyp = 70 then 'path' --rada
            when s.tyyp = 80 then 'bike' -- kergliiklustee
        end::vectiles.type_roads as type,
        case
            when s.teekate = 10 then 'permanent' --kruusakate
            when s.teekate = 20 then 'gravel' --kruusakate
            when s.teekate = 30 then 'stone' -- kivikate
            when s.teekate = 40 then 'dirt' -- pinnas
            when s.teekate = 50 then 'wood' --puit
            when s.teekate = 999 then 'other' -- muu
            else 'other'
        end::vectiles.class_roads as class,
        bar.z as relative_height,
        case
            when s.liiklus = 10 then false --kahesuunaline
            when s.liiklus in (30, 20) then true -- päri- või vastassuunaline
            else false
        end as oneway,
        bar.has_tunnel as tunnel
    from vectiles_input.e_501_tee_j s, (
        select
            gid,
            case when st_contains(st_buffer(tunnel, 0.5), split) then least(l_tasand, a_tasand) else greatest(a_tasand, l_tasand) end as z,
            case when st_contains(st_buffer(tunnel, 0.5), split) then true else false end as has_tunnel,
            split as geom
        from (
            select s.gid, s.a_tasand, s.l_tasand , (st_dump(st_split(s.geom, st_boundary(b.geom)))).geom as split, b.geom as tunnel
            from vectiles_input.e_501_tee_j s, vectiles_input.tunnels b
            where (
                (a_tasand < 0 and l_tasand > a_tasand and st_within(st_startpoint(s.geom), b.geom)) or
                (l_tasand < 0 and a_tasand > l_tasand and st_within(st_endpoint(s.geom), b.geom))
            ) and
            st_intersects(b.geom, s.geom) and
            not exists (
                select f.*
                    from vectiles.roads f
                    where f.originalid::int = s.etak_id
            )
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;


insert into vectiles.roads (
    geom, originalid, name, road_number, type, class, relative_height, oneway, bridge, tunnel
)
select
    case
        when liiklus = 30 then st_reverse(f.geom)
        else f.geom
    end as geom,
    f.etak_id, f.name, f.road_number, f.type, f.class, f.relative_height,
    f.oneway, f.bridge, false as tunnel
from (
    select
        st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(bar.geom), 0.1)))).geom, 1) as geom,
        s.etak_id,
        s.liiklus,
        case
            when s.tyyp=40 then null -- ramp või ühendustee
            when s.tahtsus=40 and nullif(s.karto_nimi, '') is null then null -- kvartalisisene tn, puudub karto_nimi
            else nullif(s.karto_nimi, '')
        end as name, s.tee::varchar as road_number,
        case
            when s.tyyp = 10 then 'highway' --põhimaantee
            /*'motorway', --"kiirtee", pole üldse*/
            when s.tyyp = 20 then 'main'  --tugimaantee
            when s.tyyp = 30 then 'secondary' -- kõrvalmaantee,
            when s.tyyp = 40 then 'secondary' --ramp või ühendustee
            when s.tyyp = 45 then 'secondary' --muu riigimaantee,
            when s.tyyp = 50 then 'local' --tänav,
            when s.tyyp = 60 then 'local' --muu tee
            when s.tyyp = 70 then 'path' --rada
            when s.tyyp = 80 then 'bike' -- kergliiklustee
        end::vectiles.type_roads as type,
        case
            when s.teekate = 10 then 'permanent' --kruusakate
            when s.teekate = 20 then 'gravel' --kruusakate
            when s.teekate = 30 then 'stone' -- kivikate
            when s.teekate = 40 then 'dirt' -- pinnas
            when s.teekate = 50 then 'wood' --puit
            when s.teekate = 999 then 'other' -- muu
            else 'other'
        end::vectiles.class_roads as class,
        bar.z as relative_height,
        case
            when s.liiklus = 10 then false --kahesuunaline
            when s.liiklus in (30, 20) then true -- päri- või vastassuunaline
            else false
        end as oneway,
        case when bar.z > 0 and bar.has_bridge = true then true else false end as bridge
    from vectiles_input.e_501_tee_j s, (
        select
            gid,
            case when st_contains(st_buffer(bridge, 0.5), split) then least(l_tasand, a_tasand) else greatest(a_tasand, l_tasand) end as z,
            case when st_contains(st_buffer(bridge, 0.5), split) then true else false end as has_bridge,
            split as geom
        from (
            select s.gid, s.a_tasand, s.l_tasand , (st_dump(st_split(s.geom, st_boundary(b.geom)))).geom as split, b.geom as bridge
            from vectiles_input.e_501_tee_j s, vectiles_input.bridges b
            where (
                (l_tasand > a_tasand and st_within(st_startpoint(s.geom), b.geom)) or
                (a_tasand > l_tasand and st_within(st_endpoint(s.geom), b.geom))
            ) and
            st_intersects(b.geom, s.geom) and
            not exists (
                select f.*
                    from vectiles.roads f
                    where f.originalid::int = s.etak_id
            )
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;

-- FIX Z LEVELS for a_tasand != l_tasand
insert into vectiles.roads (
    geom, originalid, name, road_number, type, class, relative_height, oneway, tunnel, bridge
)
select
    case
        when liiklus = 30 then st_reverse(f.geom)
        else f.geom
    end as geom,
    f.etak_id, f.name, f.road_number, f.type, f.class, f.relative_height,
    f.oneway, f.tunnel, f.bridge
from (
    select
        st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(bar.geom), 0.1)))).geom, 1) as geom,
        s.etak_id,
        s.liiklus,
        case
            when s.tyyp=40 then null -- ramp või ühendustee
            when s.tahtsus=40 and nullif(s.karto_nimi, '') is null then null -- kvartalisisene tn, puudub karto_nimi
            else nullif(s.karto_nimi, '')
        end as name, s.tee::varchar as road_number,
        case
            when s.tyyp = 10 then 'highway' --põhimaantee
            /*'motorway', --"kiirtee", pole üldse*/
            when s.tyyp = 20 then 'main'  --tugimaantee
            when s.tyyp = 30 then 'secondary' -- kõrvalmaantee,
            when s.tyyp = 40 then 'secondary' --ramp või ühendustee
            when s.tyyp = 45 then 'secondary' --muu riigimaantee,
            when s.tyyp = 50 then 'local' --tänav,
            when s.tyyp = 60 then 'local' --muu tee
            when s.tyyp = 70 then 'path' --rada
            when s.tyyp = 80 then 'bike' -- kergliiklustee
        end::vectiles.type_roads as type,
        case
            when s.teekate = 10 then 'permanent' --kruusakate
            when s.teekate = 20 then 'gravel' --kruusakate
            when s.teekate = 30 then 'stone' -- kivikate
            when s.teekate = 40 then 'dirt' -- pinnas
            when s.teekate = 50 then 'wood' --puit
            when s.teekate = 999 then 'other' -- muu
            else 'other'
        end::vectiles.class_roads as class,
        bar.z as relative_height,
        case
            when s.liiklus = 10 then false --kahesuunaline
            when s.liiklus in (30, 20) then true -- päri- või vastassuunaline
            else false
        end as oneway,
        bar.has_tunnel as tunnel,
        bar.has_bridge as bridge
    from vectiles_input.e_501_tee_j s, (
        select
            gid,
            case
                when -1=any(array[a_tasand, l_tasand]) and st_within(split, tunnel)=false then 0
                when -1=any(array[a_tasand, l_tasand]) and st_within(split, tunnel)=true then -1
                else greatest(a_tasand, l_tasand)
            end as z,
            coalesce(st_within(split, tunnel), false) as has_tunnel,
            greatest(a_tasand, l_tasand)=1 as has_bridge,
            split as geom
        from (
            select
                s.gid, s.a_tasand, s.l_tasand ,
                br.geom as bridge, tu.geom as tunnel,
                (st_dump(
                    case
                        when br.geom is not null or tu.geom is not null then
                            st_split(s.geom, coalesce(st_union(br.geom, tu.geom), br.geom, tu.geom))
                        else s.geom
                    end
                )).geom as split
            from (
                select * from vectiles_input.e_501_tee_j
                where
                    a_tasand != l_tasand and
                    not exists (
                        select f.*
                        from vectiles.roads f
                        where f.originalid::int = e_501_tee_j.etak_id)
                )s
                    left join lateral (
                        select st_union(b.geom) as geom
                        from vectiles_input.bridges b
                        where (
                            st_within(st_startpoint(s.geom), st_buffer(b.geom, 0.5)) and s.a_tasand > 0
                        ) or (
                            st_within(st_endpoint(s.geom), st_buffer(b.geom, 0.5)) and s.l_tasand > 0
                        )
                    ) br on true
                    left join lateral (
                        select st_union(t.geom) as geom
                        from vectiles_input.tunnels t
                        where (
                            st_within(st_startpoint(s.geom), st_buffer(t.geom, 0.5)) and s.a_tasand < 0
                        ) or (
                            st_within(st_endpoint(s.geom), st_buffer(t.geom, 0.5)) and s.l_tasand < 0
                        )
                    ) tu on true
            order by gid
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;

-- FIX Z LEVELS for a_tasand == l_tasand
insert into vectiles.roads (
    geom, originalid, name, road_number, type, class, relative_height, oneway, tunnel, bridge
)
select
    case
        when liiklus = 30 then st_reverse(f.geom)
        else f.geom
    end as geom,
    f.etak_id, f.name, f.road_number, f.type, f.class, f.relative_height,
    f.oneway, f.tunnel, f.bridge
from (
    select
        st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(bar.geom), 0.1)))).geom, 1) as geom,
        s.etak_id,
        s.liiklus,
        case
            when s.tyyp=40 then null -- ramp või ühendustee
            when s.tahtsus=40 and nullif(s.karto_nimi, '') is null then null -- kvartalisisene tn, puudub karto_nimi
            else nullif(s.karto_nimi, '')
        end as name, s.tee::varchar as road_number,
        case
            when s.tyyp = 10 then 'highway' --põhimaantee
            /*'motorway', --"kiirtee", pole üldse*/
            when s.tyyp = 20 then 'main'  --tugimaantee
            when s.tyyp = 30 then 'secondary' -- kõrvalmaantee,
            when s.tyyp = 40 then 'secondary' --ramp või ühendustee
            when s.tyyp = 45 then 'secondary' --muu riigimaantee,
            when s.tyyp = 50 then 'local' --tänav,
            when s.tyyp = 60 then 'local' --muu tee
            when s.tyyp = 70 then 'path' --rada
            when s.tyyp = 80 then 'bike' -- kergliiklustee
        end::vectiles.type_roads as type,
        case
            when s.teekate = 10 then 'permanent' --kruusakate
            when s.teekate = 20 then 'gravel' --kruusakate
            when s.teekate = 30 then 'stone' -- kivikate
            when s.teekate = 40 then 'dirt' -- pinnas
            when s.teekate = 50 then 'wood' --puit
            when s.teekate = 999 then 'other' -- muu
            else 'other'
        end::vectiles.class_roads as class,
        bar.z as relative_height,
        case
            when s.liiklus = 10 then false --kahesuunaline
            when s.liiklus in (30, 20) then true -- päri- või vastassuunaline
            else false
        end as oneway,
        bar.has_tunnel as tunnel,
        bar.has_bridge as bridge
    from vectiles_input.e_501_tee_j s, (
        select
            gid,
            case
                when -1=any(array[a_tasand, l_tasand]) and st_within(split, tunnel)=false then 0
                when -1=any(array[a_tasand, l_tasand]) and st_within(split, tunnel)=true then -1
                else greatest(a_tasand, l_tasand)
            end as z,
            coalesce(st_within(split, tunnel), false) as has_tunnel,
            greatest(a_tasand, l_tasand)=1 as has_bridge,
            split as geom
        from (
            select
                s.gid, s.a_tasand, s.l_tasand ,
                br.geom as bridge, tu.geom as tunnel,
                (st_dump(
                    case
                        when br.geom is not null or tu.geom is not null then
                            st_split(s.geom, coalesce(st_union(br.geom, tu.geom), br.geom, tu.geom))
                        else s.geom
                    end
                )).geom as split
            from (
                select * from vectiles_input.e_501_tee_j
                where
                    a_tasand = l_tasand and
                    not exists (
                        select f.*
                        from vectiles.roads f
                        where f.originalid::int = e_501_tee_j.etak_id)
                )s
                    left join lateral (
                        select st_union(b.geom) as geom
                        from vectiles_input.bridges b
                        where (
                            st_within(st_startpoint(s.geom), st_buffer(b.geom, 0.5)) and s.geom && b.geom and s.a_tasand > 0
                        ) or (
                            st_within(st_endpoint(s.geom), st_buffer(b.geom, 0.5)) and s.geom && b.geom and s.l_tasand > 0
                        )
                    ) br on true
                    left join lateral (
                        select st_union(t.geom) as geom
                        from vectiles_input.tunnels t
                        where (
                            st_within(st_startpoint(s.geom), st_buffer(t.geom, 0.5)) and s.geom && t.geom and s.a_tasand < 0
                        ) or (
                            st_within(st_endpoint(s.geom), st_buffer(t.geom, 0.5)) and s.geom && t.geom and s.l_tasand < 0
                        )
                    ) tu on true
            order by gid
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;

insert into vectiles.roads (
    geom, originalid, name, road_number, type, class, relative_height, oneway
)
select
    case
        when liiklus = 30 then st_reverse(f.geom)
        else f.geom
    end as geom,
    f.etak_id, f.name, f.road_number, f.type, f.class, f.relative_height,
    f.oneway
from (
    select
        st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(geom), 0.1)))).geom, 1) as geom,
        etak_id,
        liiklus,
        case
            when tyyp=40 then null -- ramp või ühendustee
            when tahtsus=40 and nullif(karto_nimi, '') is null then null -- kvartalisisene tn, puudub karto_nimi
            else nullif(karto_nimi, '')
        end as name, tee::varchar as road_number,
        case
            when tyyp = 10 then 'highway' --põhimaantee
            /*'motorway', --"kiirtee", pole üldse*/
            when tyyp = 20 then 'main'  --tugimaantee
            when tyyp = 30 then 'secondary' -- kõrvalmaantee,
            when tyyp = 40 then 'secondary' --ramp või ühendustee
            when tyyp = 45 then 'secondary' --muu riigimaantee,
            when tyyp = 50 then 'local' --tänav,
            when tyyp = 60 then 'local' --muu tee
            when tyyp = 70 then 'path' --rada
            when tyyp = 80 then 'bike' -- kergliiklustee
        end::vectiles.type_roads as type,
        case
            when teekate = 10 then 'permanent' --kruusakate
            when teekate = 20 then 'gravel' --kruusakate
            when teekate = 30 then 'stone' -- kivikate
            when teekate = 40 then 'dirt' -- pinnas
            when teekate = 50 then 'wood' --puit
            when teekate = 999 then 'other' -- muu
            else 'other'
        end::vectiles.class_roads as class,
        case
            when a_tasand = l_tasand then a_tasand
            when abs(a_tasand) > abs(l_tasand) then greatest(a_tasand, l_tasand)
            else l_tasand
        end as relative_height,
        case
            when liiklus = 10 then false --kahesuunaline
            when liiklus in (30, 20) then true -- päri- või vastassuunaline
            else false
        end as oneway
    from vectiles_input.e_501_tee_j
    where
        not exists (
            select f.* from vectiles.roads f where f.originalid::int = e_501_tee_j.etak_id
        )
) f
;

/* insert e_503_siht_j */

insert into vectiles.roads (
    geom, originalid, name, road_number, type, class, relative_height
)
select
    st_simplifypreservetopology((st_dump(st_removerepeatedpoints(st_snaptogrid(st_force2d(geom), 0.1)))).geom, 1) as geom,
    etak_id, null, null,
    'path'::vectiles.type_roads as type, 'dirt'::vectiles.class_roads as class,
    0 as relative_height
from vectiles_input.e_503_siht_j
;


/* if a road segment at relative_height=0 intersects a bridge that intersects a */
/* a) waterbody so that the road segment also intersects said waterbody sergment (within the bridges' area), or */
/* b) intersects a railway on a bridge that's marked for_rail=false (i.e rail goes under the bridge) */
/* then in all probability it's a road on top of a bridge over a waterbody */

drop table if exists vectiles_input.roads_fix_bridges;
create table vectiles_input.roads_fix_bridges as
select
    r.oid,
    r.originalid,
    r.name,
    r.type,
    r.class,
    r.tunnel,
    case
        when st_within(split, st_buffer(c.bridge,0.5)) then true
        else r.bridge
    end as bridge,
    r.oneway,
    r.road_number,
    case
        when st_within(split, st_buffer(c.bridge,0.5)) then 1
        else r.relative_height
    end as relative_height,
    split as geom
from (
    select
        r.oid, r.relative_height,
        (st_dump(st_split(r.geom, b.geom))).geom as split, b.geom as bridge
    from vectiles.roads r
        join lateral (
            select st_union(b.geom) as geom
            from
                vectiles_input.bridges b
                    left join
                        vectiles_input.rail_road_inter_calc c on
                            c.bridge_gid = b.gid
            where
                st_intersects(b.geom, r.geom) and
                (
                    (
                        st_intersects(b.water_geoms, vectiles_input.st_extend(r.geom, 10, 0)) and
                        coalesce(c.for_rail, false)=false
                    ) or
                    (
                        st_intersects(b.rail_geoms, vectiles_input.st_extend(r.geom, 10, 0)) and
                        c.for_rail=false
                    )
                )
        ) b on true
    where r.relative_height = 0
) c
    left join vectiles.roads r on r.oid = c.oid
;

delete from vectiles.roads
where exists (select 1 from vectiles_input.roads_fix_bridges rfb where rfb.oid = roads.oid);

insert into vectiles.roads(
    geom, originalid, name, type, class, tunnel, bridge, oneway, road_number, relative_height
)
select
    geom, originalid, name, type, class, tunnel, bridge, oneway, road_number, relative_height
from vectiles_input.roads_fix_bridges
;

/* if a road segment at relative_height=0 intersects a tunnel that intersects a */
/* railway so that the road segment also intersects said railway segment (within the tunnels area) */
/* then in all probability it's a road on within a tunnel under a railroad */
/* (as underground rail is not present in EE) */

drop table if exists vectiles_input.roads_fix_tunnels;
create table vectiles_input.roads_fix_tunnels as
select
    r.oid,
    r.originalid,
    r.name,
    r.type,
    r.class,
    case
        when st_within(split, st_buffer(c.tunnel,0.5)) then true
        else r.bridge
    end as tunnel,
    r.bridge,
    r.oneway,
    r.road_number,
    case
        when st_within(split, st_buffer(c.tunnel,0.5)) then -1
        else r.relative_height
    end as relative_height,
    split as geom
from (
    select
        r.oid, r.relative_height,
        (st_dump(st_split(r.geom, b.geom))).geom as split, b.geom as tunnel
    from vectiles.roads r
        join lateral (
            select st_union(b.geom) as geom
            from
                vectiles_input.tunnels b
            where
                st_intersects(b.geom, r.geom) and
                st_intersects(b.rail_geoms, vectiles_input.st_extend(r.geom, 10, 0))
        ) b on true
    where
        r.relative_height = 0 and
        r.type in ('bike', 'path')
) c
    left join vectiles.roads r on r.oid = c.oid
;


delete from vectiles.roads
where exists (select 1 from vectiles_input.roads_fix_tunnels rfb where rfb.oid = roads.oid);

insert into vectiles.roads(
    geom, originalid, name, type, class, tunnel, bridge, oneway, road_number, relative_height
)
select
    geom, originalid, name, type, class, tunnel, bridge, oneway, road_number, relative_height
from vectiles_input.roads_fix_tunnels
;
