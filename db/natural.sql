/* NATURAL */

drop type if exists vectiles.type_natural cascade;
create type vectiles.type_natural
    as enum (
        'high',
        'low',
        'bare'
    )
;

drop type if exists vectiles.subtype_natural cascade;
create type vectiles.subtype_natural
    as enum (
        'high.mixed',
        'high.deciduous',
        'high.coniferous',
        'low.heath',
        'low.grass',
        'low.shrubs',
        'low.wet', -- etak: puis==Jah
        'bare.sand',
        'bare.rock',
        'bare.dune',
        'bare.wet', -- etak: puis==Ei
        'bare.peat'
    )
;

drop table if exists vectiles.natural;
create table vectiles.natural(
    oid serial not null,
    geom geometry(Polygon, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_natural not null,
    subtype vectiles.subtype_natural not null
);

alter table vectiles.natural
    add constraint pk__natural
        primary key (oid)
;

create index sidx__natural
    on vectiles.natural
        using gist (geom)
;


drop table if exists vectiles.z_low_natural;
create table vectiles.z_low_natural(
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_natural not null,
    subtype vectiles.subtype_natural not null
);

alter table vectiles.z_low_natural
    add constraint pk__z_low_natural
        primary key (oid)
;

create index sidx__z_low_natural
    on vectiles.z_low_natural
        using gist (geom)
;


drop table if exists vectiles.z_med_natural;
create table vectiles.z_med_natural(
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_natural not null,
    subtype vectiles.subtype_natural not null
);

alter table vectiles.z_med_natural
    add constraint pk__z_med_natural
        primary key (oid)
;

create index sidx__z_med_natural
    on vectiles.z_med_natural
        using gist (geom)
;
