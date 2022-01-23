/* NUILTUP */

drop type if exists vectiles.type_builtup cascade;
create type vectiles.type_builtup
    as enum (
        'area',
        'building',
        'wall'
    )
;

drop type if exists vectiles.subtype_builtup cascade;
create type vectiles.subtype_builtup
    as enum (
        'area.', --??
        'area.courtyard',
        'area.industrial',
        'area.residential',
        'area.graveyard',
        'area.quarry',
        'area.dump',
        'area.sports',
        'building.', --??
        'building.industry',
        'building.main',
        'building.barn',
        'building.entrance',
        'building.waterbasin',
        'building.cover',
        'building.pitch',
        'building.berth', --kai
        'building.under_construction',
        'building.wreck',
        'building.foundation',
        'building.underground',
        'wall.' --??
    )
;

drop table if exists vectiles.builtup;
create table vectiles.builtup(
    oid serial not null,
    geom geometry(Polygon, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_builtup not null,
    subtype vectiles.subtype_builtup not null
);

alter table vectiles.builtup
    add constraint pk__builtup
        primary key (oid)
;

create index sidx__builtup
    on vectiles.builtup
        using gist (geom)
;

drop table if exists vectiles.z_low_builtup;
create table vectiles.z_low_builtup(
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_builtup not null,
    subtype vectiles.subtype_builtup not null
);

alter table vectiles.z_low_builtup
    add constraint pk__z_low_builtup
        primary key (oid)
;

create index sidx__z_low_builtup
    on vectiles.z_low_builtup
        using gist (geom)
;

drop table if exists vectiles.z_med_builtup;
create table vectiles.z_med_builtup(
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_builtup not null,
    subtype vectiles.subtype_builtup not null
);

alter table vectiles.z_med_builtup
    add constraint pk__z_med_builtup
        primary key (oid)
;

create index sidx__z_med_builtup
    on vectiles.z_med_builtup
        using gist (geom)
;
