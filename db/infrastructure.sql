/* INFRASTRUCTURE*/

drop type if exists vectiles.type_infrastructure cascade;
create type vectiles.type_infrastructure
    as enum (
        'parking',
        'road',
        'railway',
        'jetty',
        'tunnel',
        'bridge',
        'runway',
        'pavement'
    )
;

drop type if exists vectiles.subtype_infrastructure cascade;
create type vectiles.subtype_infrastructure
    as enum (
        'parking.',
        'road.motorway',
        'road.transit',
        'road.bike',
        'road.driveway',
        'road.bridle_way',
        'road.crossing',
        'road.secondary',
        'road.highway',
        'road.local',
        'road.path',
        'railway.track_surface',
        'railway.platform',
        'jetty.',
        'tunnel.',
        'bridge.',
        'runway.',
        'pavement.'
    )
;

drop table if exists vectiles.infrastructure;
create table vectiles.infrastructure(
    oid serial not null,
    geom geometry(Polygon, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_infrastructure not null,
    subtype vectiles.subtype_infrastructure not null
);

alter table vectiles.infrastructure
    add constraint pk__infrastructure
        primary key (oid)
;

create index sidx__infrastructure
    on vectiles.infrastructure
        using gist (geom)
;


drop table if exists vectiles.z_low_infrastructure;
create table vectiles.z_low_infrastructure(
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_infrastructure not null,
    subtype vectiles.subtype_infrastructure not null
);

alter table vectiles.z_low_infrastructure
    add constraint pk__z_low_infrastructure
        primary key (oid)
;

create index sidx__z_low_infrastructure
    on vectiles.z_low_infrastructure
        using gist (geom)
;

drop table if exists vectiles.z_med_infrastructure;
create table vectiles.z_med_infrastructure(
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_infrastructure not null,
    subtype vectiles.subtype_infrastructure not null
);

alter table vectiles.z_med_infrastructure
    add constraint pk__z_med_infrastructure
        primary key (oid)
;

create index sidx__z_med_infrastructure
    on vectiles.z_med_infrastructure
        using gist (geom)
;
