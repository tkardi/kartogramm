/* WATERLINE */

truncate table vectiles.waterline restart identity;

insert into vectiles.waterline(
    geom, name, type, class, underground
)
select
    (st_dump(st_linemerge(st_collect(geom)))).geom , name, type, class, underground
from (
    select st_snaptogrid((st_dump(st_force2d(geom))).geom, 1) as geom, nimetus as name,
        case
            when laius=10 then '1m'
            when laius=20 then '3m'
            when laius=30 then '6m'
            when laius=40 then '8m'
            when laius=50 then '12m'
            else '1m'
        end::vectiles.type_waterline as type,
        case
            when tyyp=10 then 'river' --etak: tyyp=10
            when tyyp=20 then 'channel' --etak: tyyp=20
            when tyyp=30 then 'stream' --etak: tyyp=30
            when tyyp=40 then 'mainditch' --etak: tyyp=40
            when tyyp=50 then 'ditch' --etak: tyyp=50
        end::vectiles.class_waterline as class,
        case
            when telje_tyyp = 20 then true
            when laius=60 then true
            else false
        end as underground
    from vectiles_input.e_203_vooluveekogu_j
    where telje_tyyp != 30
) f
group by name, type, class, underground
;

/* WATER */

truncate table vectiles.water restart identity;

/* processing e_203_vooluveekogu_a */
drop table if exists vectiles.tmp_water;
create table vectiles.tmp_water as
select st_buffer(st_snaptogrid((st_dump(st_union(st_force2d(geom)))).geom, 1),0) as geom, nimetus as name
from vectiles_input.e_203_vooluveekogu_a
group by nimetus
;

alter table vectiles.tmp_water add column oid serial;
alter table vectiles.tmp_water add constraint pk__tmp_water primary key(oid);
create index sidx__tmp_water on vectiles.tmp_water using gist (geom);

update vectiles.tmp_water set
    name = f.name
from (
    select w.oid, v.name
    from vectiles.tmp_water w, vectiles.tmp_water v
    where w.name is null and v.name is not null and st_touches(v.geom, w.geom)
) f
where f.oid = tmp_water.oid and tmp_water.name is null
;

insert into vectiles.water(
    geom, name, type
)
select (st_dump(st_union(geom))).geom as geom, name, 'water_way'::vectiles.type_water
from vectiles.tmp_water
group by name
;


insert into vectiles.water(
    geom, originalid, name, type
)
select
    st_buffer(st_snaptogrid((st_dump((geom))).geom, 1), 0) as geom,
    null as etak_id, null as name,
    'sea'::vectiles.type_water
from vectiles.oceans
;

insert into vectiles.water(
    geom, name, type
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom), 1), 0))).geom as geom,
    nimetus as name, 'lake'::vectiles.type_water
from vectiles_input.e_202_seisuveekogu_a
;

drop table if exists vectiles.tmp_water;


/* NATURAL */

truncate table vectiles.natural restart identity;
/* insert  e_305_puittaimestik_a */
insert into vectiles.natural (
    geom, type, subtype
)
select (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    case
        when tyyp = 10 then 'high'
        else 'low'
    end::vectiles.type_natural as type,
    case
        when tyyp = 10 then 'high.mixed'
        else 'low.shrubs'
    end::vectiles.subtype_natural as subtype
from vectiles_input.e_305_puittaimestik_a
;

/* insert  e_304_lage_a */
insert into vectiles.natural (
    geom, originalid, name, type, subtype
)
select (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom, etak_id, null as name,
    case
        when tyyp = 10 then 'low'
        when tyyp = 20 then 'bare'
        when tyyp = 30 then 'low'
        when tyyp = 40 then 'bare'
    end::vectiles.type_natural as type,
    case
        when tyyp = 10 then 'low.grass'
        when tyyp = 20 then 'bare.sand'
        when tyyp = 30 then 'low.grass' -- or bare.rock?
        when tyyp = 40 then 'bare.rock'
    end::vectiles.subtype_natural as subtype
from vectiles_input.e_304_lage_a
;

/* insert e_306_margala_a */

insert into vectiles.natural (
    geom, originalid, name, type, subtype
)
select (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom, etak_id, null as name,
    case
        when tyyp in (10,20,30,40) and puis = 10 then 'low'
        else 'bare'
    end::vectiles.type_natural as type,
    case
        when tyyp in (10,20,30,40) and puis = 10 then 'low.wet'
        else 'bare.wet'
    end::vectiles.subtype_natural as subtype
from vectiles_input.e_306_margala_a
;


/* insert e_307_turbavali_a */
insert into vectiles.natural (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom, etak_id, null as name,
   'bare'::vectiles.type_natural as type,
   'bare.peat'::vectiles.subtype_natural as subtype
from vectiles_input.e_307_turbavali_a
;

/* insert e_301_muu_kolvik_a */
insert into vectiles.natural (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom, etak_id, null as name,
   'low'::vectiles.type_natural as type,
   'low.grass'::vectiles.subtype_natural as subtype
from vectiles_input.e_301_muu_kolvik_a
;


/* BUILTUP */

truncate table vectiles.builtup restart identity;

/* insert e_302_ou_a */

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    etak_id, null as name,
    'area'::vectiles.type_builtup,
    case
        when tyyp = 10 then 'area.residential'
        when tyyp = 20 then 'area.industrial'
    end::vectiles.subtype_builtup as subtype
from vectiles_input.e_302_ou_a
;

/* insert e_401_hoone_ka*/
insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom), 0.1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    case
        when tyyp = 10 then 'building.main'
        when tyyp = 20 then 'building.barn'
        when tyyp = 30 then 'building.foundation'
        when tyyp = 40 then 'building.wreck'
        when tyyp = 50 then 'building.under_construction'
    end::vectiles.subtype_builtup as subtype
from vectiles_input.e_401_hoone_ka
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    'building.cover'::vectiles.subtype_builtup as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 20 -- Katusealune
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    'building.berth'::vectiles.subtype_builtup as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused) = any(array['sadamakai'])
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    'building.'::vectiles.subtype_builtup as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused) != all(array['paadisild', 'sadamakai', 'perroon', 'parkla', 'parkimismaja'])
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    'building'::vectiles.type_builtup,
    'building.underground'::vectiles.subtype_builtup as subtype
from vectiles_input.e_404_maaalune_hoone_ka
;

insert into vectiles.builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom  as geom, etak_id, null as name,
    case
        when tyyp = 30 then 'area'
        when tyyp = 50 then 'building'
        when tyyp = 60 then 'area'
        when tyyp = 90 then 'area'
        when tyyp = 100 then 'area'
    end::vectiles.type_builtup as type,
    case
        when tyyp = 30 then 'area.graveyard'
        when tyyp = 50 then 'building.berth'
        when tyyp = 60 then 'area.sports'
        when tyyp = 90 then 'area.dump'
        when tyyp = 100 then 'area.quarry'
    end::vectiles.subtype_builtup as subtype
from vectiles_input.e_301_muu_kolvik_ka
where tyyp not in (40)
;


/* INFRASTRUCTURE */

truncate table vectiles.infrastructure restart identity;

/* insert e_501_tee_a */

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    etak_id, null as name,
    case
        when tyyp = 10 then 'road'
        when tyyp = 20 then 'parking'
        when tyyp = 30 then 'pavement'
        when tyyp = 40 then 'runway'
        when tyyp = 50 then 'pavement'
        when tyyp = 60 then 'pavement'
        when tyyp = 997 then 'pavement'
        when tyyp = 999 then 'pavement'
    end::vectiles.type_infrastructure as type,
    case
        when tyyp = 10 then 'road.motorway'
        when tyyp = 20 then 'parking.'
        when tyyp = 30 then 'pavement.'
        when tyyp = 40 then 'runway.'
        when tyyp = 50 then 'pavement.'
        when tyyp = 60 then 'pavement.'
        when tyyp = 997 then 'pavement.'
        when tyyp = 999 then 'pavement.'
    end::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_501_tee_a
;




insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom,
    etak_id, nullif(nimetus, ''),
    case
        when tyyp = 60 then 'tunnel'
        when tyyp = 30 then 'bridge'
    end::vectiles.type_infrastructure as type,
    case
        when tyyp = 60 then 'tunnel.'
        when tyyp = 30 then 'bridge.'
    end::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_505_liikluskorralduslik_rajatis_ka --OK. Kuid probleem siin: sildade puhul on meil vaja z-levelit tegelt, hetkel suht kasutud, sest me ei tea, kuhu seda joonistada.
;

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, etak_id, null,
    'parking'::vectiles.type_infrastructure as type,
    'parking.'::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused)=any(array['parkla', 'parkimismaja'])
;

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, etak_id, null,
    'railway'::vectiles.type_infrastructure as type,
    'railway.platform'::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused)=any(array['perroon'])
;

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, etak_id, null,
    'jetty'::vectiles.type_infrastructure as type,
    'jetty.'::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 999 and lower(markused)=any(array['paadisild'])
;

insert into vectiles.infrastructure (
    geom, originalid, name, type, subtype
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom, etak_id, null,
    'runway'::vectiles.type_infrastructure as type,
    'runway.'::vectiles.subtype_infrastructure as subtype
from vectiles_input.e_301_muu_kolvik_ka
where tyyp = (40)
;

/* AGRICULTURAL */

truncate table vectiles.agricultural restart identity;

/* insert e_303_haritav_maa_a */
insert into vectiles.agricultural (
    geom, originalid, name, type
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    etak_id, null as name,
    case
        when puis = 10 then 'arboriculture'
        else 'agriculture'
    end::vectiles.type_agricultural as type
from vectiles_input.e_303_haritav_maa_a
;

insert into vectiles.agricultural (
    geom, originalid, name, type
)
select
    (st_dump(st_buffer(st_snaptogrid(st_force2d(geom),1), 0))).geom as geom,
    etak_id, null as name,
    'greenhouse'::vectiles.type_agricultural as type
from vectiles_input.e_403_muu_rajatis_ka
where tyyp = 10
;

/* RAILWAYS */

truncate table vectiles.railways restart identity;
/* insert e_502_roobastee_j */

-- splits of rail on top of bridges
with bridges as (select * from vectiles.bridges_for_rails where for_rail = true)
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
with bridges as (select b4r.*, st_buffer(geom, 0.1) as buff_geom from vectiles.bridges_for_roads b4r where b4r.for_road = true)
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

/* BOUNDARIES */

truncate table vectiles.boundaries;

insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    x.geom, null as originalid, x.left_a3, x.right_a3,
    case
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTA'
        when x.left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTA'
        when x.right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'settlement'::vectiles.type_boundaries,
    'settlement.'::vectiles.subtype_boundaries,
    false as on_water
from ehak.baltic_admin x
where x.left_a3 is not null or x.right_a3 is not null
;


insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(st_linemerge(st_collect(x.geom)))).geom, null as originalid,
    x.left_a2, x.right_a2,
    case
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTA'
        when x.left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTA'
        when x.right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'municipality'::vectiles.type_boundaries,
    'municipality.'::vectiles.subtype_boundaries,
    false as on_water
from ehak.baltic_admin x
where coalesce(x.left_a2, '-1') != coalesce(x.right_a2, '-1')
group by x.left_a2, x.right_a2, x.left_country_code, x.right_country_code
;

insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(st_linemerge(st_collect(x.geom)))).geom, null as originalid,
    x.left_a1, x.right_a1,
    case
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTA'
        when x.left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTA'
        when x.right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'province'::vectiles.type_boundaries,
    'province.'::vectiles.subtype_boundaries,
    false as on_water
from ehak.baltic_admin x
where coalesce(x.left_a1, '-1') != coalesce(x.right_a1, '-1')
group by x.left_a1, x.right_a1, x.left_country_code, x.right_country_code
;

insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(st_linemerge(st_collect(x.geom)))).geom,
    null as originalid,
    case
        when x.left_country_code = 'EE' then 'Eesti'
        when x.left_country_code = 'LV' then 'Läti'
        when x.left_country_code = 'LT' then 'Leedu'
        when x.left_country_code = 'RU' then 'Venemaa'
        else null
    end as name_left,
    case
        when x.right_country_code = 'EE' then 'Eesti'
        when x.right_country_code = 'LV' then 'Läti'
        when x.right_country_code = 'LT' then 'Leedu'
        when x.right_country_code = 'RU' then 'Venemaa'
        else null
    end as name_right,
    case
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTA'
        when x.left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTA'
        when x.right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'country'::vectiles.type_boundaries,
    case
        when 'EE' = any(array[left_country_code, right_country_code]) then 'country.domestic'
        else 'country.foreign'
    end::vectiles.subtype_boundaries as subtype,
    false as on_water
from ehak.baltic_admin x
where coalesce(x.left_country_code, '-1') != coalesce(x.right_country_code, '-1')
group by x.left_a1, x.right_a1, x.left_country_code, x.right_country_code
;


insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    geom, null as originalid,
    case
        when tyyp = 'Kontrolljoon maismaal' then 'Venemaa'
        when tyyp = 'Kontrolljoon veekogus' then 'Eesti'
        when tyyp = 'Riigipiir veekogus' then null
    end as name_left,
    case
        when tyyp = 'Kontrolljoon maismaal' then 'Eesti'
        when tyyp = 'Kontrolljoon veekogus' then 'Venemaa'
        when tyyp = 'Riigipiir veekogus' then 'Eesti'
    end as name_right,
    case
        when tyyp = 'Kontrolljoon maismaal' then 'RUS'
        when tyyp = 'Kontrolljoon veekogus' then 'EST'
        when tyyp = 'Riigipiir veekogus' then null
    end as country_left,
    case
        when tyyp = 'Kontrolljoon maismaal' then 'EST'
        when tyyp = 'Kontrolljoon veekogus' then 'RUS'
        when tyyp = 'Riigipiir veekogus' then 'EST'
    end as country_right,
    'country'::vectiles.type_boundaries as type,
    'country.domestic'::vectiles.subtype_boundaries,
    case
        when tyyp like '% veekogus' then true
        else false
    end as on_water
from vectiles.k250_piir
where tyyp != 'Riigipiir maismaal'
;

insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    geom, null as originalid, left_name, right_name,
    case
        when left_country_code = 'EE' then 'EST'
        when left_country_code = 'LV' then 'LVA'
        when left_country_code = 'LT' then 'LTA'
        when left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when right_country_code = 'EE' then 'EST'
        when right_country_code = 'LV' then 'LVA'
        when right_country_code = 'LT' then 'LTA'
        when right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'country'::vectiles.type_boundaries as type,
    'country.foreign'::vectiles.subtype_boundaries,
    on_water
from ehak.baltic_a0_expanded_lines where on_water = true and 'EE' != all(array[coalesce(left_country_code,''), coalesce(right_country_code,'')])
;


/* LABELS */

truncate table vectiles.labels restart identity;


insert into vectiles.labels (
    geom, name, type, subtype, hierarchy
)
select
    (array_agg(st_snaptogrid(st_centroid(geom),1) order by st_area(geom) desc))[1] as geom, name,
    'place'::vectiles.type_labels,
    'place.urban_district'::vectiles.subtype_labels,
    25 as hierarchy
from vectiles_input.informal_district
group by name
;


insert into vectiles.labels (
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    geom, originalid, name, type, subtype,
    case
        when lower(name) in ('tartu', 'narva', 'pärnu') then 150
        when lower(name) in ('viljandi', 'haapsalu', 'kuressaare', 'võru', 'valga', 'rakvere', 'kärdla', 'paide', 'jõgeva', 'põlva', 'rapla') then 100
        when suf = any(array['linn', 'linnaosa']) then 50
        when suf = any(array['alev', 'alevik']) then 25
        else 0
    end as hierarchy,
    0 as rotation
from (
    select
        st_snaptogrid(st_geometricmedian(st_collect(geom)), 1) as geom, 'A3:'||coalesce(tase3_kood, tase2_kood) as originalid,
        replace(coalesce(tase3_nimetus, tase2_nimetus), ' '||f.suf , '') as name,
        f.suf,
       'admin'::vectiles.type_labels as type,
       'admin.settlement'::vectiles.subtype_labels as subtype
    from vectiles_input.ee_address_object, (
        select
            unnest(array['linn', 'alevik', 'alev', 'küla', 'linnaosa']) as suf
        ) f
    where
        coalesce(tase3_nimetus, tase2_nimetus) like '% '||f.suf and
        tase7_kood is not null and
        tase8_kood is null
    group by
        tase3_kood, tase2_kood, tase3_nimetus, tase2_nimetus, suf
) foo
;


insert into vectiles.labels (
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    geom, originalid, name, type, subtype,
    150 as hierarcy,
    0 as rotation
from (
select
     st_snaptogrid(geom, 1) as geom, 'A3:'||tase2_kood as originalid,
     replace(tase2_nimetus, ' linn' , '') as name,
    'admin'::vectiles.type_labels as type,
    'admin.settlement'::vectiles.subtype_labels as subtype
from vectiles_input.ee_address_object
where
    adob_liik = 'OV' and
    tase8_kood is null and tase2_nimetus = any(array['Tallinn', 'Kohtla-Järve linn'])
) foo
;


insert into vectiles.labels (
    geom, originalid, name, type, subtype
)
select
    st_snaptogrid(st_centroid(st_collect(geom)), 1) as geom, 'A2:'||tase2_kood as originalid,
    tase2_nimetus,
    'admin'::vectiles.type_labels,
    'admin.municipality'::vectiles.subtype_labels
from
    vectiles_input.ee_address_object
where
    (tase6_kood is not null or tase7_kood is not null) and
    tase8_kood is null and tase2_nimetus like '% vald'
group by tase2_kood, tase2_nimetus
;

insert into vectiles.labels (
    geom, originalid, name, type, subtype
)
select
    st_snaptogrid(st_centroid(st_collect(geom)), 1) as geom, 'A2:'||tase1_kood as originalid,
    replace(tase1_nimetus, ' maakond', 'maa') as name,
    'admin'::vectiles.type_labels,
    'admin.province'::vectiles.subtype_labels
from
    vectiles_input.ee_address_object
where
    (tase6_kood is not null or tase7_kood is not null) and
    tase8_kood is null
group by tase1_kood, tase1_nimetus
;

insert into vectiles.labels (
    geom, originalid, name, type, subtype, hierarchy
)
select
    st_snaptogrid(st_geometricmedian(st_collect(st_centroid(geom))), 1) as geom, null, nimetus,
    'water'::vectiles.type_labels,
    'water.'::vectiles.subtype_labels,
    case
        when sum(st_area(geom)) > 100000000 then 150
        when sum(st_area(geom)) > 5000000 then 100
        when sum(st_area(geom)) > 100000 then 50
        when sum(st_area(geom)) > 50000 then 25
        else 0
    end as hierarchy
from
    vectiles_input.e_202_seisuveekogu_a
where
    nullif(lower(nimetus), 'nimetu') is not null
group by nimetus
;


--create index idx__e_501_tee_j__ads_oid on vectiles_input.e_501_tee_j using btree (ads_oid);
--create index idx__ee_address_object__adob_liik on vectiles_input.ee_address_object using btree(adob_liik);
--create index idx__ee_address_object__tase5_kood on vectiles_input.ee_address_object using btree(tase5_kood);

drop table if exists vectiles_input.streetlinemerge;
create table vectiles_input.streetlinemerge as
select st_linemerge(st_collect(st_snaptogrid(geom, 1))) as geom, ads_oid
from (
    select (st_dump(st_force2d(geom))).geom as geom, ads_oid
    from vectiles_input.e_501_tee_j
    where ads_oid > '0'
) f
group by ads_oid
;

alter table vectiles_input.streetlinemerge add constraint pk__streetlinemerge primary key (ads_oid);
create index sidx__streetlinemerge__geom on vectiles_input.streetlinemerge using gist (geom);

alter table vectiles_input.streetlinemerge add column a5_code varchar(4);
update vectiles_input.streetlinemerge set
    a5_code = f.tase5_kood
from vectiles_input.ee_address_object f
where
    f.adob_liik = 'LP' and
    f.ads_oid = streetlinemerge.ads_oid
;

create index idx__streetlinemerge_a5_code on vectiles_input.streetlinemerge using btree (a5_code);

delete from vectiles_input.streetlinemerge where a5_code is null;

insert into vectiles.labels (
    geom, originalid, name, type, subtype, rotation
)
select
    ap.geom, ap.ads_oid,
    case
        when right(hn, 1) = any(array['6', '9']) then hn||'.'
        else hn
    end as name,
    'address'::vectiles.type_labels,
    case
        when adob_liik = any(array['EE', 'ME']) then 'address.building'
        when adob_liik = any(array['CU']) then 'address.parcel'
        else null
    end::vectiles.subtype_labels as subtype,
    round(angle::numeric, 0) as angle
from (
    select
        st_snaptogrid(ap.geom,1) as geom,
        coalesce(ap.tase7_nimetus, ap.tase6_nimetus) as hn,
        degrees(st_azimuth(st_closestpoint(s.geom, ap.geom), ap.geom)) as angle,
        --st_makeline(array[st_closestpoint(s.geom, ap.geom), ap.geom]) as line,
        ap.ads_oid, ap.adob_liik
    from vectiles_input.streetlinemerge s, (
        select
            (array_agg(adob_liik order by ord))[1] as adob_liik,
            (array_agg(ads_oid order by ord))[1] as ads_oid,
            tase2_kood, tase3_kood, tase4_kood, tase5_kood, tase7_nimetus, tase6_nimetus,
            (array_agg(geom order by ord))[1] as geom
        from (
            select
                case when adob_liik = 'EE' then 1 when adob_liik = 'ME' then 2 else 3 end as ord, ads_oid,
                adob_liik, tase2_kood, tase3_kood, tase4_kood, tase5_kood, tase7_nimetus, tase6_nimetus, geom
            from vectiles_input.ee_address_object
            where
                adob_liik in ('EE', 'ME', 'CU') and
                tase8_kood is null and (tase6_kood is not null or tase7_kood is not null) and
                geom is not null
        ) f
        group by tase2_kood, tase3_kood, tase4_kood, tase5_kood, tase7_nimetus, tase6_nimetus
    ) ap
    where ap.tase5_kood = s.a5_code
) ap
;

insert into vectiles.labels (
    geom, originalid, name, type, subtype, rotation
)
select ap.geom, ap.ads_oid,
    case
        when right(hn, 1) = any(array['6', '9']) then hn||'.'
        else hn
    end as name,
    'address'::vectiles.type_labels,
    case
        when adob_liik = any(array['EE', 'ME']) then 'address.building'
        when adob_liik = any(array['CU']) then 'address.parcel'
        else null
    end::vectiles.subtype_labels as subtype,
    angle
from (
    select
        st_snaptogrid(ap.geom,1) as geom,
        case
            when ap.tase6_nimetus is not null and ap.tase7_nimetus is not null then ap.lahiaadress
            else coalesce(ap.tase7_nimetus, ap.tase6_nimetus)
        end as hn,
        0 as angle,
        ap.ads_oid as ads_oid, ap.adob_liik
    from (
        select
            (array_agg(adob_liik order by ord))[1] as adob_liik,
            (array_agg(ads_oid order by ord))[1] as ads_oid,
            tase2_kood, tase3_kood, tase4_kood, tase5_kood, tase7_nimetus, tase6_nimetus,
            lahiaadress,
            (array_agg(geom order by ord))[1] as geom
        from (
            select
                case when adob_liik = 'EE' then 1 when adob_liik = 'ME' then 2 else 3 end as ord, ads_oid,
                adob_liik, tase2_kood, tase3_kood, tase4_kood, tase5_kood, tase7_nimetus, tase6_nimetus, geom,
                lahiaadress
            from vectiles_input.ee_address_object
            where
                adob_liik in ('EE', 'ME') and
                tase8_kood is null and (tase6_kood is not null or tase7_kood is not null) and
                geom is not null
        ) f
        group by tase2_kood, tase3_kood, tase4_kood, tase5_kood, tase7_nimetus, tase6_nimetus, lahiaadress
    ) ap
    where
        not exists (
            select s.*
            from vectiles_input.streetlinemerge s
            where ap.tase5_kood = s.a5_code
        ) or ap.tase5_kood is null
) ap
;

insert into vectiles.labels (
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_snaptogrid(foo.geom,1) as geom,
    foo.originalid, foo.name, foo.type, foo.subtype, foo.hierarchy, foo.rotation
from (
    select
        geom, null as originalid, nimetus as name,
        case
            when tyyp = 'Veekogu nimi' and (nimetus like '%raba' or nimetus like '% raba %' or trim(trailing ')' from nimetus) like '%soo') then 'nature'
            when tyyp = 'Veekogu nimi' then 'water'
            when tyyp = 'Loodusnimi' then 'nature'
        end::vectiles.type_labels as type,
        case
            when tyyp = 'Veekogu nimi' and (nimetus like '%raba' or nimetus like '% raba %' or trim(trailing ')' from nimetus) like '%soo') then 'nature.'
            when tyyp = 'Veekogu nimi' then 'water.'
            when tyyp = 'Loodusnimi' then 'nature.'
        end::vectiles.subtype_labels as subtype,
        0::int as hierarchy,
        0 as rotation
    from vectiles_input.k250_kohanimi
    where
        tyyp = any(array['Veekogu nimi', 'Loodusnimi'])
) foo
where
    not exists (
        select l.*
        from vectiles.labels l
        where
            l.name = foo.name and
            l.type = foo.type and
            l.subtype = foo.subtype and
            l.type::text=any(array['nature', 'water'])
        )
;
