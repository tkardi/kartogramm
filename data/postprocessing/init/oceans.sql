drop table if exists vectiles_input.sea;

create table vectiles_input.sea as
select st_force2d(st_union(geom)) as geom
from vectiles_input.e_201_meri_a;


update vectiles_input.oceans set
    geom = f.geom
from (
    select o.oid, st_force2d(st_difference(o.geom, st_transform(a.geom, 4326))) as geom
    from vectiles_input.oceans o
        join lateral (
            select st_union(a.geom) geom
            from vectiles_input.sea a
            where st_intersects(a.geom, st_transform(o.geom,3301))
        ) a on true
	) f
where f.geom is not null and f.oid = oceans.oid
;
