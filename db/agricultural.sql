/* AGRICULTURAL */

drop type if exists vectiles.type_agricultural cascade;
create type vectiles.type_agricultural
    as enum (
        'agriculture',
        'arboriculture',
        'pasture',
        'greenhouse',
        'fallow' --sööt
    )
;

drop table if exists vectiles.agricultural;
create table vectiles.agricultural(
    oid serial not null,
    geom geometry(Polygon, 3301),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_agricultural not null
);


alter table vectiles.agricultural
    add constraint pk__agricultural
        primary key (oid)
;

create index sidx__agricultural
    on vectiles.agricultural
        using gist (geom)
;


drop table if exists vectiles.z_low_agricultural;
create table vectiles.z_low_agricultural(
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_agricultural not null
);


alter table vectiles.z_low_agricultural
    add constraint pk__z_low_agricultural
        primary key (oid)
;

create index sidx__z_low_agricultural
    on vectiles.z_low_agricultural
        using gist (geom)
;



drop table if exists vectiles.z_med_agricultural;
create table vectiles.z_med_agricultural(
    oid serial not null,
    geom geometry(Polygon, 4326),
    originalid varchar(50),
    name varchar(500),
    type vectiles.type_agricultural not null
);


alter table vectiles.z_med_agricultural
    add constraint pk__z_med_agricultural
        primary key (oid)
;

create index sidx__z_med_agricultural
    on vectiles.z_med_agricultural
        using gist (geom)
;
