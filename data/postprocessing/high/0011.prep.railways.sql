drop table if exists vectiles_input.rail_road_inter_calc;
create table vectiles_input.rail_road_inter_calc as
select
    bridge_gid, tee_gids,
    road_geoms, rail_geoms, tram_geoms,
    st_length(road_geoms) as road_length,
    st_length(rail_geoms) as rail_length,
    st_length(tram_geoms) as tram_length
from (
    select
        bridge_gid, array_agg(tee_gid) as tee_gids,
        st_union(tram.geom) as tram_geoms,
        st_union(road.geom) as road_geoms,
        st_union(rail.geom) as rail_geoms
    from (
    select
        j.gid as tee_gid, b.gid as bridge_gid,
        st_intersection(j.geom,b.geom) as road_geom,
        st_intersection(r.geom,b.geom) as rail_geom,
        st_intersection(t.geom,b.geom) as tram_geom
    from
        vectiles_input.e_502_roobastee_j r,
        vectiles_input.bridges b
            left join vectiles_input.e_501_tee_j j on st_intersects(b.geom, j.geom) and (
                /* it intersects a railway but not tram */
                exists (select 1 from vectiles_input.e_502_roobastee_j r where st_intersects(j.geom, r.geom) and r.tyyp != 40) or (
                    /* or any of the from to z levels is at 1 and within a bridge */
                    (j.l_tasand > 0 and st_within(st_endpoint(j.geom), b.geom)) or
                    (j.a_tasand > 0 and st_within(st_startpoint(j.geom), b.geom))
                )
            )
            /* include tramlines as "roads" */
            left join vectiles_input.e_502_roobastee_j t on st_intersects(b.geom, t.geom) and t.tyyp = 40
    where
        r.etak_id = any(b.rail_etak_ids) and
        r.tyyp != 40
    ) f
        left join lateral st_dump(road_geom) as road on true
        left join lateral st_dump(rail_geom) as rail on true
        left join lateral st_dump(tram_geom) as tram on true
    where
        geometrytype(rail.geom) = 'LINESTRING' and geometrytype(road.geom) = 'LINESTRING'
    group by bridge_gid
) g
;

alter table vectiles_input.rail_road_inter_calc add column for_rail boolean default false;

update vectiles_input.rail_road_inter_calc set
    for_rail = true
where
    coalesce(road_length,0) + coalesce(tram_length,0) < rail_length
;

alter table vectiles_input.rail_road_inter_calc add constraint pk__rail_road_inter_calc primary key (bridge_gid);
