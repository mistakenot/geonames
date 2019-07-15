-- A fast prefix search designed for user lookup boxes.
create or replace function geo.search_for_habitat_by_prefix(term character varying)
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
            select distinct on(geonameid) * from combinedResults
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