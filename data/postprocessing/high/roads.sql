/* ROADS */

/* fixing some z-levels beforehand, derive pseudo z-levels from z coordinates. */
/* although these might be broken aswell... */
/* using these simply as backup. */
/* ... and a later try tells us, that these are so broken that they will lead nowhere */
/* and will cause more problems than solve currently. but will keep this calc */
/* in here anyway... maybe sometime later.*/
alter table vectiles_input.e_501_tee_j add column z_coord_from int;
alter table vectiles_input.e_501_tee_j add column z_coord_to int;
alter table vectiles_input.e_501_tee_j add column xyz_from varchar;
alter table vectiles_input.e_501_tee_j add column xyz_to varchar;
alter table vectiles_input.e_501_tee_j add column z_from int;
alter table vectiles_input.e_501_tee_j add column z_to int;


update vectiles_input.e_501_tee_j set z_coord_from = st_z(st_startpoint(geom))::int;
update vectiles_input.e_501_tee_j set z_coord_to = st_z(st_endpoint(geom))::int;
update vectiles_input.e_501_tee_j set xyz_from = (st_x(st_startpoint(geom))*100)::bigint::varchar||(st_y(st_startpoint(geom))*100)::bigint::varchar;
update vectiles_input.e_501_tee_j set xyz_to = (st_x(st_endpoint(geom))*100)::bigint::varchar||(st_y(st_endpoint(geom))*100)::bigint::varchar;
create index idx__e_501_tee_j__xyz_from on vectiles_input.e_501_tee_j (xyz_from);
create index idx__e_501_tee_j__xyz_to on vectiles_input.e_501_tee_j (xyz_to);

/* ... BUT back to z_levels business */
/* create a quasi-tmp table of all intersections and roads. */
drop table if exists vectiles_input.tee_tmp;
create table vectiles_input.tee_tmp as
select
    gid as tee_gid, (array[1, st_numpoints(geom)])[i] as ord,
    elem as z, st_numpoints(geom) as numpoints,
    case when i = 1 then st_startpoint(geom) else st_endpoint(geom) end as geom,
    (array[xyz_from, xyz_to])[i] as xyz,
    tee, teeosa
from
    vectiles_input.e_501_tee_j
        join lateral unnest(array[a_tasand, l_tasand]) with ordinality d(elem, i) on true
;

alter table vectiles_input.tee_tmp add column oid serial;
alter table vectiles_input.tee_tmp add constraint pk__tee_tmp primary key (oid);
create index sidx__tee_tmp on vectiles_input.tee_tmp using gist (geom);
create index idx__tee_tmp__xyz on vectiles_input.tee_tmp (xyz);

alter table vectiles_input.tee_tmp add column total_per_z int;
alter table vectiles_input.tee_tmp add column total int;

update vectiles_input.tee_tmp set
    total = f.count
from (
    select xyz, count(1)
    from vectiles_input.tee_tmp
    group by xyz
) f
where f.xyz = tee_tmp.xyz
;

update vectiles_input.tee_tmp set
    total_per_z = f.count
from (
    select xyz, z, count(1)
    from vectiles_input.tee_tmp
    group by xyz, z
) f
where f.xyz = tee_tmp.xyz and f.z = tee_tmp.z
;

/* problem solving with a hammer: */
/* if it's not on a bridge, and it's not a path/bikeroad (as these have a lot of bridges missing from the input) */
/* and it's claiming to be z-level > 0 then most probably it's not! */
drop table if exists vectiles_input.tee_tmp_new_z;
create table vectiles_input.tee_tmp_new_z as
select
    t.*
from
    vectiles_input.tee_tmp t,
    vectiles_input.e_501_tee_j j
where
    j.gid = t.tee_gid and
    t.z > 0 and
    not exists (
        select 1 from vectiles_input.bridges b where st_within(t.geom, b.geom)
    ) and
    total_per_z = 1 and
    ((total = 1 and a_tasand != l_tasand) or total > 1)
order by xyz
;

create index idx__tee_tmp_new_z__xyz on vectiles_input.tee_tmp_new_z (xyz);
create index idx__tee_tmp_new_z__tee_gid on vectiles_input.tee_tmp_new_z (tee_gid);

update vectiles_input.e_501_tee_j set
    a_tasand = 0
from vectiles_input.tee_tmp_new_z c
where
    c.tee_gid = e_501_tee_j.gid and
    c.xyz = e_501_tee_j.xyz_from
;

update vectiles_input.e_501_tee_j set
    l_tasand = 0
from vectiles_input.tee_tmp_new_z c
where
    c.tee_gid = e_501_tee_j.gid and
    c.xyz = e_501_tee_j.xyz_to
;


/* DONE. recreate temp */
drop table if exists vectiles_input.tee_tmp;
create table vectiles_input.tee_tmp as
select
    gid as tee_gid, (array[1, st_numpoints(geom)])[i] as ord,
    elem as z, st_numpoints(geom) as numpoints,
    case when i = 1 then st_startpoint(geom) else st_endpoint(geom) end as geom,
    (array[xyz_from, xyz_to])[i] as xyz,
    tee, teeosa
from
    vectiles_input.e_501_tee_j
        join lateral unnest(array[a_tasand, l_tasand]) with ordinality d(elem, i) on true
;

alter table vectiles_input.tee_tmp add column oid serial;
alter table vectiles_input.tee_tmp add constraint pk__tee_tmp primary key (oid);
create index sidx__tee_tmp on vectiles_input.tee_tmp using gist (geom);
create index idx__tee_tmp__xyz on vectiles_input.tee_tmp (xyz);

alter table vectiles_input.tee_tmp add column total_per_z int;
alter table vectiles_input.tee_tmp add column total int;

update vectiles_input.tee_tmp set
    total = f.count
from (
    select xyz, count(1)
    from vectiles_input.tee_tmp
    group by xyz
) f
where f.xyz = tee_tmp.xyz
;

update vectiles_input.tee_tmp set
    total_per_z = f.count
from (
    select xyz, z, count(1)
    from vectiles_input.tee_tmp
    group by xyz, z
) f
where f.xyz = tee_tmp.xyz and f.z = tee_tmp.z
;


/* hammer continues... */
/* xyz has two roads associated but only one xyz per z */
/* if there's a bridge present lift everything on this xyz to z=1 otherwise 0 */
drop table if exists vectiles_input.tee_tmp_new_z;
create table vectiles_input.tee_tmp_new_z as
select xyz, array_agg(z), count(1), (array_agg(st_within(f.geom, b.geom)))[1] as is_bridge, (array_agg(f.geom))[1] as geom
from (
    select xyz, z, count(1), min(geom)::geometry(pointzm, 3301) as geom
    from vectiles_input.tee_tmp
    group by xyz, z
    having count(1) = 1
    order by z
) f
    left join vectiles_input.bridges b on st_within(f.geom, b.geom)
group by xyz
having count(1) = 2
order by 2
;

create index idx__tee_tmp_new_z__xyz on vectiles_input.tee_tmp_new_z (xyz);

update vectiles_input.e_501_tee_j set
    a_tasand = case when f.is_bridge is true then 1 else 0 end
from vectiles_input.tee_tmp_new_z f
where f.xyz = e_501_tee_j.xyz_from
;

update vectiles_input.e_501_tee_j set
    l_tasand = case when f.is_bridge is true then 1 else 0 end
from vectiles_input.tee_tmp_new_z f
where f.xyz = e_501_tee_j.xyz_to
;


/*  recreate temp */
drop table if exists vectiles_input.tee_tmp;
create table vectiles_input.tee_tmp as
select
    gid as tee_gid, (array[1, st_numpoints(geom)])[i] as ord,
    elem as z, st_numpoints(geom) as numpoints,
    case when i = 1 then st_startpoint(geom) else st_endpoint(geom) end as geom,
    (array[xyz_from, xyz_to])[i] as xyz,
    tee, teeosa
from
    vectiles_input.e_501_tee_j
        join lateral unnest(array[a_tasand, l_tasand]) with ordinality d(elem, i) on true
;

alter table vectiles_input.tee_tmp add column oid serial;
alter table vectiles_input.tee_tmp add constraint pk__tee_tmp primary key (oid);
create index sidx__tee_tmp on vectiles_input.tee_tmp using gist (geom);
create index idx__tee_tmp__xyz on vectiles_input.tee_tmp (xyz);

alter table vectiles_input.tee_tmp add column total_per_z int;
alter table vectiles_input.tee_tmp add column total int;

update vectiles_input.tee_tmp set
    total = f.count
from (
    select xyz, count(1)
    from vectiles_input.tee_tmp
    group by xyz
) f
where f.xyz = tee_tmp.xyz
;

update vectiles_input.tee_tmp set
    total_per_z = f.count
from (
    select xyz, z, count(1)
    from vectiles_input.tee_tmp
    group by xyz, z
) f
where f.xyz = tee_tmp.xyz and f.z = tee_tmp.z
;

drop table if exists vectiles_input.tee_tmp_new_z;
create table vectiles_input.tee_tmp_new_z as
select
    t.*
from
    vectiles_input.tee_tmp t,
    vectiles_input.e_501_tee_j j
where
    j.gid = t.tee_gid and
    t.z > 0 and
    exists (
        select 1 from vectiles_input.bridges b where st_within(t.geom, b.geom)
    ) and
    total_per_z = 1 and
    ((total = 1 and a_tasand != l_tasand) or total > 1)
order by xyz
;

create index idx__tee_tmp_new_z__xyz on vectiles_input.tee_tmp_new_z (xyz);
create index idx__tee_tmp_new_z__tee_gid on vectiles_input.tee_tmp_new_z (tee_gid);

update vectiles_input.e_501_tee_j set
    a_tasand = 1
from vectiles_input.tee_tmp_new_z c
where
    c.xyz = e_501_tee_j.xyz_from and
    c.total < 4
;

update vectiles_input.e_501_tee_j set
    l_tasand = 1
from vectiles_input.tee_tmp_new_z c
where
    c.xyz = e_501_tee_j.xyz_to and
    c.total < 4
;

/*  recreate temp */
drop table if exists vectiles_input.tee_tmp;
create table vectiles_input.tee_tmp as
select
    gid as tee_gid, (array[1, st_numpoints(geom)])[i] as ord,
    elem as z, st_numpoints(geom) as numpoints,
    case when i = 1 then st_startpoint(geom) else st_endpoint(geom) end as geom,
    (array[xyz_from, xyz_to])[i] as xyz,
    tee, teeosa
from
    vectiles_input.e_501_tee_j
        join lateral unnest(array[a_tasand, l_tasand]) with ordinality d(elem, i) on true
;

alter table vectiles_input.tee_tmp add column oid serial;
alter table vectiles_input.tee_tmp add constraint pk__tee_tmp primary key (oid);
create index sidx__tee_tmp on vectiles_input.tee_tmp using gist (geom);
create index idx__tee_tmp__xyz on vectiles_input.tee_tmp (xyz);

alter table vectiles_input.tee_tmp add column total_per_z int;
alter table vectiles_input.tee_tmp add column total int;

update vectiles_input.tee_tmp set
    total = f.count
from (
    select xyz, count(1)
    from vectiles_input.tee_tmp
    group by xyz
) f
where f.xyz = tee_tmp.xyz
;

update vectiles_input.tee_tmp set
    total_per_z = f.count
from (
    select xyz, z, count(1)
    from vectiles_input.tee_tmp
    group by xyz, z
) f
where f.xyz = tee_tmp.xyz and f.z = tee_tmp.z
;


/* ASSUMPTIONS: */
/* 1) a road segment with a natinal identifier should essentially pass a xyz intersection only once in the same z-level */
/* except for those rare occasions when it doesn't. like a link road starting from under the bridge and finishing on top... */
drop table if exists vectiles_input.tee_tmp_new_z;
create table vectiles_input.tee_tmp_new_z as
select
    y.xyz, y.tee, y.zs, y.count, y.tee_gids,
    y.count_per_z,
    y.current_z,
    t.count as tee_count,
    t.ts,
    coalesce(
        case
            -- intersects a bridge (on top or under), count of roads == 2 and intersects any of water of waterlines then use higher available
            when b.gid is not null and t.count = 2 and (vvk.etak_ids is not null or rail_and_bridge.etak_ids is not null) then y.zs[2]
            -- intersects a bridge (on top or under), count of roads > 2 then manage it somehow later on but mark it differently
            when b.gid is not null and t.count > 2 and (vvk.etak_ids is not null or rail_and_bridge.etak_ids is not null) then -2
            -- intersects a bridge (on top or under) and count of roads == 2, but no waterline or railroad (ecoducts!!! or not... ??? not all of them at least)
            when b.gid is not null and t.count= 2 and (vvk.etak_ids is null and rail_and_bridge.etak_ids is null) then 0
            -- all as before, but number of intersecting roads is > 2
            when b.gid is not null and t.count > 2 and (vvk.etak_ids is null and rail_and_bridge.etak_ids is null) then -3
            -- everything else, pass on
            when b.gid is null and vvk.etak_ids is not null then null
            when b.gid is null and vvk.etak_ids is null then null
        end,
        case
            -- this way crosses railroads, so opt for the smaller (there was no bridge here!)
            when y.zs[1] < 0 and rail.etak_ids is not null then y.zs[1]
            -- there's no rail, take a chance, go for bigger one as the original was -1
            when y.zs[1] < 0 and rail.etak_ids is null then y.zs[2]
            else y.zs[1]
        end
    ) as new_z,
    case when b.gid is null then false else true end as xyz_on_bridge,
    case when vvk.etak_ids is null then false else true end as road_crosses_a_river,
    case when rail_and_bridge.etak_ids is null then false else true end as road_crosses_a_railway,
    b.gid as bridge_gid,
    b.water_etak_ids,
    rail_and_bridge.etak_ids as rail_etak_ids,
    l.roads_per_z as roads_per_lower_z,
    h.roads_per_z as roads_per_higher_z,
    t.geom as road_geom,
    y.geom as xyz_geom
from (
    select
        xyz, tee, array_agg(distinct z) as zs, count(1),
        array_agg(z order by g) as current_z,
        min(geom)::geometry(pointzm, 3301) as geom,
        array_agg(g order by g) as tee_gids,
        array_agg(d.c order by g) as count_per_z
    from (
        select xyz, tee, z, geom, array_agg(tee_gid) as tee_gids
        from vectiles_input.tee_tmp
        where tee is not null
        group by xyz, tee, z, geom
    ) x
        join lateral unnest(tee_gids) g on true
        join lateral (
            select count(1) c
            from vectiles_input.tee_tmp t
            where t.xyz=x.xyz and t.tee=x.tee and t.z = x.z ) d on true
    group by xyz, tee
    having array_upper(array_agg(distinct z), 1)>1
) y
    left join
        vectiles_input.bridges b on st_within(y.geom, b.geom)
    left join lateral (
        select st_union(t.geom) as geom, count(1), array_agg(distinct tee) as ts
        from vectiles_input.e_501_tee_j t
        where t.gid = any(y.tee_gids)) t on true
    left join lateral (
        select array_agg(etak_id) as etak_ids
        from vectiles_input.e_203_vooluveekogu_j j
        where j.etak_id = any(b.water_etak_ids) and st_intersects(j.geom, t.geom)) vvk on true
    left join lateral (
        select array_agg(etak_id) as etak_ids
        from vectiles_input.e_502_roobastee_j r
        where r.etak_id = any(b.rail_etak_ids) and st_intersects(r.geom, t.geom)) rail_and_bridge on true
    left join lateral (
        select array_agg(etak_id) as etak_ids
        from vectiles_input.e_502_roobastee_j r
        where st_intersects(r.geom, t.geom)) rail on true
    left join lateral (
        select count(1) as roads_per_z
        from vectiles_input.tee_tmp low
        where low.xyz = y.xyz and low.z = y.zs[1] and coalesce(low.tee,-1) != y.tee) l on true
    left join lateral (
        select count(1) as roads_per_z
        from vectiles_input.tee_tmp high
        where high.xyz = y.xyz and high.z = y.zs[2] and coalesce(high.tee,-1) != y.tee) h on true
where
    /* assuming road identifiers 'tee' are not messed up */
    /* if a road segments finishes at xyz and exits it at a z, everything is fine */
    2 != any(y.count_per_z)
order by xyz
;

create index idx__tee_tmp_new_z__xyz on vectiles_input.tee_tmp_new_z (xyz);
create index idx__tee_tmp_new_z__tee_gids on vectiles_input.tee_tmp_new_z using gin (tee_gids);

update vectiles_input.e_501_tee_j set
    a_tasand = f.new_z
from
    vectiles_input.tee_tmp_new_z f
where
    f.xyz = e_501_tee_j.xyz_from and
    e_501_tee_j.gid = any(f.tee_gids) and
    f.new_z > -2
;

update vectiles_input.e_501_tee_j set
    l_tasand = f.new_z
from
    vectiles_input.tee_tmp_new_z f
where
    f.xyz = e_501_tee_j.xyz_to and
    e_501_tee_j.gid = any(f.tee_gids) and
    f.new_z > -2
;


/* recreat temp */
drop table if exists vectiles_input.tee_tmp;
create table vectiles_input.tee_tmp as
select
    gid as tee_gid, (array[1, st_numpoints(geom)])[i] as ord,
    elem as z, st_numpoints(geom) as numpoints,
    case when i = 1 then st_startpoint(geom) else st_endpoint(geom) end as geom,
    (array[xyz_from, xyz_to])[i] as xyz,
    tee, teeosa
from
    vectiles_input.e_501_tee_j
        join lateral unnest(array[a_tasand, l_tasand]) with ordinality d(elem, i) on true
;

alter table vectiles_input.tee_tmp add column oid serial;
alter table vectiles_input.tee_tmp add constraint pk__tee_tmp primary key (oid);
create index sidx__tee_tmp on vectiles_input.tee_tmp using gist (geom);
create index idx__tee_tmp__xyz on vectiles_input.tee_tmp (xyz);


alter table vectiles_input.tee_tmp add column total_per_z int;
alter table vectiles_input.tee_tmp add column total int;

update vectiles_input.tee_tmp set
    total = f.count
from (
    select xyz, count(1)
    from vectiles_input.tee_tmp
    group by xyz
) f
where f.xyz = tee_tmp.xyz
;

update vectiles_input.tee_tmp set
    total_per_z = f.count
from (
    select xyz, z, count(1)
    from vectiles_input.tee_tmp
    group by xyz, z
) f
where f.xyz = tee_tmp.xyz and f.z = tee_tmp.z
;


/* comparing NULL road identifiers makes no sense */
/* instead let's calculate the turn angle between roads intersecting at */
/* xyz and assume that the "straightest" pairs are on the same z-level. */
drop table if exists vectiles_input.tee_tmp_new_z;
create table vectiles_input.tee_tmp_new_z as
select
    fix.*,
    y.geom,
    y.count_per_z
from (
    select
        xyz, array_agg(distinct z) as zs, count(1),
        array_agg(z order by g) as current_z,
        min(geom)::geometry(pointzm, 3301) as geom,
        array_agg(g order by g) as tee_gids,
        array_agg(d.c order by g) as count_per_z
    from (
        select xyz, z, min(geom)::geometry(pointzm, 3301) as geom, array_agg(tee_gid) as tee_gids
        from vectiles_input.tee_tmp
        group by xyz, z
    ) x
        join lateral unnest(tee_gids) g on true
        join lateral (
            select count(1) c
            from vectiles_input.tee_tmp t
            where t.xyz=x.xyz /*and coalesce(t.tee,-1) = coalesce(x.tee,-1)*/ and t.z = x.z ) d on true
    group by xyz
    having array_upper(array_agg(distinct z), 1)>1
) y
    left join
        vectiles_input.bridges b on st_within(y.geom, b.geom)
    left join lateral (
        select st_union(t.geom) as geom, count(1), array_agg(distinct tee) as ts
        from vectiles_input.e_501_tee_j t
        where t.gid = any(y.tee_gids)) t on true
    left join lateral (
        select array_agg(etak_id) as etak_ids
        from vectiles_input.e_203_vooluveekogu_j j
        where j.etak_id = any(b.water_etak_ids) and st_intersects(j.geom, t.geom)) vvk on true
    left join lateral (
        select array_agg(etak_id) as etak_ids
        from vectiles_input.e_502_roobastee_j r
        where r.etak_id = any(b.rail_etak_ids) and st_intersects(r.geom, t.geom)) rail_and_bridge on true
    left join lateral (
        select array_agg(etak_id) as etak_ids
        from vectiles_input.e_502_roobastee_j r
        where st_intersects(r.geom, t.geom)) rail on true
    join lateral vectiles_input.azimuth_based_z_level_fix(y.xyz, y.tee_gids) fix on true
where
    /* if a road segments finishes at xyz and exits it at a z, everything is fine */
    1 = any(y.count_per_z)
order by xyz
;

create index idx__tee_tmp_new_z__xyz on vectiles_input.tee_tmp_new_z (xyz);
create index idx__tee_tmp_new_z__tee_gids on vectiles_input.tee_tmp_new_z using gin (tee_gids);

update vectiles_input.e_501_tee_j set
    a_tasand = f.new_z
from
    vectiles_input.tee_tmp_new_z f
where
    f.xyz = e_501_tee_j.xyz_from and
    e_501_tee_j.gid = any(f.tee_gids) and
    f.new_z > -2
;

update vectiles_input.e_501_tee_j set
    l_tasand = f.new_z
from
    vectiles_input.tee_tmp_new_z f
where
    f.xyz = e_501_tee_j.xyz_to and
    e_501_tee_j.gid = any(f.tee_gids) and
    f.new_z > -2
;


/* and recreate temp... */
drop table if exists vectiles_input.tee_tmp;
create table vectiles_input.tee_tmp as
select
    gid as tee_gid, (array[1, st_numpoints(geom)])[i] as ord,
    elem as z, st_numpoints(geom) as numpoints,
    case when i = 1 then st_startpoint(geom) else st_endpoint(geom) end as geom,
    (array[xyz_from, xyz_to])[i] as xyz,
    tee, teeosa
from
    vectiles_input.e_501_tee_j
        join lateral unnest(array[a_tasand, l_tasand]) with ordinality d(elem, i) on true
;

alter table vectiles_input.tee_tmp add column oid serial;
alter table vectiles_input.tee_tmp add constraint pk__tee_tmp primary key (oid);
create index sidx__tee_tmp on vectiles_input.tee_tmp using gist (geom);
create index idx__tee_tmp__xyz on vectiles_input.tee_tmp (xyz);


alter table vectiles_input.tee_tmp add column total_per_z int;
alter table vectiles_input.tee_tmp add column total int;

update vectiles_input.tee_tmp set
    total = f.count
from (
    select xyz, count(1)
    from vectiles_input.tee_tmp
    group by xyz
) f
where f.xyz = tee_tmp.xyz
;

update vectiles_input.tee_tmp set
    total_per_z = f.count
from (
    select xyz, z, count(1)
    from vectiles_input.tee_tmp
    group by xyz, z
) f
where f.xyz = tee_tmp.xyz and f.z = tee_tmp.z
;


/* an intersection at z=-1 and z=0 and nothing on z=1 */
/* and it intersects A BRIDGE */
/* +1 to z-levels at current z=0 */
update vectiles_input.e_501_tee_j set
    a_tasand = 1
from (
    select t.xyz, t.z, tee_gid, total_per_z, count(1) filter(where z=1) over (partition by xyz) as z1_count, t.geom
    from vectiles_input.tee_tmp t, vectiles_input.bridges b
    where
        st_within (t.geom, b.geom) and
        exists (
            select 1 from vectiles_input.tee_tmp a
            where a.xyz = t.xyz and a.z = -1
        )
) b
where
    b.z1_count = 0 and
    b.z = 0 and
    e_501_tee_j.gid = b.tee_gid and
    e_501_tee_j.xyz_from = b.xyz and
    e_501_tee_j.a_tasand = 0;

update vectiles_input.e_501_tee_j set
    l_tasand = 1
from (
    select t.xyz, t.z, tee_gid, total_per_z, count(1) filter(where z=1) over (partition by xyz) as z1_count, t.geom
    from vectiles_input.tee_tmp t, vectiles_input.bridges b
    where
        st_within (t.geom, b.geom) and
        exists (
            select 1 from vectiles_input.tee_tmp a
            where a.xyz = t.xyz and a.z = -1
        )
) b
where
    b.z1_count = 0 and
    b.z = 0 and
    e_501_tee_j.gid = b.tee_gid and
    e_501_tee_j.xyz_to = b.xyz and
    e_501_tee_j.l_tasand = 0;
;

/* and recreate temp... */
drop table if exists vectiles_input.tee_tmp;
create table vectiles_input.tee_tmp as
select
    gid as tee_gid, (array[1, st_numpoints(geom)])[i] as ord,
    elem as z, st_numpoints(geom) as numpoints,
    case when i = 1 then st_startpoint(geom) else st_endpoint(geom) end as geom,
    (array[xyz_from, xyz_to])[i] as xyz,
    tee, teeosa
from
    vectiles_input.e_501_tee_j
        join lateral unnest(array[a_tasand, l_tasand]) with ordinality d(elem, i) on true
;

alter table vectiles_input.tee_tmp add column oid serial;
alter table vectiles_input.tee_tmp add constraint pk__tee_tmp primary key (oid);
create index sidx__tee_tmp on vectiles_input.tee_tmp using gist (geom);
create index idx__tee_tmp__xyz on vectiles_input.tee_tmp (xyz);
alter table vectiles_input.tee_tmp add column total_per_z int;
alter table vectiles_input.tee_tmp add column total int;

update vectiles_input.tee_tmp set
    total = f.count
from (
    select xyz, count(1)
    from vectiles_input.tee_tmp
    group by xyz
) f
where f.xyz = tee_tmp.xyz
;

update vectiles_input.tee_tmp set
    total_per_z = f.count
from (
    select xyz, z, count(1)
    from vectiles_input.tee_tmp
    group by xyz, z
) f
where f.xyz = tee_tmp.xyz and f.z = tee_tmp.z
;

/* and intersection at a bridge with four road segments at z=0 and none at z=1 */
/* but one (and only one) of the segments has another end at z=1 */
/* clc azimuth based pairs and assign z=1 to the one pairing */
drop table if exists vectiles_input.tee_tmp_new_z;
create table vectiles_input.tee_tmp_new_z as
select * from (
    select
        fix.*, c.other_gid
    from (
        select xyz, array_agg(tee_gid) as tee_gids, (array_agg(distinct o))[1] as other_gid
        from
        (
            select t.xyz, t.z, tee_gid, total_per_z, count(1) filter(where z=1) over (partition by xyz) as z1_count, t.geom, j.gid as o
            from vectiles_input.tee_tmp t, vectiles_input.bridges b, vectiles_input.e_501_tee_j j
            where
                z = 0 and
                total_per_z > 3 and
                st_within (t.geom, b.geom) and
                ((j.l_tasand = 1 and j.xyz_from = t.xyz ) or (j.a_tasand = 1 and j.xyz_to = t.xyz))
        ) b
        /* but only if we're currently z=0 and there's nothing on z=1 */
        where b.z1_count = 0 and b.z = 0
        group by xyz
        /* and only if there's 1 other that's partly z=1 */
        having array_upper(array_agg(distinct o), 1) = 1
    ) c
    join lateral vectiles_input.azimuth_based_z_level_fix(c.xyz, c.tee_gids) fix on true
) d
where
    other_gid = any(tee_gids)
;
create index idx__tee_tmp_new_z__xyz on vectiles_input.tee_tmp_new_z (xyz);
create index idx__tee_tmp_new_z__tee_gids on vectiles_input.tee_tmp_new_z using gin (tee_gids);


update vectiles_input.e_501_tee_j set
    l_tasand = f.new_z
from
    vectiles_input.tee_tmp_new_z f
where
    f.xyz = e_501_tee_j.xyz_to and e_501_tee_j.gid = any(f.tee_gids)
;

update vectiles_input.e_501_tee_j set
    a_tasand = f.new_z
from
    vectiles_input.tee_tmp_new_z f
where
    f.xyz = e_501_tee_j.xyz_from and e_501_tee_j.gid = any(f.tee_gids)
;

/* and recreate temp... */
drop table if exists vectiles_input.tee_tmp;
create table vectiles_input.tee_tmp as
select
    gid as tee_gid, (array[1, st_numpoints(geom)])[i] as ord,
    elem as z, st_numpoints(geom) as numpoints,
    case when i = 1 then st_startpoint(geom) else st_endpoint(geom) end as geom,
    (array[xyz_from, xyz_to])[i] as xyz,
    tee, teeosa
from
    vectiles_input.e_501_tee_j
        join lateral unnest(array[a_tasand, l_tasand]) with ordinality d(elem, i) on true
;

alter table vectiles_input.tee_tmp add column oid serial;
alter table vectiles_input.tee_tmp add constraint pk__tee_tmp primary key (oid);
create index sidx__tee_tmp on vectiles_input.tee_tmp using gist (geom);
create index idx__tee_tmp__xyz on vectiles_input.tee_tmp (xyz);
alter table vectiles_input.tee_tmp add column total_per_z int;
alter table vectiles_input.tee_tmp add column total int;

update vectiles_input.tee_tmp set
    total = f.count
from (
    select xyz, count(1)
    from vectiles_input.tee_tmp
    group by xyz
) f
where f.xyz = tee_tmp.xyz
;

update vectiles_input.tee_tmp set
    total_per_z = f.count
from (
    select xyz, z, count(1)
    from vectiles_input.tee_tmp
    group by xyz, z
) f
where f.xyz = tee_tmp.xyz and f.z = tee_tmp.z
;

/* DATA PREPARTION */

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
/* waterbody so that the road segment also intersects said waterbody sergment (within the bridges' area) */
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
            where
                st_intersects(b.geom, r.geom) and
                st_intersects(b.water_geoms, vectiles_input.st_extend(r.geom, 10, 0))
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
    where r.relative_height = 0 and r.type in ('bike', 'path')
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
