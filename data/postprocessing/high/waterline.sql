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
