while read LINE; do
    RESULT=$(psql -t -A -h localhost -U postgres -c "select count(*) from geo.search_for_habitat_by_prefix('$LINE')");

    if [ "$RESULT" -eq "0" ]; then
        echo $LINE;
    fi
done < ./sheet-locations.txt