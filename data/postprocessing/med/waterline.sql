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
