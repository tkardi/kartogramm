/* WATER */

drop type if exists vectiles.type_water cascade;
create type vectiles.type_water
    as enum (
        'sea',
        'tidal_flat',
        'lake',
        'water_way'
    )
;

drop table if exists vectiles.water;
create table vectiles.water (
    oid serial not null,
    geom geometry(Polygon, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_water not null
);

alter table vectiles.water
    add constraint pk__water
        primary key (oid)
;

create index sidx__water
    on vectiles.water
        using gist (geom)
;

drop table if exists vectiles.z_low_water;
create table vectiles.z_low_water (
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_water not null
);

alter table vectiles.z_low_water
    add constraint pk__z_low_water
        primary key (oid)
;

create index sidx__z_low_water
    on vectiles.z_low_water
        using gist (geom)
;

drop table if exists vectiles.z_med_water;
create table vectiles.z_med_water (
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_water not null
);

alter table vectiles.z_med_water
    add constraint pk__z_med_water
        primary key (oid)
;

create index sidx__z_med_water
    on vectiles.z_med_water
        using gist (geom)
;
