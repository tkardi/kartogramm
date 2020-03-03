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


/* Z_LOW_WATER */

truncate table vectiles.z_low_water restart identity;

insert into vectiles.z_low_water(
    geom, originalid, name, type
)
select
    st_transform((st_dump(st_union(ring))).geom, 4326) as geom, null as originalid, name, type
from (
    select
        (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 1000))).geom as ring,
        nimetus as name,
        case
            when tyyp = 'Seisuveekogu' then 'lake'
            when tyyp = 'Vooluveekogu' then 'water_way'
        end::vectiles.type_water as type
    from vectiles_input.k250_kolvik
    where
        tyyp = any(array['Vooluveekogu', 'Seisuveekogu']) and
        nullif(nimetus, 'nimetu') is not null
) foo
where
    st_area(foo.ring) > 10000000
group by
    name, type
;

insert into vectiles.z_low_water(
    geom, originalid, name, type
)
select
    (st_dump(st_union(ring))).geom as geom, null as originalid, name, type
from (
    select
        (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 0.00001))).geom as ring,
        name,
        'lake'::vectiles.type_water as type
    from
        vectiles_input.lv_water
    where
        fclass in ('reservoir','water') and
        name like '%ezers'
) foo
where
    st_area(foo.ring, true) > 10000000
group by
    name, type
;

insert into vectiles.z_low_water(
    geom, originalid, name, type
)
select
    (st_dump(st_buildarea(st_collect(ring)))).geom as geom, null as originalid, name, type
from (
    select
        oid, (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 0.00001))).geom as ring,
        null as etak_id, null as name,
        'sea'::vectiles.type_water as type
    from
        vectiles_input.oceans
) foo
where
    st_area(foo.ring, true) > 10000000
group by
    oid, name, type
;

insert into vectiles.z_low_water(
    geom, originalid, name, type
)
select
    (st_dump(geom)).geom, null as originalid, name,
    'lake'::vectiles.type_water as type
from
    vectiles_input.ne_10m_lakes
where
    st_area(geom, true)> 1000000 and
    name not in ('Lake Peipus', 'Võrtsjärv', 'Pskoyskoye Ozero')
union all
select
    (st_dump(geom)).geom, null as originalid, name,
    'lake'::vectiles.type_water as type
from
    vectiles_input.ne_10m_lakes_europe
where
    st_area(geom, true)> 100000 and
    name not in ('Lake Peipus', 'Võrtsjärv', 'Pskoyskoye Ozero', 'Lake Usma', 'Engure', 'Babīte Ezers', 'Pljavinjas')
;


/* Z_LOW_BUILTUP */

truncate table vectiles.z_low_builtup restart identity;

insert into vectiles.z_low_builtup (
    geom, originalid, name, type, subtype
)
select
    (st_dump(geom)).geom, null as originalid, null as name,
    'area'::vectiles.type_builtup as type,
    'area.'::vectiles.subtype_builtup as subtype
from
    vectiles_input.ne_10m_urban_areas
where
    st_area(geom, true)> 10000
;


/* Z_LOW_RAILWAYS */

truncate table vectiles.z_low_railways restart identity;

insert into vectiles.z_low_railways (
    geom, originalid, name,
    type, subtype, class,
    tunnel, bridge
)
select
    geom, null as originalid, null as name,
    'rail'::vectiles.type_railways as type,
    case
        when category = 1 then 'rail.large_gauge'
        else 'rail.narrow_gauge'
    end::vectiles.subtype_railways as subtype,
    'main'::vectiles.class_railways as class,
    false as tunnel, false as bridge
from vectiles_input.ne_10m_railroads
where disp_scale in( '1:40m','1:20m','1:10m')
;

/* Z_LOW_ROADS */

truncate table vectiles.z_low_roads restart identity;

/* k250_tee */
insert into vectiles.z_low_roads (
    geom, originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    st_transform((st_dump(st_linemerge(st_collect(st_simplifypreservetopology(geom, 100000))))).geom, 4326) as geom, null as originalid, nimetus,
    'highway'::vectiles.type_roads as type,
    'permanent'::vectiles.class_roads as class, false as tunnel, false as bridge,
    false as oneway, tee_nr as road_number, 0 as relative_height
from vectiles_input.k250_tee
where tyyp = 'Põhimaantee'
group by nimetus, tee_nr, tyyp
;

/* OSM roads from lv_roads */
insert into vectiles.z_low_roads (
    geom, originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    (st_dump(st_linemerge(st_collect(st_simplifypreservetopology(geom, 0.00001))))).geom as geom, null as originalid, name,
    'highway'::vectiles.type_roads as type,
    'permanent'::vectiles.class_roads as class, false as tunnel, false as bridge,
    false as oneway, ref as road_number, 0 as relative_height
from vectiles_input.lv_roads
where fclass = 'trunk'
group by name, ref, fclass
;


/* Z_LOW_BOUNDARIES */

truncate table vectiles.z_low_boundaries restart identity;

with trans as (
    select * from json_to_recordset('[
       {"en":"Austria","ee":"Austria"},
       {"en":"Belarus","ee":"Valgevene"},
       {"en":"Belgium","ee":"Belgia"},
       {"en":"Bosnia and Herzegovina","ee":"Bosnia ja Hertsegoviina"},
       {"en":"Croatia","ee":"Horvaatia"},
       {"en":"Czech Republic","ee":"Tšehhi"},
       {"en":"Denmark","ee":"Taani"},
       {"en":"Estonia","ee":"Eesti"},
       {"en":"Finland","ee":"Soome"},
       {"en":"France","ee":"Prantsusmaa"},
       {"en":"Germany","ee":"Saksamaa"},
       {"en":"Hungary","ee":"Ungari"},
       {"en":"Italy","ee":"Itaalia"},
       {"en":"Latvia","ee":"Läti"},
       {"en":"Liechtenstein","ee":"Lihtenstein"},
       {"en":"Lithuania","ee":"Leedu"},
       {"en":"Luxembourg","ee":"Luksemburg"},
       {"en":"Moldova","ee":"Moldova"},
       {"en":"Netherlands","ee":"Holland"},
       {"en":"Norway","ee":"Norra"},
       {"en":"Poland","ee":"Poola"},
       {"en":"Republic of Serbia","ee":"Serbia"},
       {"en":"Romania","ee":"Rumeenia"},
       {"en":"Russia","ee":"Venemaa"},
       {"en":"Slovakia","ee":"Slovakkia"},
       {"en":"Slovenia","ee":"Sloveenia"},
       {"en":"Sweden","ee":"Rootsi"},
       {"en":"Switzerland","ee":"Šveits"},
       {"en":"Ukraine","ee":"Ukraina"}
]') as x(en text, ee text)
)
insert into vectiles.z_low_boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(geom)).geom, null as originalid, l.ee, r.ee, adm0_a3_l, adm0_a3_r,
    'country'::vectiles.type_boundaries as type,
    case
        when 'EST' = any(array[adm0_a3_l, adm0_a3_r]) then 'country.domestic'
        else 'country.foreign'
    end::vectiles.subtype_boundaries as subtype,
    false as on_water
from
    vectiles_input.ne_10m_admin_0_boundary_lines_land lines
        left join trans l on
            l.en = lines.adm0_left
        left join trans r on
            r.en = lines.adm0_right
;

/* Z_LOW_LABELS */

truncate table vectiles.z_low_labels restart identity;

with trans as (
    select * from json_to_recordset('[
       {"en":"Austria","ee":"Austria"},
       {"en":"Belarus","ee":"Valgevene"},
       {"en":"Belgium","ee":"Belgia"},
       {"en":"Bosnia and Herzegovina","ee":"Bosnia ja Hertsegoviina"},
       {"en":"Croatia","ee":"Horvaatia"},
       {"en":"Czech Republic","ee":"Tšehhi"},
       {"en":"Czechia","ee":"Tšehhi"},
       {"en":"Denmark","ee":"Taani"},
       {"en":"Estonia","ee":"Eesti"},
       {"en":"Finland","ee":"Soome"},
       {"en":"France","ee":"Prantsusmaa"},
       {"en":"Germany","ee":"Saksamaa"},
       {"en":"Hungary","ee":"Ungari"},
       {"en":"Italy","ee":"Itaalia"},
       {"en":"Latvia","ee":"Läti"},
       {"en":"Liechtenstein","ee":"Lihtenstein"},
       {"en":"Lithuania","ee":"Leedu"},
       {"en":"Luxembourg","ee":"Luksemburg"},
       {"en":"Moldova","ee":"Moldova"},
       {"en":"Netherlands","ee":"Holland"},
       {"en":"Norway","ee":"Norra"},
       {"en":"Poland","ee":"Poola"},
       {"en":"Republic of Serbia","ee":"Serbia"},
       {"en":"Romania","ee":"Rumeenia"},
       {"en":"Russia","ee":"Venemaa"},
       {"en":"Slovakia","ee":"Slovakkia"},
       {"en":"Slovenia","ee":"Sloveenia"},
       {"en":"Sweden","ee":"Rootsi"},
       {"en":"Switzerland","ee":"Šveits"},
       {"en":"Ukraine","ee":"Ukraina"}
]') as x(en text, ee text)
)
insert into vectiles.z_low_labels(
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select st_geometricmedian(st_collect(st_centroid(geom))) as geom, null as originalid, trans.ee as name,
    'admin'::vectiles.type_labels as type,
    case when trans.ee = 'Eesti' then 'admin.country.domestic' else 'admin.country.foreign' end::vectiles.subtype_labels as subtype,
    case when trans.ee = any(array['Rootsi', 'Soome', 'Eesti', 'Läti', 'Leedu', 'Venemaa']) then 100 else 0 end as hierarchy,
    0 as rotation
from
    vectiles_input.ne_10m_admin_0_countries a, trans where trans.en = a.admin
group by trans.ee
;


insert into vectiles.z_low_labels(
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    geom, null as originalid,
	  case
		    when iso_a2='AT' then name_de
		    when iso_a2='AX' then name_en
		    when iso_a2='BE' then name_fr
		    when iso_a2='BY' then name_ru
		    when iso_a2='CH' then name_en
	    	when iso_a2='CZ' then name_en
		    when iso_a2='DE' then name_de
		    when iso_a2='DK' then name_en
		    when iso_a2='EE' then name_en
		    when iso_a2='FI' then name_en
        when iso_a2='GB' then name_en
		    when iso_a2='FR' then name_fr
		    when iso_a2='HR' then name_en
		    when iso_a2='HU' then name_hu
		    when iso_a2='IT' then name_it
		    when iso_a2='LI' then name_en
		    when iso_a2='LT' then name_en
		    when iso_a2='LU' then name_en
		    when iso_a2='LV' then name_en
		    when iso_a2='MD' then name_en
		    when iso_a2='NL' then name_nl
		    when iso_a2='NO' then name_en
		    when iso_a2='PL' then name_pl
		    when iso_a2='RO' then name_en
		    when iso_a2='RS' then name_en
		    when iso_a2='RU' then name_ru
		    when iso_a2='SE' then name_en
		    when iso_a2='SI' then name_en
    		when iso_a2='SK' then name_en
		    when iso_a2='UA' then name_ru
	  end as name,
    'place'::vectiles.type_labels,
    'place.settlement'::vectiles.subtype_labels,
    case
        when megacity = 1 or worldcity = 1 then 100
        when name = any(array['Tallinn', 'Helsinki', 'Riga', 'Tartu', 'Vilnius']) then 100
        else 0
    end as hierarchy,
    0 as rotation
from
    vectiles_input.ne_10m_populated_places
;


insert into vectiles.z_low_labels(
        geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_transform(st_centroid((st_dump(st_union(ring))).geom), 4326) as geom, null as originalid, name, type, subtype, 0 as hierarchy, 0 as rotation
from (
select
    (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 1000))).geom as ring,
    nimetus as name,
    'water'::vectiles.type_labels as type,
    'water.'::vectiles.subtype_labels as subtype
from vectiles_input.k250_kolvik
where tyyp = any(array['Seisuveekogu']) and nullif(nimetus, 'nimetu') is not null
) foo
where st_area(foo.ring) > 10000000
group by name, type, subtype
;


insert into vectiles.z_low_labels(
        geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_centroid((st_dump(st_union(ring))).geom) as geom, null as originalid,
    name, type, subtype, 0 as hierarchy, 0 as rotation
from (
    select
        (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 0.00001))).geom as ring,
        name,
        'water'::vectiles.type_labels as type,
        'water.'::vectiles.subtype_labels as subtype
    from vectiles_input.lv_water
    where
        fclass in ('reservoir','water') and name like '%ezers'
) foo
where
    st_area(foo.ring, true) > 10000000
group by
    name, type, subtype
;



insert into vectiles.z_low_labels(
        geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_geometricmedian(st_collect(st_centroid(geom))) as geom,
    null as originalid, name, type, subtype, 0 as hierarchy, 0 as rotation
from (
    select
        (st_dump(geom)).geom, name,
        'water'::vectiles.type_labels as type,
        'water.'::vectiles.subtype_labels as subtype
    from
        vectiles_input.ne_10m_lakes
    where
        st_area(geom, true)> 1000000 and
        name not in ('Lake Peipus', 'Võrtsjärv', 'Pskoyskoye Ozero')
    union all
    select
        (st_dump(geom)).geom, name,
        'water'::vectiles.type_labels as type,
        'water.'::vectiles.subtype_labels as subtype
    from
        vectiles_input.ne_10m_lakes_europe
    where
        st_area(geom, true)> 100000 and
        name not in ('Lake Peipus', 'Võrtsjärv', 'Pskoyskoye Ozero', 'Lake Usma', 'Engure', 'Babīte Ezers', 'Pljavinjas')
) foo
group by
    name, type, subtype
;
