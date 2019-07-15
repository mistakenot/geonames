#!/bin/bash

# Script to download and create a database based on GeoNames.
# Use the following environmental vars to setup psql
#   PGHOST
#   PGPORT
#   PDDATABASE
#   PGUSER
#   PGPASSWORD

export PGHOST="${PGHOST:=localhost}"
export PGUSER="${PGUSER:=postgres}"

download_file() {
    test -e output/$1.* || \
    (
        wget --directory-prefix=output http://download.geonames.org/export/dump/$1.zip && \
        unzip output/$1.zip
    ) || \
    wget --directory-prefix=output http://download.geonames.org/export/dump/$1.txt
}

download_all_files() {
    mkdir -p output
    download_file allCountries
    download_file hierarchy
    download_file alternateNames
    download_file countryInfo
    download_file admin1CodesASCII
    download_file admin2Codes

    cat output/countryInfo.txt | sed '/^#/ d' > output/countryInfoNoHeader.txt
    # We ignore the alternative names field as we import them from a seperate file.
    test -e output/allCountriesNoAlternativeNames.txt || cat output/allCountries.txt | cut -f4 --complement > output/allCountriesNoAlternativeNames.txt
}

create_schema() {
    cat ./schema.sql | psql
}

import_data() {
    echo 'Importing allCountries.txt. Might take a while.'
    cat output/allCountries.txt | psql -c "copy geo.geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from STDIN null as '';"
    echo 'Importing alternateNames.txt. Might take a while.'
    cat output/alternateNames.txt | psql -c "copy geo.alternatename (alternatenameid,geonameid,isolanguage,alternatename,ispreferredname,isshortname,iscolloquial,ishistoric) from stdin null as '';"
    echo 'Importing countryInfoNoHeader.txt'
    cat output/countryInfoNoHeader.txt | psql -c "copy geo.countryinfo (iso_alpha2,iso_alpha3,iso_numeric,fips_code,name,capital,areainsqkm,population,continent,tld,currencycode,currencyname,phone,postalcode,postalcoderegex,languages,geonameid,neighbors,equivfipscode) from stdin null as '';"
    echo 'Importing heirarchy.txt. Might take a while.'
    cat output/hierarchy.txt | psql -c "copy geo.heirarchy (parentId, childId, type) from stdin null as '';"
    echo 'Import admin codes.'
    cat output/admin1CodesASCII.txt | psql -c "copy geo.admincodes (code, name, nameascii, geonameid) from stdin null as '';"
    cat output/admin2Codes.txt | psql -c "copy geo.admincodes (code, name, nameascii, geonameid) from stdin null as '';"
}

download_all_files
create_schema
import_data