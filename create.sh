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
    # if [ ! -f "data/$1.*" ]; then
    #     (wget --directory-prefix=data http://download.geonames.org/export/dump/$1.zip && \
    #     unzip -q data/$1.zip -d./data/) ||
    #     wget --directory-prefix=data http://download.geonames.org/export/dump/$1.txt
    # fi

    if ! ls -q data/$1.* >/dev/null; then
        (wget --directory-prefix=data http://download.geonames.org/export/dump/$1.zip && \
        unzip -o data/$1.zip -d./data/) ||
        wget --directory-prefix=data http://download.geonames.org/export/dump/$1.txt
    fi
}

download_all_files() {
    mkdir -p data
    download_file allCountries
    download_file hierarchy
    download_file alternateNames
    download_file countryInfo
    download_file admin1CodesASCII
    download_file admin2Codes
    download_file GB
    download_file no-country

    cat data/countryInfo.txt | sed '/^#/ d' > data/countryInfoNoHeader.txt
    # We ignore the alternative names field as we import them from a seperate file.
    # test -e data/allCountriesNoAlternativeNames.txt || cat data/allCountries.txt | cut -f4 --complement > data/allCountriesNoAlternativeNames.txt
}

create_schema() {
    cat ./schema.sql | psql
    cat ./functions.sql | psql
}

import_all_data() {
    echo 'Importing allCountries.txt. Might take a while.'
    cat data/allCountries.txt | psql -c "copy geo.geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from STDIN null as '';"
    echo 'Importing alternateNames.txt. Might take a while.'
    cat data/alternateNames.txt | psql -c "copy geo.alternatename (alternatenameid,geonameid,isolanguage,alternatename,ispreferredname,isshortname,iscolloquial,ishistoric) from stdin null as '';"
    echo 'Importing countryInfoNoHeader.txt'
    cat data/countryInfoNoHeader.txt | psql -c "copy geo.countryinfo (iso_alpha2,iso_alpha3,iso_numeric,fips_code,name,capital,areainsqkm,population,continent,tld,currencycode,currencyname,phone,postalcode,postalcoderegex,languages,geonameid,neighbors,equivfipscode) from stdin null as '';"
    echo 'Importing heirarchy.txt. Might take a while.'
    cat data/hierarchy.txt | psql -c "copy geo.heirarchy (parentId, childId, type) from stdin null as '';"
    echo 'Import admin codes.'
    cat data/admin1CodesASCII.txt | psql -c "copy geo.admincodes (code, name, nameascii, geonameid) from stdin null as '';"
    cat data/admin2Codes.txt | psql -c "copy geo.admincodes (code, name, nameascii, geonameid) from stdin null as '';"
}

import_uk_data() {
    echo 'Importing GB.txt. Might take a while.'
    cat data/GB.txt | psql -c "copy geo.geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from STDIN null as '';"
    echo 'Importing heirarchy.txt. Might take a while.'
    cat data/hierarchy.txt | psql -c "copy geo.heirarchy (parentId, childId, type) from stdin null as '';"
}

post_create() {
    cat ./post-create.sql | psql
}

download_all_files
create_schema
import_uk_data
# import_all_data
post_create