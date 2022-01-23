/* RAILWAYS */

truncate table vectiles.railways restart identity;
/* insert e_502_roobastee_j */

-- splits of rail on top of bridges
with bridges as (select * from vectiles_input.bridges_for_rails where for_rail = true)
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
	bar.has_bridge as bridge
from vectiles_input.e_502_roobastee_j  r, (
    select
        foo.gid,
        case when st_contains(st_buffer(b.geom, 0.5), split) then true else false end as has_bridge,
        split as geom
    from (
        select r.gid, (st_dump(st_split(r.geom, b.geom))).geom as split
        from vectiles_input.e_502_roobastee_j r, (
		    select r.gid as rail_gid, st_union(st_boundary(b.geom)) as geom
			from bridges b, vectiles_input.e_502_roobastee_j r
			where st_intersects(b.geom, r.geom)
			group by r.gid
	    ) b
        where  b.rail_gid = r.gid
    ) foo, bridges b
	where st_intersects(st_buffer(b.geom, 0.5), foo.split)
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
    )
;
