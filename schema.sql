create schema geo;
use schema geo;

create table geoname (
    geonameid int primary key,
    name varchar(200),
    asciiname varchar(200),
    alternatives text,
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

create index on geoname(lower(name) text_pattern_ops)

create function search_geoname_by_name_prefix(prefix text) returns table(id int, name text, country text) as $$
begin
    
end
$$; language plpgsql;

create table alternatename (
    alternatenameId int primary key,
    geonameid int references geoname(geonameId),
    isoLanguage varchar(7),
    alternateName varchar(200),
    isPreferredName boolean,
    isShortName boolean,
    isColloquial boolean,
    isHistoric boolean
);

create table "countryinfo" (
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
    geonameId int primary key references geoname(geonameid),
    neighbors varchar(50),
    equivfipscode varchar(3)
);

create table heirarchy (
    parentId int,
    childId int,
    type varchar(100)
)
-- This is used instead of a unique / foreign key as some 
--  ids are missing.
create index on heirarchy(parentId)
create index on heirarchy(childId)