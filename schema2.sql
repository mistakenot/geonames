create schema if not exists geo;

CREATE EXTENSION cube;
CREATE EXTENSION earthdistance;

create table if not exists geo.geoname (
    id int primary key,
    name varchar(200),
    asciiname varchar(200),
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
    geonameid int references geo.geoname(id),
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
    geonameId int primary key references geo.geoname(id),
    neighbors varchar(50),
    equivfipscode varchar(3)
);

create table if not exists geo.heirarchy (
    parentId int references geo.geoname(id),
    childId int references geo.geoname(id),
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
    geonameid int references geo.geoname(id)
);


-- A fast prefix search designed for user lookup boxes.
create or replace function geo.search_by_prefix(term character varying)
    returns TABLE(id integer, name character varying, alternatename character varying, country character varying)
    language plpgsql
as
$$
declare
    acceptableFClasses text[] = array['A', 'L', 'P'];
    pattern text = lower(term || '%');
begin
    return query(
        with alternatives as (
            select *
            from geo.alternatename a
            where lower(a.alternatename) like pattern),
        alternativesGeo as (
            select * from geo.geoname g 
            where g.geonameid in (select a.geonameid from alternatives a)
            and g.fclass = any(acceptableFClasses)
        ),
        aliasResults as (
            select g.geonameid, g.name as name, a.alternatename as alternatename, coalesce(g.population, 0) as population, g.country
            from alternatives a inner join alternativesGeo g on a.geonameid = g.geonameid
        ),
        geoResults as (
            select g.geonameid, g.name, g.name as alternatename, coalesce(g.population, 0) as population, g.country
            from geo.geoname g where lower(g.name) like pattern and g.fclass = any(acceptableFClasses)
        ),
        combinedResults as (
            select * from aliasResults union
            select * from geoResults),
        uniqueResults as (
            select distinct on(id) * from combinedResults
        )
        select r.geonameid, r.name, r.alternatename, r.country from uniqueResults r order by r.population desc limit 10);
end
$$;

create or replace function geo.get_parents(_geoRegionId int) RETURNS TABLE(geonameid int) AS $$ BEGIN
    RETURN QUERY (
        WITH RECURSIVE parents(id, parentId) AS (
            SELECT g.childid AS id, g.parentid AS parentId
            FROM geo.heirarchy g
            WHERE g.childid = _geoRegionId UNION
                SELECT g.childId AS id, g.parentid AS parentId
                FROM geo.heirarchy g
                INNER JOIN parents ON parents.parentId = g.childid)
        SELECT distinct id FROM parents union select * from geo.get_earth_id());
END $$ LANGUAGE plpgsql;

create function geo.get_earth_id() returns int as $$ begin
    return (select geonameid from geo.geoname
            where name = 'Earth' and latitude = 0 and longitude = 0 and country is null);
end;
$$ language plpgsql;

create or replace function geo.get_distance_between(georegionidOne int, georegionidTwo int) returns float as $$
begin
    return (
        select point(a.longitude, a.latitude) <@> point(b.longitude, b.latitude)
        from geo.geoname a cross join  geo.geoname b
        where a.geonameid = georegionidOne and b.geonameid = georegionidTwo);
end;
$$ language plpgsql;