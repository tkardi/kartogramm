/* WATERLINES */

drop type if exists vectiles.type_waterline cascade;
create type vectiles.type_waterline
    as enum (
        '1m', --etak: "1-2m"
        '3m', --etak: "2-4m"
        '6m', --etak: "4-6m"
        '8m', --etak: "6-8m"
        '12m', --etak: laius=='Telg' and telje_tyyp in (10, 20)
        '50m',
        '125m'
    )
;

drop type if exists vectiles.class_waterline cascade;
create type vectiles.class_waterline
    as enum (
        'river', --etak: tyyp=10
        'channel', --etak: tyyp=20
        'stream', --etak: tyyp=30
        'ditch', --etak: tyyp=50
        'mainditch' --etak: tyyp=40
    )
;


drop table if exists vectiles.waterline;
create table vectiles.waterline(
    oid serial not null,
    geom geometry(LineString, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_waterline not null,
    class vectiles.class_waterline not null,
    underground boolean default false
);

alter table vectiles.waterline
    add constraint pk__waterline
        primary key (oid)
;

create index sidx__waterline
    on vectiles.waterline
        using gist (geom)
;

drop table if exists vectiles.z_low_waterline;
create table vectiles.z_low_waterline(
    oid serial not null,
    geom geometry(LineString, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_waterline not null,
    class vectiles.class_waterline not null,
    underground boolean default false
);

alter table vectiles.z_low_waterline
    add constraint pk__z_low_waterline
        primary key (oid)
;

create index sidx__z_low_waterline
    on vectiles.z_low_waterline
        using gist (geom)
;

drop table if exists vectiles.z_med_waterline;
create table vectiles.z_med_waterline(
    oid serial not null,
    geom geometry(LineString, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_waterline not null,
    class vectiles.class_waterline not null,
    underground boolean default false
);

alter table vectiles.z_med_waterline
    add constraint pk__z_med_waterline
        primary key (oid)
;

create index sidx__z_med_waterline
    on vectiles.z_med_waterline
        using gist (geom)
;
