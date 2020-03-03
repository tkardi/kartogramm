/* Z_MED_WATERLINE */

truncate table vectiles.z_med_waterline restart identity;

/* EE waterline from k250_vooluvesi */
insert into vectiles.z_med_waterline(
    geom, originalid, name, type, class, underground
)
select
    st_transform((st_dump(st_linemerge(st_collect(geom)))).geom, 4326) as geom,
    null as originalid,
    name, type, class, false as underground
from (
    select
        (st_dump(geom)).geom,
        nimetus as name,
        case
            when w.laius=10 then '1m'
            when w.laius=20 then '3m'
            when w.laius=30 then '6m'
            when w.laius=40 then '8m'
            when w.laius=50 then '12m'
            else '1m'
        end::vectiles.type_waterline as type,
        case
            when tyyp='Jõgi' then 'river' --etak: tyyp=10
            when tyyp='Kanal' then 'channel' --etak: tyyp=20
            when tyyp='Oja' then 'stream' --etak: tyyp=30
            when tyyp='Peakraav' then 'mainditch' --etak: tyyp=40
            when tyyp='Kraav' then 'ditch' --etak: tyyp=50
        end::vectiles.class_waterline as class
    from
        vectiles_input.k250_vooluvesi d left join (
            select round(avg(laius),-1) as laius, kkr_kood
            from vectiles_input.e_203_vooluveekogu_j
            where kkr_kood is not null and laius != 60
            group by kkr_kood
        ) w on d.kkr_kood = w.kkr_kood
    ) foo
group by name, type, class
;

/* LV waterline from lv_waterways */
insert into vectiles.z_med_waterline(
    geom, originalid,
    name, type, class, underground
)
select
    (st_dump(st_linemerge(st_collect(f.geom)))).geom as geom, null as originalid,
    f.name, f.type, f.class, false as underground
from (
    select
        f.*,
        case
            when (string_to_array(f.name, ' / '))[1] = any(
                array['Gauja', 'Daugava', 'Ogre', 'Venta', 'Iecava', 'Pededze',
                    'Abava', 'Lielupe', 'Rēzekne', 'Mēmele', 'Aiviekste',
                    'Bērze', 'Dubna' ]
                ) then '12m'
            when w.w >= 16 then '12m'
            when w.w = 6 then '8m'
            when w.w = 5 then '6m'
            when w.w = 4 then '3m'
            when w.w = 3 then '3m'
            when w.w = 2 then '1m'
            when f.name is not null then '8m'
            else '1m'
        end::vectiles.type_waterline as type,
        case
            when fclass='river' then 'river'
            when fclass='canal' then 'channel'
            when fclass='strem' then 'stream'
            when fclass='drain' then 'ditch'
            when f.name is not null then 'river'
            else 'stream'
        end::vectiles.class_waterline as class
    from
        vectiles_input.lv_waterways f left join
            (
                select
                    max(width) as w, name
                from
                    vectiles.lv_waterways
                where
                    fclass = 'river' and
                    name is not null and
                    width > 0
                group by
                    name
            ) w on
                f.name = w.name
    where
        f.fclass != 'drain'
) f
group by
    name, type, class
;


/* Z_MED_WATER */

truncate table vectiles.z_med_water restart identity;

insert into vectiles.z_med_water(
    geom, originalid, name, type
)
select
    (st_dump((geom))).geom as geom,
    null as etak_id, null as name,
    'sea'::vectiles.type_water
from vectiles_input.oceans
;

insert into vectiles.z_med_water(
    geom, originalid, name, type
)
select
    st_transform((st_dump((geom))).geom, 4326) as geom,
    null as etak_id, nimetus as name,
    case
        when tyyp = 'Seisuveekogu' then 'lake'
        when tyyp = 'Vooluveekogu' then 'water_way'
    end::vectiles.type_water as type
from
    vectiles_input.k250_kolvik
where
    tyyp = any(array['Vooluveekogu', 'Seisuveekogu'])
;


select
    (st_dump(st_union(ring))).geom as geom, null as originalid, name, type
from
    (
        select
            (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 0.00001))).geom as ring,
            name,
            'lake'::vectiles.type_water as type
        from
            vectiles_input.lv_water
        where
            fclass in ('reservoir', 'water') and
            (lower((string_to_array(name, ' / '))[1]) like '%ezers' or lower((string_to_array(name, ' / '))[1]) like 'ez. %')
    ) foo
where
    st_area(foo.ring, true) > 250000
group by
    name, type
;


insert into vectiles.z_med_water(
    geom, originalid, name, type
)
select
    (st_dump(st_union(st_buffer(ring, 0.00005)))).geom as geom, null as originalid, name, type
from (
    select
        w.gid, foo.gids,
        (st_dumprings(
            st_simplifypreservetopology(
                (st_dump(st_union(array[foo.geom, coalesce(w.geom, foo.geom)]))).geom,
                0.00001
            )
        )).geom as ring,
        foo.name as name,
        case
            when foo.name = any(
                array['Gauja', 'Daugava', 'Ogre', 'Venta', 'Iecava', 'Pededze',
                    'Abava', 'Lielupe', 'Rēzekne', 'Mēmele', 'Aiviekste',
                    'Bērze', 'Dubna' ]
            ) then 'water_way'
            else 'lake'
        end::vectiles.type_water as type
    from (
        select
            array_agg(gid) as gids, (string_to_array(name, ' / '))[1] as name, st_union(geom) as geom
        from
            vectiles_input.lv_water
        where
            (
                (
                    "fclass" not in ('wetland', 'river') and
                    st_area(geom, true) > 250000 and
                    lower((string_to_array(coalesce(name, 'a'), ' / '))[1]) not like '%ezers' and
                    lower((string_to_array(coalesce(name, 'a'), ' / '))[1]) not like 'ez. %'
                ) or
                    (string_to_array(name, ' / '))[1] = any(
                        array['Gauja', 'Daugava', 'Ogre', 'Venta', 'Iecava', 'Pededze',
                            'Abava', 'Lielupe', 'Rēzekne', 'Mēmele', 'Aiviekste',
                            'Bērze', 'Dubna' ]
                    )
            ) and
            name is not null
        group by
            (string_to_array(name, ' / '))[1]
    ) foo
        left join vectiles_input.lv_water w on
            st_intersects(w.geom, foo.geom) and
            w.name is null and
            w.gid != all(foo.gids) and
            w.fclass not in ('wetland')
) f
group by
    name, type
;


/* Z_MED_NATURAL */

truncate table vectiles.z_med_natural restart identity;

insert into vectiles.z_med_natural (
    geom, originalid, name, type, subtype
)
select
    st_transform(st_simplifypreservetopology((st_dump(st_makevalid(geom))).geom, 0.00001), 4326), null as originalid, null as name,
    case
        when tyyp = 'Lage ala' then 'low'
        when tyyp = 'Märgala' then 'bare'
        when tyyp = 'Mets ja põõsastik' then 'high'
    end::vectiles.type_natural as type,
    case
        when tyyp = 'Lage ala' then 'low.grass'
        when tyyp = 'Märgala' then 'bare.wet'
        when tyyp = 'Mets ja põõsastik' then 'high.mixed'
    end::vectiles.subtype_natural as subtype
from
    vectiles_input.k250_kolvik
where
    tyyp = any(array['Lage ala', 'Märgala', 'Mets ja põõsastik'])
;


/* Z_MED_BUILTUP */

truncate table vectiles.z_med_builtup restart identity;

insert into vectiles.z_med_builtup (
    geom,
    originalid, name, type, subtype
)
select
    st_transform(st_simplifypreservetopology((st_dump(st_makevalid(geom))).geom, 0.00001), 4326) as geom,
    null as originalid, nimetus as name,
    'area'::vectiles.type_builtup as type,
    'area.'::vectiles.subtype_builtup as subtype
from
    vectiles_input.k250_kolvik
where
    tyyp = 'Asustus'
;

insert into vectiles.z_med_builtup (
    geom, originalid, name, type, subtype
)
select
    st_simplifypreservetopology((st_dump(st_union(geom))).geom, 0.00001) as geom,
    null as originalid, null as name, type, subtype
from (
    select
        geom as geom,
        'area'::vectiles.type_builtup as type,
        'area.'::vectiles.subtype_builtup as subtype
    from
        vectiles_input.lv_landuse
    where
        fclass = any(array['cemetary', 'commercial', 'industrial', 'quarry', 'recreation_ground', 'residential', 'retail'])
) foo
group by
    type, subtype
;


/* Z_MED_RAILWAYS */


truncate table vectiles.z_med_railways restart identity;

/* k250_roobastee */

insert into vectiles.z_med_railways (
    geom, originalid, name,
    type, subtype, class,
    tunnel, bridge
)
select
    st_transform((st_dump(geom)).geom, 4326) as geom, null as originalid, null as name,
    'rail'::vectiles.type_railways as type,
    'rail.large_gauge'::vectiles.subtype_railways as subtype,
    'main'::vectiles.class_railways,
    false as tunnel, false as bridge
from
    vectiles_input.k250_roobastee
;

insert into vectiles.z_med_railways (
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
from vectiles_input.lv_railways
where disp_scale in( '1:40m','1:20m','1:10m')
;


/* Z_MED_ROADS */


truncate table vectiles.z_med_roads restart identity;

/* k250_tee */
insert into vectiles.z_med_roads (
    geom, originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    st_transform((st_dump(geom)).geom, 4326) as geom, null, nimetus,
    case
        when tyyp = 'Põhimaantee' then 'highway' --põhimaantee
        when tyyp = 'Tugimaantee' then 'main'  --tugimaantee
        when tyyp = 'Kõrvalmaantee' then 'secondary' -- kõrvalmaantee,
        when tyyp = 'Ramp või ühendustee' then 'secondary' --ramp või ühendustee
        when tyyp = 'Tänav' then 'local' --tänav,
        when tyyp = 'Muu tee' then 'local' --muu tee
    end::vectiles.type_roads as type,
    'permanent'::vectiles.class_roads as class, false as tunnel, false as bridge,
    false as oneway, tee_nr as road_number, 0 as relative_height
from
    vectiles_input.k250_tee
;


insert into vectiles.z_med_roads (
    geom, originalid, name,
    type, class, tunnel, bridge,
    oneway, road_number, relative_height
)
select
    case
        when oneway='T' then st_reverse(geom)
        else geom
    end as geom, null as originalid, name,
    case
        when fclass = any(array['trunk', 'trunk_link']) then 'highway'
        when fclass = any(array['primary', 'primary_link']) then 'main'
        when fclass = any(array['secondary', 'secondary_link']) then 'secondary'
        when fclass = any(array['tertiary', 'tertiary_link']) then 'local'
    end::vectiles.type_roads as type,
    'permanent'::vectiles.class_roads as class,
    case
        when tunnel = 'F' then false
        else true
    end as tunnel,
    case
        when bridge = 'F' then false
        else true
    end as bridge,
    case
        when oneway=any(array['T','F']) then true
        else false
    end as oneway,
    ref as road_number, 0 as relative_height
from
    vectiles_input.lv_roads
where
    fclass = any(
        array['primary','secondary','trunk','primary_link',
            'secondary_link','tertiary','tertiary_link','trunk_link']
    )
;


/* Z_MED_BOUNDARIES */

truncate table vectiles.z_med_boundaries restart identity;

insert into vectiles.z_med_boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    st_transform((st_dump(st_linemerge(st_collect(x.geom)))).geom, 4326) as geom,
    null as originalid,
    x.left_a2, x.right_a2,
    case
        when x.left_country_code = 'RU' then 'RUS'
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTU'
		else null
    end as country_left,
    case
        when x.right_country_code = 'RU' then 'RUS'
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTU'
		else null
    end as country_right,
    'municipality'::vectiles.type_boundaries,
    'municipality.'::vectiles.subtype_boundaries,
    false as on_water
from
    vectiles_input.baltic_admin x
where
    coalesce(x.left_a2, '-1') != coalesce(x.right_a2, '-1')
group by
    x.left_a2, x.right_a2, x.left_country_code, x.right_country_code
;

insert into vectiles.z_med_boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    st_transform((st_dump(st_linemerge(st_collect(x.geom)))).geom, 4326) as geom,
    null as originalid,
    x.left_a1, x.right_a1,
    case
        when x.left_country_code = 'RU' then 'RUS'
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTU'
        else null
    end as country_left,
    case
        when x.right_country_code = 'RU' then 'RUS'
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTU'
        else null
    end as country_right,
    'province'::vectiles.type_boundaries,
    'province.'::vectiles.subtype_boundaries,
    false as on_water
from
    vectiles_input.baltic_admin x
where
    coalesce(x.left_a1, '-1') != coalesce(x.right_a1, '-1')
group by
    x.left_a1, x.right_a1, x.left_country_code, x.right_country_code
;

insert into vectiles.z_med_boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    st_transform((st_dump(st_linemerge(st_collect(x.geom)))).geom, 4326) as geom,
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
        when x.left_country_code = 'RU' then 'RUS'
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTU'
		else null
    end as country_left,
    case
        when x.right_country_code = 'RU' then 'RUS'
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTU'
		else null
    end as country_right,
    'country'::vectiles.type_boundaries,
    case
        when 'EE' = any(array[left_country_code, right_country_code]) then 'country.domestic'
        else 'country.foreign'
    end::vectiles.subtype_boundaries as subtype,
    false as on_water
from
    vectiles_input.baltic_admin x
where
    coalesce(x.left_country_code, '-1') != coalesce(x.right_country_code, '-1')
group by
    x.left_a1, x.right_a1, x.left_country_code, x.right_country_code
;


insert into vectiles.z_med_boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    st_transform((st_dump(st_linemerge(st_collect(geom)))).geom, 4326) as geom, null as originalid,
    left_name as name_left,
    right_name as name_right,
    case
        when left_country_code = 'RU' then 'RUS'
        when left_country_code = 'EE' then 'EST'
        when left_country_code = 'LV' then 'LVA'
        when left_country_code = 'LT' then 'LTU'
		else null
    end as country_left,
    case
        when right_country_code = 'RU' then 'RUS'
        when right_country_code = 'EE' then 'EST'
        when right_country_code = 'LV' then 'LVA'
        when right_country_code = 'LT' then 'LTU'
		else null
    end as country_right,
    'country'::vectiles.type_boundaries as type,
    case
        when 'EE' = any(array[left_country_code, right_country_code]) then 'country.domestic'
        else 'country.foreign'
    end::vectiles.subtype_boundaries as subtype,
    on_water
from
    vectiles_input.baltic_a0_expanded
group by
    left_name, right_name, left_country_code, right_country_code, on_water
;


/* Z_MED_LABELS */

truncate table vectiles.z_med_labels restart identity;

insert into vectiles.z_med_labels (
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_transform(geom, 4326) as geom, null as originalid, nimetus,
    case
        when tyyp = 'Veekogu nimi' and (nimetus like '%raba' or nimetus like '% raba %' or trim(trailing ')' from nimetus) like '%soo') then 'nature'
        when tyyp = 'Veekogu nimi' then 'water'
        when tyyp = 'Loodusnimi' then 'nature'
    end::vectiles.type_labels as type,
    case
        when tyyp = 'Veekogu nimi' and (nimetus like '%raba' or nimetus like '%soo') then 'nature.'
        when tyyp = 'Veekogu nimi' then 'water.'
        when tyyp = 'Loodusnimi' then 'nature.'
    end::vectiles.subtype_labels as subtype,
    0 as hierarchy,
    0 as rotation
from vectiles_input.k250_kohanimi
where tyyp = any(array['Veekogu nimi', 'Loodusnimi'])
;


insert into vectiles.z_med_labels (
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_transform(st_pointonsurface(geom), 4326) as geom, null as originalid, nimetus,
    'water'::vectiles.type_labels as type,
    'water.'::vectiles.subtype_labels as subtype,
    case
        when tyyp = 'Meri' then 100
        else 0
    end as hierarchy,
    0 as roatation
from vectiles_input.k250_kolvik
where
    nullif(nimetus, 'nimetu') is not null and
    tyyp != 'Vooluveekogu'
;


insert into vectiles.z_med_labels (
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_transform(geom, 4326) as geom, null as originalid, initcap(nimetus) as name,
    'admin'::vectiles.type_labels as type,
    'admin.settlement'::vectiles.subtype_labels as subtype,
    case
        when nimetus in ('TALLINN', 'TARTU', 'NARVA', 'PÄRNU') then 150
        when nimetus in ('VILJANDI', 'HAAPSALU', 'KURESSAARE', 'VÕRU', 'VALGA', 'RAKVERE', 'KÄRDLA', 'PAIDE', 'JÕGEVA', 'PÕLVA', 'RAPLA') then 100
        when nimetus = upper(nimetus) then 50
        else 0
    end as hierarchy,
    0 as rotation
from vectiles_input.k250_kohanimi
where tyyp = 'Asustusüksus'
;


insert into vectiles.z_med_labels (
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_transform(st_geometricmedian(st_collect(geom)), 4326) as geom,
    'A1:'||tase1_kood, tase1_nimetus,
    'admin'::vectiles.type_labels,
    'admin.province'::vectiles.subtype_labels,
    0 as hierarchy,
    0 as rotation
from
    vectiles_input.ee_address_object
where
    (tase7_kood is not null or tase6_kood is not null) and
    adob_liik = any(array['EE', 'ME', 'CU'])
group by
    tase1_kood, tase1_nimetus
;


insert into vectiles.z_med_labels(
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_pointonsurface((st_dump(st_union(ring))).geom) as geom, null as originalid, name, type, subtype,
    0 as hierarcy,
    0 as rotation
from (
    select
        (st_dumprings(st_simplifypreservetopology((st_dump((geom))).geom, 0.00001))).geom as ring,
        name,
        'water'::vectiles.type_labels as type,
        'water.'::vectiles.subtype_labels as subtype
    from
        vectiles_input.lv_water
    where
        fclass in ('reservoir', 'water') and
        (lower((string_to_array(name, ' / '))[1]) like '%ezers' or lower((string_to_array(name, ' / '))[1]) like 'ez. %')
) foo
where
    st_area(foo.ring, true) > 250000
group by
    name, type, subtype
;


insert into vectiles.z_med_labels(
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select
    st_pointonsurface((st_dump(st_union(geom))).geom) as geom, null as originalid, name, type, subtype,
    0 as hierarcy,
    0 as rotation
from (
    select
        (st_dump(st_union(st_buffer(ring, 0.00005)))).geom as geom, null as originalid, name,
        'water'::vectiles.type_labels as type,
        'water.'::vectiles.subtype_labels as subtype
    from (
        select
            w.gid, foo.gids,
            (st_dumprings(st_simplifypreservetopology((st_dump(st_union(array[foo.geom, coalesce(w.geom, foo.geom)]))).geom, 0.00001))).geom as ring,
            foo.name as name,
            case
                when foo.name = any(
                    array['Gauja', 'Daugava', 'Ogre', 'Venta', 'Iecava', 'Pededze',
                        'Abava', 'Lielupe', 'Rēzekne', 'Mēmele', 'Aiviekste',
                        'Bērze', 'Dubna' ]
                ) then 'water_way'
                else 'lake'
            end::vectiles.type_water as type
        from (
            select array_agg(gid) as gids, (string_to_array(name, ' / '))[1] as name, st_union(geom) as geom
            from vectiles_input.lv_water
            where
                (
                    (
                        "fclass" not in ('wetland', 'river') and
                        st_area(geom, true) > 250000 and
                        lower((string_to_array(coalesce(name, 'a'), ' / '))[1]) not like '%ezers' and
                        lower((string_to_array(coalesce(name, 'a'), ' / '))[1]) not like 'ez. %'
                    ) or
                    (string_to_array(name, ' / '))[1] = any(
                        array['Gauja', 'Daugava', 'Ogre', 'Venta', 'Iecava', 'Pededze',
                            'Abava', 'Lielupe', 'Rēzekne', 'Mēmele', 'Aiviekste',
                            'Bērze', 'Dubna' ]
                    )
                ) and
                name is not null
            group by
                (string_to_array(name, ' / '))[1]
        ) foo left join vectiles_input.lv_water w on
            st_intersects(w.geom, foo.geom) and
            w.name is null and
            w.gid != all(foo.gids) and
            w.fclass not in ('wetland')
    ) f
    where
        type != 'water_way'
    group by
        name, type
) g
group by
    name, type, subtype
;


insert into vectiles.z_med_labels(
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select st_transform(st_geometricmedian(st_collect(geom)), 4326) as geom, l2_code as originalid, l2_name as name,
    'admin'::vectiles.type_labels,
    'admin.settlement'::vectiles.subtype_labels,
    case when l2_type = 1 then 150 else 50 end as hierarchy,
    0 as rotation
from (
    select
        st_lineinterpolatepoint(geom, 0.5) as geom,
        left_a2_code as l2_code, left_a2 as l2_name,
        case
            when left_a1_code = left_a2_code then 1
            else 2
        end as l2_type
    from
        vectiles_input.baltic_admin
    where
        left_country_code = 'LV' and
        left_a2 not like '% pagasts' and
        left_a2 not like '% novads'
    union all
    select
        st_lineinterpolatepoint(geom, 0.5) as geom,
        right_a2_code, right_a2,
        case
            when right_a1_code = right_a2_code then 1
            else 2
        end as l2_type
    from
        vectiles_input.baltic_admin
    where
        right_country_code = 'LV' and
        right_a2 not like '% pagasts' and
        right_a2 not like '% novads'
) foo
group by
    l2_code, l2_name, l2_type
;


insert into vectiles.z_med_labels(
    geom, originalid, name, type, subtype, hierarchy, rotation
)
select st_transform(st_geometricmedian(st_collect(geom)), 4326) as geom, l1_code as originalid, l1_name as name,
    'admin'::vectiles.type_labels,
    'admin.province'::vectiles.subtype_labels,
    case when l1_type = 1 then 100 else 0 end as hierarchy,
    0 as rotation
from (
    select
        st_lineinterpolatepoint(geom, 0.5) as geom,
        left_a1_code as l1_code, left_a1 as l1_name,
        case
            when left_a1_code = left_a2_code then 1
            else 2
        end as l1_type
    from
        vectiles_input.baltic_admin
    where
        left_country_code = 'LV'
    union all
    select
        st_lineinterpolatepoint(geom, 0.5) as geom,
        right_a1_code, right_a1,
        case
            when right_a1_code = right_a2_code then 1
            else 2
        end as l1_type
    from
        vectiles_input.baltic_admin
    where
        right_country_code = 'LV'
) foo
group by
    l1_code, l1_name, l1_type
;
