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
