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
        tase7_kood != '' and
        tase8_kood = ''
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
    tase8_kood = '' and tase2_nimetus = any(array['Tallinn', 'Kohtla-Järve linn'])
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
    (tase6_kood != '' or tase7_kood != '') and
    tase8_kood = '' and tase2_nimetus like '% vald'
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
    (tase6_kood != '' or tase7_kood != '') and
    tase8_kood = ''
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

/*
drop table if exists vectiles_input.streetlinemerge_cp;
create table vectiles_input.streetlinemerge_cp as
select
    line.oid as lineoid,
    st_closestpoint(line.geom, ee.geom) as p,
    ee.geom as pnt, line.geom as line, ee.tase7_nimetus, line.ads_oid
from
    vectiles_input.ee_address_object ee,
    vectiles_input.streetlinemerge f
        cross join lateral (
            select
                oid, ads_oid, geom as geom
                from vectiles_input.streetlinemerge j
              where
                j.ads_oid = f.ads_oid
              order by
                ee.geom <-> j.geom
              limit 1
        ) line
where
    ee.adob_liik in ('EE', 'ME') and
    ee.un_tunnus = 1 and
    ee.tase7_nimetus not like '%/%' and
    f.a5_code = ee.tase5_kood
;

alter table vectiles_input.streetlinemerge_cp
    add column
        oid serial
;

alter table vectiles_input.streetlinemerge_cp
    add constraint
        pk__trt_streetmegre_cp
            primary key (oid)
;

alter table vectiles_input.streetlinemerge_cp
    add column
        line_start geometry(linestring, 3301)
;

alter table vectiles_input.streetlinemerge_cp
    add column
        line_end geometry(linestring, 3301)
;

alter table vectiles_input.streetlinemerge_cp
    add column
        line_med geometry(linestring, 3301)
;

update vectiles_input.streetlinemerge_cp set
    line_start = st_force2d(st_linesubstring(f.geom, 0, 5/st_length(geom))),
    line_end = st_force2d(st_linesubstring(f.geom, (st_length(geom)-5)/st_length(geom), 1)),
    line_med = st_force2d(st_linesubstring(f.geom, ((st_length(geom)/2)-2.5)/st_length(geom), ((st_length(geom)/2)+2.5)/st_length(geom)))
from (
    select oid, (st_dump(geom)).*
    from (
        select
            oid, st_linesubstring(
                line,
                15/st_length(line),
                (st_length(line)-15)/st_length(line)
            ) as geom
          from
            vectiles_input.streetlinemerge_cp
        where
            st_length(line) >= 40
    ) g
) f
where
    st_length(geom) >= 40 and
    f.oid = streetlinemerge_cp.oid
;

create index sidx__streetlinemerge_cp__line_start on
    vectiles_input.streetlinemerge_cp
        using gist (line_start)
;

create index sidx__streetlinemerge_cp__line_end on
    vectiles_input.streetlinemerge_cp
        using gist (line_end)
;

create index sidx__streetlinemerge_cp__line_med on
    vectiles_input.streetlinemerge_cp
        using gist (line_med)
;

drop table if exists vectiles_input.adrsegs;
create table vectiles_input.adrsegs as
select
    lineoid, ads_oid, minnr, maxnr, side,
    minlocation, maxlocation,
    st_offsetcurve(minlocation::geometry(linestring, 3301), case when side = 'R' then -1 else 1 end * 3.0) as min_geom,
    st_offsetcurve(maxlocation::geometry(linestring, 3301), case when side = 'R' then -1 else 1 end * 3.0) as  max_geom,
    st_offsetcurve(medlocation::geometry(linestring, 3301), case when side = 'R' then -1 else 1 end * 3.0) as  med_geom,
    minsource, maxsource, medsource,
    mindeg, maxdeg
from (
    select
        lineoid, ads_oid,
        trim(leading '0' from minnr) as minnr,
        trim(leading '0' from maxnr) as maxnr,
        side,
        case
              when count=1 then null
            when st_distance(st_endpoint(line_start), pnts[array_upper(pnts,1)]) > st_distance(st_endpoint(line_start), pnts[1])
                        then line_start
                else line_end
          end as minlocation,
        case
              when count=1 then null
                when st_distance(st_endpoint(line_start), pnts[1]) > st_distance(st_endpoint(line_start), pnts[array_upper(pnts,1)])
                        then line_start
                  else line_end
          end as maxlocation,
          case
              when count = 1 then line_med
            else null
          end as medlocation,
        case
              when count=1 then null
            when st_distance(st_endpoint(line_start), pnts[array_upper(pnts,1)]) > st_distance(st_endpoint(line_start), pnts[1])
                        then 'line_start'
                else 'line_end'
          end as minsource,
        case
              when count=1 then null
                when st_distance(st_endpoint(line_start), pnts[1]) > st_distance(st_endpoint(line_start), pnts[array_upper(pnts,1)])
                        then 'line_start'
                  else 'line_end'
          end as maxsource,
          case
              when count = 1 then 'line_med'
            else null
          end as medsource,
          degrees(deg[1]) as mindeg,
        degrees(deg[array_upper(deg, 1)]) as maxdeg
    from (
        select
            array_agg(deg order by tase7_nimetus)as deg, lineoid, ads_oid, side,
            min(tase7_nimetus) as minnr, max(tase7_nimetus) as maxnr,
            array_agg(pnt order by tase7_nimetus) as pnts,
              min(line_start)::geometry(linestring, 3301) as line_start,
              min(line_end)::geometry(linestring, 3301) as line_end,
              min(line_med)::geometry(linestring, 3301) as line_med,
              count(1)
        from (
            select
                oid, line_start, line_end, line_med,
                  deg, lineoid, lpad(tase7_nimetus, 5, '0') as tase7_nimetus, ads_oid,
                  case
                      when side between 0.0 and pi() then 'R'
                      when side between -1*pi() and 0.0 then 'L'
                      when side > pi() then 'L'
                        else 'R'
                end as side, geom, pnt,
                  degrees(side) as rad, vec, seg
            from (
                select
                    tase7_nimetus, ads_oid,
                    (
                        st_azimuth(st_startpoint(h.vec), st_endpoint(h.vec)) -
                        st_azimuth(st_startpoint(h.seg), st_endpoint(h.seg))
                    ) as side,
                    st_azimuth(st_startpoint(h.vec), st_endpoint(h.vec)) as deg,
                      vec as vec, seg as seg,
                      line as geom, pnt, lineoid,
                      oid, line_start, line_end, line_med
                from (
                    select
                          cp.oid, line_start, line_end, line_med,
                        st_makeLine(cp.p, pnt) vec,
                            case
                                  when st_linelocatepoint(line, cp.p) < 0.95
                                   then st_makeline(cp.p, st_lineinterpolatepoint(line, st_linelocatepoint(line, cp.p) * 1.01))
                              else
                                  st_makeline(st_lineinterpolatepoint(line,0.95), cp.p)
                        end as seg,
                            tase7_nimetus, ads_oid, line, pnt, lineoid
                    from
                        vectiles_input.streetlinemerge_cp cp
                ) h
            ) r
        ) e
        group by lineoid, ads_oid, side
    ) z
) y
;

alter table vectiles_input.adrsegs
    add column
        gid serial not null
;

alter table vectiles_input.adrsegs
    add constraint
        pk__adrsegs primary key (
            gid
        )
;

insert into vectiles.labels (
    geom, originalid, name, type, subtype, rotation
)
select
    case
        when minsource='line_start' then st_endpoint(min_geom)
        else st_startpoint(min_geom)
    end as geom, null as originalid, minnr as name,
    'addressrange' as type, 'addressrange.'||minsource as subtype,
    degrees(st_azimuth(st_startpoint(min_geom), st_endpoint(min_geom)) - pi()/2) as rotation
from vectiles_input.adrsegs
where
    min_geom is not null
union all
select
    case
        when maxsource='line_start' then st_endpoint(min_geom)
        else st_startpoint(max_geom)
    end as geom, null as originalid, maxnr as name,
    'addressrange' as type, 'addressrange.'||maxsource as subtype,
    degrees(st_azimuth(st_startpoint(max_geom), st_endpoint(max_geom)) - pi()/2) as rotation
from vectiles_input.adrsegs
where
    max_geom is not null
union all
select
    st_centroid(med_geom) as geom, null as originalid, minnr as name,
    'addressrange' as type, 'addressrange.'||medsource as subtype,
    degrees(st_azimuth(st_startpoint(med_geom), st_endpoint(med_geom)) - pi()/2) as rotation
from vectiles_input.adrsegs
where
    med_geom is not null
;
*/
