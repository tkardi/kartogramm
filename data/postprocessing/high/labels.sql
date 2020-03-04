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
                adob_liik, nullif(tase2_kood, '') as tase2_kood, nullif(tase3_kood, '') as tase3_kood,
                nullif(tase4_kood, '') as tase4_kood, nullif(tase5_kood, '') as tase5_kood,
                nullif(tase7_nimetus, '') as tase7_nimetus, nullif(tase6_nimetus, '') as tase6_nimetus, geom
            from vectiles_input.ee_address_object
            where
                adob_liik in ('EE', 'ME', 'CU') and
                nullif(tase8_kood, '') is null and (
                    nullif(tase6_kood,'') is not null or
                    nullif(tase7_kood,'') is not null
                ) and
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
                adob_liik, nullif(tase2_kood, '') as tase2_kood, nullif(tase3_kood, '') as tase3_kood,
                nullif(tase4_kood, '') as tase4_kood, nullif(tase5_kood, '') as tase5_kood,
                nullif(tase7_nimetus, '') as tase7_nimetus, nullif(tase6_nimetus, '') as tase6_nimetus, geom,
                lahiaadress
            from vectiles_input.ee_address_object
            where
                adob_liik in ('EE', 'ME', 'CU') and
                nullif(tase8_kood, '') is null and (
                    nullif(tase6_kood,'') is not null or
                    nullif(tase7_kood,'') is not null
                ) and
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
