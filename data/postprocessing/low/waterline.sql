/* Z_LOW_WATERLINE */

truncate table vectiles.z_low_waterline restart identity;

/* k250_vooluvesi */
insert into vectiles.z_low_waterline(
    geom, originalid, name, type, class, underground
)
select
    st_transform((st_dump(foo.geom)).geom, 4326) as geom, foo.originalid, foo.name,
    foo.type, foo.class, foo.underground
from (
select
    st_linemerge(st_collect(bar.geom)) as geom, null as originalid,
    name, type, class, false as underground
from (
	select
	    (st_dump(st_linemerge(st_collect(st_simplifypreservetopology(geom, 5000))))).geom,
	    name, type, class
	from (
	    select
	        (st_dump(geom)).geom,
	        nimetus as name,
	        '12m'::vectiles.type_waterline as type,
	        'river'::vectiles.class_waterline as class
	    from
	        vectiles_input.k250_vooluvesi d left join (
	            select round(avg(laius),-1) as laius, kkr_kood
	            from vectiles_input.e_203_vooluveekogu_j
	            where kkr_kood is not null and laius != 60
	            group by kkr_kood
	        ) w on d.kkr_kood = w.kkr_kood
	    where d.tyyp = 'Jõgi' and w.laius = 50
	    ) foo
	group by name, type, class
	) bar
	where st_length(bar.geom) > 20000
	group by name, type, class
) foo
where st_length(foo.geom) > 60000
;

/* OSM waterways from lv_waterways */
insert into vectiles.z_low_waterline(
    geom, originalid, name, type, class, underground
)
select
    (st_dump(foo.geom)).geom as geom, foo.originalid, foo.name,
    foo.type, foo.class, foo.underground
from (
    select
        st_linemerge(st_collect(bar.geom)) as geom, null as originalid,
        name, type, class, false as underground
    from (
        select
            (st_dump(st_linemerge(st_collect(st_simplifypreservetopology(geom, 0.0001))))).geom as geom,
            null as originalid, (string_to_array(name, ' / '))[1] as name,
            '12m'::vectiles.type_waterline as type,
            'river'::vectiles.class_waterline as class
        from vectiles_input.lv_waterways
        where fclass = 'river' and name is not null
        group by (string_to_array(name, ' / '))[1]
    )bar
    group by name, type, class
) foo
where st_length(foo.geom, true) > 100000
;
