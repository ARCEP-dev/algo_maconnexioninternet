#!/bin/bash
# params : pghost pgport pgdatabase pguser pgpassword api_url schema table score_min parall_workers

# To kill all workers
# for pid in $(ps -ef | awk '/geocoding_pgsql_max_length.py/ {print $2}'); do sudo kill -9 $pid; done

stat_request="SELECT 'coax' AS table, count(*), (count(*)::real / (SELECT COUNT(*) FROM reseau_coax.adresse))::decimal(5,4) AS ratio, 'Done' AS state, to_char(now(), 'YYYY-mm-dd HH24:MI:SS') AS time FROM reseau_coax.adresse WHERE code_ban IS NOT NULL \
UNION \
SELECT 'coax' AS table, count(*), (count(*)::real / (SELECT COUNT(*) FROM reseau_coax.adresse))::decimal(5,4) AS ratio, 'Remaining' AS state, to_char(now(), 'YYYY-mm-dd HH24:MI:SS') AS time FROM reseau_coax.adresse WHERE code_ban IS NULL AND geocoding_failure IS NOT True \
UNION \
SELECT 'coax' AS table, count(*), (count(*)::real / (SELECT COUNT(*) FROM reseau_coax.adresse))::decimal(5,4) AS ratio, 'Failure' AS state, to_char(now(), 'YYYY-mm-dd HH24:MI:SS') AS time FROM reseau_coax.adresse WHERE code_ban IS NULL AND geocoding_failure IS True \
ORDER BY state;"

export PGHOST=$1
export PGPORT=$2
export PGDATABASE=$3
export PGUSER=$4
export PGPASSWORD=$5

echo `date +"%Y-%m-%d %T"` "Géocodage coax" > ./geocoding_processus_coax.log

#Phase 1 : Géocodage
echo `date +"%Y-%m-%d %T"` "Phase 1 : Géocodage" >> ./geocoding_processus_coax.log

seq 0 $((${10} - 1)) | parallel --jobs ${10} --delay 2 python3.7 ./geocoding_pgsql_max_length.py $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} {}
python3.7 ./geocoding_pgsql_max_length.py $1 $2 $3 $4 $5 $6 $7 $8 $9

psql -c "$stat_request" >> ./geocoding_processus_coax.log

#Phase 2 : Normalisation des adresses
echo `date +"%Y-%m-%d %T"` "Phase 2 : Normalisation des adresses" >> ./geocoding_processus_coax.log

psql < ../sql/Normalisation_adresses_coax.sql

psql -c "$stat_request" >> ./geocoding_processus_coax.log

#Phase 3 : Géocodage
echo `date +"%Y-%m-%d %T"` "Phase 3 : Géocodage"  >> ./geocoding_processus_coax.log

seq 0 $((${10} - 1)) | parallel --jobs ${10} --delay 2 python3.7 ./geocoding_pgsql_max_length.py $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} {}
python3.7 ./geocoding_pgsql_max_length.py $1 $2 $3 $4 $5 $6 $7 $8 $9

psql -c "$stat_request" >> ./geocoding_processus_coax.log

echo `date +"%Y-%m-%d %T"` "Fin d'exécution du script"  >> ./geocoding_processus_coax.log
