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
            w.oid, foo.oids,
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
            select array_agg(oid) as oids, (string_to_array(name, ' / '))[1] as name, st_union(geom) as geom
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
            w.oid != all(foo.oids) and
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
