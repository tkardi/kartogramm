/* LABELS */

drop type if exists vectiles.type_labels cascade;
create type vectiles.type_labels
    as enum (
        'place',
        'admin',
        'water',
        'nature',
        'address'
    )
;

drop type if exists vectiles.subtype_labels cascade;
create type vectiles.subtype_labels
    as enum (
        'place.urban_district',
        'place.settlement',
        'admin.country.foreign',
        'admin.country.domestic',
        'admin.province',
        'admin.municipality',
        'admin.settlement',
        'admin.district',
        'admin.neighborhood',
        'address.building',
        'address.parcel',
        'water.',
        'nature.'
    )
;

drop table if exists vectiles.labels;
create table vectiles.labels(
    oid serial not null,
    geom geometry(Point, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_labels not null,
    subtype vectiles.subtype_labels not null,
    hierarchy int not null default 0,
    rotation numeric
);

alter table vectiles.labels
    add constraint pk__labels
        primary key (oid)
;

create index sidx__labels
    on vectiles.labels
        using gist (geom)
;

drop table if exists vectiles.z_low_labels;
create table vectiles.z_low_labels(
    oid serial not null,
    geom geometry(Point, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_labels not null,
    subtype vectiles.subtype_labels not null,
    hierarchy int not null default 0,
    rotation numeric
);

alter table vectiles.z_low_labels
    add constraint pk__z_low_labels
        primary key (oid)
;

create index sidx__z_low_labels
    on vectiles.z_low_labels
        using gist (geom)
;

drop table if exists vectiles.z_med_labels;
create table vectiles.z_med_labels(
    oid serial not null,
    geom geometry(Point, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_labels not null,
    subtype vectiles.subtype_labels not null,
    hierarchy int not null default 0,
    rotation numeric
);

alter table vectiles.z_med_labels
    add constraint pk__z_med_labels
        primary key (oid)
;

create index sidx__z_med_labels
    on vectiles.z_med_labels
        using gist (geom)
;
