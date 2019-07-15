-- Creates heirarchical links for admincodes. These aren't included in the 
--  heirarchy table by default.
insert into geo.heirarchy(parentId, childId)
    with geoname as (
        select
            g.geonameid as id,
            coalesce(g.country, '') || coalesce('.' || g.admin1, '') || coalesce('.' || g.admin2, '') as code
        from
            geo.geoname g),
    heirarchy as (
        select
            a.geonameid as parentId, g.id as childId
        from geo.admincodes a
        inner join geoname g on g.code = a.code
        where
            a.geonameid <> g.id
            and not exists (select * from geo.heirarchy where parentid = a.geonameid and childid = g.id))
    select parentId, childId from heirarchy where parentId <> childId;

-- Delete loose ends. Don't know why these are here.
with missingIds as (
    select * from (select h.childid from geo.heirarchy h except select g.geonameid from geo.geoname g) q union
    select * from (select h.parentid from geo.heirarchy h except select g.geonameid from geo.geoname g) q)
delete from geo.heirarchy where childid in (select * from missingIds) or parentid in (select * from missingIds);

-- Add foreign key to heirarchy
alter table geo.heirarchy add foreign key (childid) references geo.geoname(geonameid);
alter table geo.heirarchy add foreign key (parentid) references geo.geoname(geonameid);

-- Redundant
alter table geo.geoname drop column alternatenames;