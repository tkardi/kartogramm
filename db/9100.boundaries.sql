/* BOUNdARIES */

drop type if exists vectiles.type_boundaries cascade;
create type vectiles.type_boundaries
    as enum (
        'country', --A0
        'province', --A1
        'municipality', --A2
        'settlement' --A3
    )
;

drop type if exists vectiles.subtype_boundaries cascade;
create type vectiles.subtype_boundaries
    as enum (
        'country.foreign',
        'country.domestic',
        'province.',
        'municipality.',
        'settlement.'
    )
;

drop table if exists vectiles.boundaries;
create table vectiles.boundaries(
    oid serial not null,
    geom geometry(LineString, 3301),
    originalid varchar(50),
    name_left varchar(500),
    name_right varchar(500),
    country_left varchar(50),
    country_right varchar(50),
    type vectiles.type_boundaries not null,
    subtype vectiles.subtype_boundaries not null,
    on_water boolean default false
);

alter table vectiles.boundaries
    add constraint pk__boundaries
        primary key (oid)
;

create index sidx__boundaries
    on vectiles.boundaries
        using gist (geom)
;

drop table if exists vectiles.z_low_boundaries;
create table vectiles.z_low_boundaries(
    oid serial not null,
    geom geometry(LineString, 4326),
    originalid varchar(50),
    name_left varchar(500),
    name_right varchar(500),
    country_left varchar(50),
    country_right varchar(50),
    type vectiles.type_boundaries not null,
    subtype vectiles.subtype_boundaries not null,
    on_water boolean default false
);

alter table vectiles.z_low_boundaries
    add constraint pk__z_low_boundaries
        primary key (oid)
;

create index sidx__z_low_boundaries
    on vectiles.z_low_boundaries
        using gist (geom)
;

drop table if exists vectiles.z_med_boundaries;
create table vectiles.z_med_boundaries(
    oid serial not null,
    geom geometry(LineString, 4326),
    originalid varchar(50),
    name_left varchar(500),
    name_right varchar(500),
    country_left varchar(50),
    country_right varchar(50),
    type vectiles.type_boundaries not null,
    subtype vectiles.subtype_boundaries not null,
    on_water boolean default false
);

alter table vectiles.z_med_boundaries
    add constraint pk__z_med_boundaries
        primary key (oid)
;

create index sidx__z_med_boundaries
    on vectiles.z_med_boundaries
        using gist (geom)
;
