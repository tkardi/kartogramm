
/** SOURCE DATA
*   Drop tables and recreate
*/

-- informal_district
drop table if exists vectiles_input.informal_district;
create table vectiles_input.informal_district (
    oid serial not null,
    name varchar(250),
    geom geometry(Polygon, 3301)
);

alter table vectiles_input.informal_district
    add constraint pk__informal_district
        primary key (oid)
;

create index sidx__informal_district
    on vectiles_input.informal_district
        using gist(geom)
;

-- bridges_for_rails
drop table if exists vectiles_input.bridges_for_rails;
create table vectiles_input.bridges_for_rails (
    oid serial not null,
    etak_id int,
    for_rail boolean,
    geom geometry(Polygon, 3301)
);

alter table vectiles_input.bridges_for_rails
    add constraint pk__bridges_for_rails
        primary key (oid)
;

create index sidx__bridges_for_rails
    on vectiles_input.bridges_for_rails
        using gist(geom)
;

-- bridges_for_rails
drop table if exists vectiles_input.bridges_for_roads;
create table vectiles_input.bridges_for_roads (
    oid serial not null,
    etak_id int,
    for_road boolean,
    geom geometry(Polygon, 3301)
);

alter table vectiles_input.bridges_for_roads
    add constraint pk__bridges_for_roads
        primary key (oid)
;

create index sidx__bridges_for_roads
    on vectiles_input.bridges_for_roads
        using gist(geom)
;

-- ee_address_object
drop table if exists vectiles_input.ee_address_object;
create table vectiles_input.ee_address_object (
    adob_id int,
    ads_oid varchar(20),
    adob_liik varchar(2),
    orig_tunnus varchar(50),
    etak_id int,
    ads_kehtiv timestamp,
    un_tunnus smallint,
    hoone_oid varchar(20),
    adr_id int,
    koodaadress varchar(50),
    taisaadress varchar(500),
    lahiaadress varchar(150),
    aadr_olek varchar(1),
    viitepunkt_x varchar,
    viitepunkt_y varchar,
    tase1_kood varchar(4),
    tase1_nimetus varchar(250),
    tase1_nimetus_liigiga varchar(250),
    tase2_kood varchar(4),
    tase2_nimetus varchar(250),
    tase2_nimetus_liigiga varchar(250),
    tase3_kood varchar(4),
    tase3_nimetus varchar(250),
    tase3_nimetus_liigiga varchar(250),
    tase4_kood varchar(4),
    tase4_nimetus varchar(250),
    tase4_nimetus_liigiga varchar(250),
    tase5_kood varchar(4),
    tase5_nimetus varchar(250),
    tase5_nimetus_liigiga varchar(250),
    tase6_kood varchar(4),
    tase6_nimetus varchar(250),
    tase6_nimetus_liigiga varchar(250),
    tase7_kood varchar(4),
    tase7_nimetus varchar(250),
    tase7_nimetus_liigiga varchar(250),
    tase8_kood varchar(4),
    tase8_nimetus varchar(250),
    tase8_nimetus_liigiga varchar(250),
    geom geometry(point, 3301),
    oid serial not null
);

alter table vectiles_input.ee_address_object
    add constraint pk__ee_address_object
        primary key (oid)
;

create index idx__ee_address__tase5_kood
    on vectiles_input.ee_address_object
       using btree (tase5_kood)
;

create index idx__ee_address_object__adob_liik
    on vectiles_input.ee_address_object
       using btree (adob_liik)
;

create index sidx__ee_address_object
    on vectiles_input.ee_address_object
       using gist (geom)
;


-- baltic_admin
drop table if exists vectiles_input.baltic_a0_expanded;
create table vectiles_input.baltic_a0_expanded(
    oid serial not null,
    left_name varchar(255),
    right_name varchar(255),
    left_country_code varchar(5),
    right_country_code varchar(5),
    on_water boolean,
    geom geometry(LineString, 3301)
);


alter table vectiles_input.baltic_a0_expanded
    add constraint pk__baltic_a0_expanded
        primary key (oid)
;

create index sidx__baltic_a0_expanded
    on vectiles_input.baltic_a0_expanded
        using gist (geom)
;

drop table if exists vectiles_input.baltic_admin;
create table vectiles_input.baltic_admin (
    hash varchar not null,
    geom geometry(LineString, 3301),
    left_country_code varchar(5),
    right_country_code varchar(5),
    left_a1_code varchar(20),
    left_a2_code varchar(20),
    left_a3_code varchar(20),
    left_a1 varchar(250),
    left_a2 varchar(250),
    left_a3 varchar(250),
    right_a1_code varchar(20),
    right_a2_code varchar(20),
    right_a3_code varchar(20),
    right_a1 varchar(250),
    right_a2 varchar(250),
    right_a3 varchar(250)
);

alter table vectiles_input.baltic_admin
    add constraint pk__baltic_admin
        primary key (hash)
;

create index sidx__baltic_admin
    on vectiles_input.baltic_admin
        using gist (geom)
;


-- oceans
drop table if exists vectiles_input.oceans;
create table vectiles_input.oceans (
    geom geometry(Polygon, 4326),
    oid serial not null
);

alter table vectiles_input.oceans
    add constraint pk__oceans
        primary key (oid)
;

create index sidx__oceans
    on vectiles_input.oceans
        using gist(geom)
;

-- lv_waterways
drop table if exists vectiles_input.lv_waterways;
create table vectiles_input.lv_waterways (
    oid serial,
    osm_id bigint,
    code int,
    fclass varchar(150),
    width int,
    name varchar(250),
    geom geometry(LineString, 4326)
);

alter table vectiles_input.lv_waterways
    add constraint pk__lv_waterways
        primary key (oid)
;

create index sidx__lv_waterways
    on vectiles_input.lv_waterways
        using gist(geom)
;

-- lv_water
drop table if exists vectiles_input.lv_water;
create table vectiles_input.lv_water (
    oid serial,
    osm_id bigint,
    code int,
    fclass varchar(150),
    name varchar(250),
    geom geometry(Polygon, 4326)
);


alter table vectiles_input.lv_water
    add constraint pk__lv_water
        primary key (oid)
;

create index sidx__lv_water
    on vectiles_input.lv_water
        using gist(geom)
;

-- lv_landuse
drop table if exists vectiles_input.lv_landuse;
create table vectiles_input.lv_landuse (
    oid serial,
    osm_id bigint,
    code int,
    fclass varchar(150),
    name varchar(250),
    geom geometry(Polygon, 4326)
);


alter table vectiles_input.lv_landuse
    add constraint pk__lv_landuse
        primary key (oid)
;

create index sidx__lv_landuse
    on vectiles_input.lv_landuse
        using gist(geom)
;

-- lv_roads
drop table if exists vectiles_input.lv_roads;
create table vectiles_input.lv_roads (
    oid serial,
    osm_id bigint,
    code int,
    fclass varchar(150),
    name varchar(250),
    ref varchar(100),
    oneway varchar(10),
    bridge varchar(10),
    tunnel varchar(10),
    geom geometry(LineString, 4326)
);


alter table vectiles_input.lv_roads
    add constraint pk__lv_roads
        primary key (oid)
;

create index sidx__lv_roads
    on vectiles_input.lv_roads
        using gist(geom)
;


--lv_railways
drop table if exists vectiles_input.lv_railways;
create table vectiles_input.lv_railways (
    oid serial,
    category int,
    disp_scale varchar(50),
    geom geometry(LineString, 4326)
);


alter table vectiles_input.lv_railways
    add constraint pk__lv_railways
        primary key (oid)
;

create index sidx__lv_railways
    on vectiles_input.lv_railways
        using gist(geom)
;


create or replace function vectiles_input.st_extend(
    line geometry,
    distance numeric,
    direction integer DEFAULT 1
) returns geometry
as
$$
/* based on
https://groups.google.com/g/postgis-users/c/yoD1IfcUMyI/m/lOLNbWeWwSEJ

@params
direction:
    -1: extend start
    0: extend both,
    1: extend end
*/
declare
    dist float;
    max_dist float = 0;
    n_points int;
    pto_1 geometry;
    pto_2 geometry;
    first_pto geometry;
    last_pto geometry;
    u_1 float;
    u_2 float;
    norm float;
begin
    if  (
            lower(geometrytype(line)) not like 'linestring' or
            distance <= 0 or
            st_length(line) = 0
        ) then
        return null;
    end if;

      if direction in (-1, 0) then
          pto_1 := st_startpoint(line);
          dist := distance;

          /* extend for first point */
          pto_2 := st_pointn(line,2);
          u_1 := st_x(pto_2)-st_x(pto_1);
          u_2 := st_y(pto_2)-st_y(pto_1);
          norm := sqrt(u_1^2 + u_2^2);
          first_pto := st_makepoint(st_x(pto_1)-u_1/norm*dist,st_y(pto_1)-u_2/norm*dist);
          line := st_addpoint(line, first_pto, 0);
       end if;

    if direction in (0, 1) then
          /* extend both or only end */
          n_points := st_npoints(line);
          pto_1 := st_pointn(line,n_points-1);
          pto_2 := st_endpoint(line);
          dist := distance;
          u_1   := st_x(pto_2)-st_x(pto_1);
          u_2   := st_y(pto_2)-st_y(pto_1);
          norm  := sqrt(u_1^2 + u_2^2);
          last_pto := st_makepoint(st_x(pto_2)+u_1/norm*dist,st_y(pto_2)+u_2/norm*dist);
          line := st_addpoint(line, last_pto);
    end if;

  return line;
end;
$$
language plpgsql
stable parallel safe;
;

create table if not exists vectiles_input.bridges (geom geometry);
create table if not exists vectiles_input.tee_tmp (xyz varchar, geom geometry, tee_gid int, z int);
create table if not exists vectiles_input.e_501_tee_j (gid int, xyz_from varchar, xyz_to varchar, tee varchar, geom geometry);

create or replace function vectiles_input.azimuth_based_z_level_fix(xyz varchar, tee_gids int[])
returns table (xyz text, tee_gids int[], tee_zs int[], new_z int) as
$$
with
    data as (
        select
            st_force2d(
                case
                    when xyz_from=$1 then st_linesubstring(geom, 0, 1/st_length(geom))
                    else st_linesubstring(geom, 1-(1/st_length(geom)), 1)
                end
            ) as geom,
            $1 as inter,
            xyz_from,
            xyz_to, tee, gid
        from
            vectiles_input.e_501_tee_j
        where
            gid = any($2) and
            array_upper($2, 1) % 2 = 0
    )
select
    inter, tee_gids,
    tee_zs,
    case
        when lag(tee_zs) over (order by rn) is null and tee_zs[1]=-1 then -1
        when lag(tee_zs) over (order by rn) is null and within_a_bridge=true then 0
        when lag(tee_zs) over (order by rn) is null then 0
        when within_a_bridge is null then 0
        else 1
    end as new_z
from (
    select
        row_number() over(order by z.z) as rn,
        inter,
        g.g as tee_gids,
        z.z as tee_zs,
        f.within_a_bridge
    from (
        select
            row_number() over (
                partition by my.my_gid order by abs(
                    st_azimuth(st_startpoint(my.my_geom), st_endpoint(my.my_geom))-
                        st_azimuth(st_startpoint(other.geom), st_endpoint(other.geom))
                )
            ) rn,
            tmp.z as my_z,
            o.z as other_z,
            my.*,
            other.geom as other_geom, other.gid as other_gid, other.tee as other_tee,
            st_azimuth(st_startpoint(my.my_geom), st_endpoint(my.my_geom)) as my_azimuth,
            st_azimuth(st_startpoint(other.geom), st_endpoint(other.geom)) as other_azimuth,
            st_within(tmp.geom, b.geom) as within_a_bridge
        from (
            select
                my.inter,
                my.tee as my_tee, my.gid as my_gid,
                case
                    when my.inter = my.xyz_to then my.geom
                    else st_reverse(my.geom)
                end as my_geom
            from
                data my
        ) my
            join lateral (
                select
                    gid, tee,
                    case
                        when data.inter = data.xyz_from then data.geom
                        else st_reverse(data.geom)
                    end as geom
                from data
                where my.my_gid != data.gid and my.inter = data.inter
            ) other on true
            left join vectiles_input.tee_tmp tmp on tmp.xyz = my.inter and tmp.tee_gid = my.my_gid
            left join vectiles_input.tee_tmp o on o.xyz = my.inter and o.tee_gid = other.gid
            left join vectiles_input.bridges b on st_within(tmp.geom, b.geom)
        ) f
        join lateral (select array_agg(g order by g) as g from unnest(array[my_gid, other_gid]) g) g on true
        join lateral (select array_agg(z order by z) as z from unnest(array[my_z, other_z]) z) z on true
    where rn = 1
    group by inter, tee_gids, tee_zs, within_a_bridge
) n
;
$$
language sql
parallel unsafe;
