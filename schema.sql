create schema if not exists geo;

CREATE EXTENSION cube;
CREATE EXTENSION earthdistance;

create table if not exists geo.geoname (
    geonameid int primary key,
    name varchar(200),
    asciiname varchar(200),
    alternatenames varchar(10000),
    latitude float,
    longitude float,
    fclass char(1),
    fcode varchar(10),
    country varchar(2),
    cc2 varchar(600),
    admin1 varchar(20),
    admin2 varchar(80),
    admin3 varchar(20),
    admin4 varchar(20),
    population bigint,
    elevation int,
    gtopo30 int,
    timezone varchar(40),
    moddate date
);

create index if not exists geoname_name_lower_idx on geo.geoname(lower(name) text_pattern_ops);

create index if not exists geoname_country_ids on geo.geoname(country);


create table if not exists geo.alternatename (
    alternatenameId int primary key,
    geonameid int references geo.geoname(geonameId),
    isoLanguage varchar(7),
    alternateName varchar(200),
    isPreferredName boolean,
    isShortName boolean,
    isColloquial boolean,
    isHistoric boolean
);

create index if not exists alternateName_alternateName_lower_idx on geo.alternateName(lower(alternateName) text_pattern_ops);


create table if not exists geo.countryinfo (
    iso_alpha2 char(2) unique,
    iso_alpha3 char(3) unique,
    iso_numeric integer unique,
    fips_code varchar(3),
    name varchar(200),
    capital varchar(200),
    areainsqkm double precision,
    population integer,
    continent varchar(2),
    tld varchar(10),
    currencycode varchar(3),
    currencyname varchar(20),
    phone varchar(20),
    postalcode varchar(100),
    postalcoderegex varchar(200),
    languages varchar(200),
    geonameId int primary key references geo.geoname(geonameid),
    neighbors varchar(50),
    equivfipscode varchar(3)
);

create table if not exists geo.heirarchy (
    parentId int,
    childId int,
    type varchar(100)
);

-- This is used instead of a unique / foreign key as some 
--  ids are missing.
create index if not exists heirarchy_parent_idx on geo.heirarchy(parentId);
create index if not exists heirarchy_child_idx on geo.heirarchy(childId);

create table if not exists geo.admincodes(
    code varchar(100) unique,
    name varchar(200),
    nameAscii varchar(200),
    geonameid int references geo.geoname(geonameid)
);