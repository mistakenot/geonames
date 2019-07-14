#!/bin/bash

# Script to download and create a database based on GeoNames.
# To use login details alias psql and source this script.

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
}

create_schema() {
    cat schema.sql | psql
}

import_data() {
    echo 'Importing allCountries.txt'
    cat allCountries.txt | psql -c "copy geoname (geonameid,name,asciiname,alternatives,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from STDIN null as '';"
    echo 'Importing alternateNames.txt'
    cat alternateNames.txt | psql -c "copy alternatename  (alternatenameid,geonameid,isolanguage,alternatename,ispreferredname,isshortname,iscolloquial,ishistoric) from stdin null as '';"
    echo 'Importing countryInfoNoHeader.txt'
    cat countryInfoNoHeader.txt | psql -c "copy countryinfo (iso_alpha2,iso_alpha3,iso_numeric,fips_code,name,capital,areainsqkm,population,continent,tld,currencycode,currencyname,phone,postalcode,postalcoderegex,languages,geonameid,neighbors,equivfipscode) from stdin null as '';"
    echo 'Importing heirarchy.txt'
    cat hierarchy.txt | psql -c "copy heirarchy (parentId, childId, type) from stdin null as '';"
}

# create_schema
download_all_files