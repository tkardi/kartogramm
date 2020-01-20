/* RAILWAYS */

drop type if exists vectiles.type_railways cascade;
create type vectiles.type_railways
    as enum (
        'rail',
        'tram',
        'metro',
        'industrial',
        'touristic',
        'light_rail'
    )
;

drop type if exists vectiles.subtype_railways cascade;
create type vectiles.subtype_railways
    as enum (
        'rail.large_gauge',
        'rail.narrow_gauge',
        'rail.funicular',
        'rail.other',
        'tram.',
        'metro.',
        'industrial.',
        'touristic.',
        'light_rail.'
    )
;

drop type if exists vectiles.class_railways cascade;
create type vectiles.class_railways
    as enum (
        'main',
        'side',
        'branch'
    )
;

drop table if exists vectiles.railways;
create table vectiles.railways(
    oid serial not null,
    geom geometry(LineString, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_railways not null,
    subtype vectiles.subtype_railways not null,
    class vectiles.class_railways,
    tunnel boolean default false,
    bridge boolean default false
);


alter table vectiles.railways
    add constraint pk__railways
        primary key (oid)
;

create index sidx__railways
    on vectiles.railways
        using gist (geom)
;

drop table if exists vectiles.z_low_railways;
create table vectiles.z_low_railways(
    oid serial not null,
    geom geometry(LineString, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_railways not null,
    subtype vectiles.subtype_railways not null,
    class vectiles.class_railways,
    tunnel boolean default false,
    bridge boolean default false
);


alter table vectiles.z_low_railways
    add constraint pk__z_low_railways
        primary key (oid)
;

create index sidx__z_low_railways
    on vectiles.z_low_railways
        using gist (geom)
;

drop table if exists vectiles.z_med_railways;
create table vectiles.z_med_railways(
    oid serial not null,
    geom geometry(LineString, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_railways not null,
    subtype vectiles.subtype_railways not null,
    class vectiles.class_railways,
    tunnel boolean default false,
    bridge boolean default false
);


alter table vectiles.z_med_railways
    add constraint pk__z_med_railways
        primary key (oid)
;

create index sidx__z_med_railways
    on vectiles.z_med_railways
        using gist (geom)
;
