#!/bin/bash
# params : pguser pgdatabase_toCreate (pgdatabase_template)

if [ $1 ] && [ $2 ]
then
  pg_isready
  if [ $? -eq 0 ]
  then
    echo Creation de la base $2 via l\'utilisateur $1

    psql -U $1 -c "DROP DATABASE IF EXISTS $2;"
    if [ $? -ne 0 ]
    then
      echo "Fail !"
      exit 1
    fi

    if [ $3 ]
    then
      psql -U $1 -c "CREATE DATABASE $2 \
          WITH \
          TEMPLATE = $3 \
          OWNER = postgres \
          ENCODING = 'UTF8' \
          LC_COLLATE = 'fr_FR.UTF-8' \
          LC_CTYPE = 'fr_FR.UTF-8' \
          TABLESPACE = pg_default \
          CONNECTION LIMIT = -1;"
    else
      psql -U $1 -c "CREATE DATABASE $2 \
          WITH \
          OWNER = postgres \
          ENCODING = 'UTF8' \
          LC_COLLATE = 'fr_FR.UTF-8' \
          LC_CTYPE = 'fr_FR.UTF-8' \
          TABLESPACE = pg_default \
          CONNECTION LIMIT = -1;"
    fi

    if [ $? -eq 0 ]
    then
      echo "Success"
    else
      echo "Fail !"
      exit 1
    fi

  else
    echo "Postgres refuse les connexions !"
    exit 1
  fi

else
  echo "Les paramètres utilisateur de connexion et nom de la base de données sont attendus. Il est possible de passer en troisième paramètre la base utilisée comme modèle."
  echo "ex : $ ./create_database.sh user db_name (template)"
  exit 1
fi
