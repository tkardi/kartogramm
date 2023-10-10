/* WATER */

truncate table vectiles.water restart identity;

/* processing e_203_vooluveekogu_a */
drop table if exists vectiles.tmp_water;
create table vectiles.tmp_water as
select st_buffer(st_snaptogrid((st_dump(st_union(st_force2d(geom)))).geom, 0.1),0) as geom, nimetus as name
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
select st_subdivide((st_dump(st_union(geom))).geom, 512) as geom, name, 'water_way'::vectiles.type_water
from vectiles.tmp_water
group by name
;

insert into vectiles.water(
    geom, originalid, name, type
)
select
    st_subdivide(st_buffer(st_snaptogrid(st_transform((st_dump((geom))).geom, 3301), 0.1), 0), 512) as geom,
    null as etak_id, null as name,
    'sea'::vectiles.type_water
from vectiles_input.oceans
;

insert into vectiles.water(
    geom, originalid, name, type
)
select
    st_subdivide(st_buffer(st_snaptogrid(st_transform((st_dump((geom))).geom, 3301), 0.1), 0), 512) as geom,
    null as etak_id, null as name,
    'sea'::vectiles.type_water
from vectiles_input.sea
;

insert into vectiles.water(
    geom, name, type
)
select
    st_subdivide((st_dump(st_buffer(st_snaptogrid(st_force2d(geom), 0.1), 0))).geom, 512) as geom,
    nimetus as name, 'lake'::vectiles.type_water
from vectiles_input.e_202_seisuveekogu_a
;

drop table if exists vectiles.tmp_water;
