/* ROADS */

drop type if exists vectiles.type_roads cascade;
create type vectiles.type_roads
    as enum (
        'highway', --põhimaantee
        'motorway', --"kiirtee", pole üldse
        'main',  --tugimaantee
        'secondary', -- kõrvalmaantee, muu riigimaantee, ramp või ühendustee
        'local', --tänav, muu tee
        'bike', -- kergliiklustee
        'path', --rada
        'ferry'
    )
;

drop type if exists vectiles.class_roads cascade;
create type vectiles.class_roads
    as enum (
        'stone',
        'gravel',
        'dirt',
        'wood',
        'permanent',
        'other'
    )
;

drop table if exists vectiles.roads;
create table vectiles.roads(
    oid serial not null,
    geom geometry(LineString, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_roads not null,
    class vectiles.class_roads not null,
    tunnel boolean default false,
    bridge boolean default false,
    oneway boolean default false,
    road_number varchar(250),
    relative_height smallint
);

alter table vectiles.roads
    add constraint pk__roads
        primary key (oid)
;

create index sidx__roads
    on vectiles.roads
        using gist (geom)
;


drop table if exists vectiles.z_low_roads;
create table vectiles.z_low_roads(
    oid serial not null,
    geom geometry(LineString, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_roads not null,
    class vectiles.class_roads not null,
    tunnel boolean default false,
    bridge boolean default false,
    oneway boolean default false,
    road_number varchar(250),
    relative_height smallint
);

alter table vectiles.z_low_roads
    add constraint pk__z_low_roads
        primary key (oid)
;

create index sidx__z_low_roads
    on vectiles.z_low_roads
        using gist (geom)
;

drop table if exists vectiles.z_med_roads;
create table vectiles.z_med_roads(
    oid serial not null,
    geom geometry(LineString, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_roads not null,
    class vectiles.class_roads not null,
    tunnel boolean default false,
    bridge boolean default false,
    oneway boolean default false,
    road_number varchar(250),
    relative_height smallint
);

alter table vectiles.z_med_roads
    add constraint pk__z_med_roads
        primary key (oid)
;

create index sidx__z_med_roads
    on vectiles.z_med_roads
        using gist (geom)
;
