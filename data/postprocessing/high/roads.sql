/* ROADS */

truncate table vectiles.roads restart identity;

/* insert e_501_tee_j */

-- roads that have (possibly) correct z-level > 0 at either end and the end is on a bridge
with bridges as (select * from vectiles_input.e_505_liikluskorralduslik_rajatis_ka where tyyp = 30)
insert into vectiles.roads (
    geom, originalid, name, road_number, type, class, relative_height, oneway, bridge
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
            from vectiles_input.e_501_tee_j s, bridges b
            where ((a_tasand = 0 and l_tasand > a_tasand) or (l_tasand = 0 and a_tasand > l_tasand)) and st_intersects(b.geom, s.geom)
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;

-- z_level porno with bridges (roads that have z-level set to 0 but they still pass a bridge, wut gives?)
with bridges as (select b4r.*, st_buffer(geom, 0.1) as buff_geom from vectiles_input.bridges_for_roads b4r where b4r.for_road = true)
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
    			from bridges b, vectiles_input.e_501_tee_j s
    			where st_intersects(b.geom, s.geom)
    			group by s.gid
	        )  b
        where
            b.street_gid = s.gid and
            (
	            (st_within(st_startpoint(s.geom), b.bridge) and s.a_tasand=0) or
                (st_within(st_endpoint(s.geom), b.bridge) and s.l_tasand=0) or
                (st_intersects(s.geom, b.bridge) and s.a_tasand=0 and s.l_tasand=0)
            ) and
                not exists (select f.* from vectiles.roads f where f.originalid::int = s.etak_id)
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;


-- roads that have (possibly) correct z-level < 0 at either end and the end is on a tunnel
with tunnels as (select * from vectiles_input.e_505_liikluskorralduslik_rajatis_ka where tyyp = 60)
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
            from vectiles_input.e_501_tee_j s, tunnels b
            where ((a_tasand < 0 and l_tasand > a_tasand) or (l_tasand < 0 and a_tasand > l_tasand)) and st_intersects(b.geom, s.geom)
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;

-- FIX Z LEVELS for a_tasand != l_tasand
-- a_tasand != l_tasand and not intersects(geom, tunnel) and not intersects(geom, bridge)
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
            foo.z as z,
            case when foo.z < 0 then true else false end as has_tunnel,
            case when foo.z > 0 then true else false end as has_bridge,
            geom
        from (
            select
                s.gid, s.a_tasand, s.l_tasand ,
                case when a.a = 0 then a_tasand else l_tasand end as z,
                st_linesubstring(s.geom, a.a, a.a + 0.5) as geom
            from (
                select * from vectiles_input.e_501_tee_j
                where
                    a_tasand != l_tasand and
                    not exists (
                        select f.*
                        from vectiles.roads f
                        where f.originalid::int = e_501_tee_j.etak_id)
                )s, (select unnest(array[0,0.5]) as a) a
            order by gid
        ) foo
    ) bar
    where s.gid = bar.gid
) f
;

-- FIX Z LEVELS for a_tasand == l_tasand
-- a_tasand == l_tasand and and intersects(geom, bridge) and intersects(geom, other.street.geom where other.street.a_tasand < a_tasand)
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
            foo.z as z,
            case when foo.z < 0 then true else false end as has_tunnel,
            case when foo.z > 0 then true else false end as has_bridge,
            geom
        from (
            select
                s.gid, s.a_tasand, s.l_tasand ,
                case when a.a = 0 then a_tasand else l_tasand end as z,
                st_linesubstring(s.geom, a.a, a.a + 0.5) as geom
            from (
                select *
                from vectiles_input.e_501_tee_j
                where
                    a_tasand != l_tasand and
                    not exists (
                        select f.*
                        from vectiles.roads f
                        where f.originalid::int = e_501_tee_j.etak_id
                    )
                )s, (select unnest(array[0,0.5]) as a) a
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
        ) and
        a_tasand = l_tasand
) f
;

--with bridges as (select * from vectiles.e_505_liikluskorralduslik_rajatis_ka where tyyp = 30)
update vectiles.roads set bridge = true
from (
    select s.etak_id, s.a_tasand, s.l_tasand
    from vectiles_input.e_501_tee_j s --, bridges b
    where s.a_tasand > 0 and s.l_tasand > 0 --and st_contains(b.geom, s.geom)
) f
where roads.originalid = f.etak_id::varchar
;


--with tunnels as (select * from vectiles.e_505_liikluskorralduslik_rajatis_ka where tyyp = 60)
update vectiles.roads set tunnel = true
from (
    select s.etak_id, s.a_tasand, s.l_tasand
    from vectiles_input.e_501_tee_j s --, tunnels b
    where s.a_tasand < 0 and s.l_tasand < 0 --and st_contains(b.geom, s.geom)
) f
where roads.originalid = f.etak_id::varchar
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
