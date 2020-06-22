
## Description des scripts de géocodage

**[Création de base de données vide - (create_database.sh)](#create_databasesh)**

**[Géocodage des données en base avec distance limite - (geocoding_pgsql_max_length.py)](#geocoding_pgsql_max_lengthpy)**

**[Processus de géocodage *global* - (geocoding_processus_{coax,cu,fo}.sh)](#geocoding_processus_*sh)**

**[Processus de géocodage coax - (geocoding_processus_coax.sh)](#geocoding_processus_coaxsh)**

**[Processus de géocodage cu - (geocoding_processus_cu.sh)](#geocoding_processus_cush)**

**[Processus de géocodage fo - (geocoding_processus_fo.sh)](#geocoding_processus_fosh)**

## ./create_database.sh

Script permettant de créer une base de données.

### Lancement
```sh
./create_database.sh user dbname template
```

### Paramètres
- **user** : utilisateur utilisé pour la création de la base
- **dbname** : nom de la base à créer
- **template*** : nom de la base existante servant de modèle

\* : facultatif.

### Retours

**Si succès de création de la base de données**
```
Success
```

### Retours sur erreur

**Requête SQL en échec**
```
Fail !
```

**Instance postgres non prête**
```
Postgres refuse les connexions !
```

**Nombre de paramètres insuffisant**
```
Les paramètres utilisateur de connexion et nom de la base de données sont attendus. Il est possible de passer en troisième paramètre la base utilisée comme modèle.
ex : $ ./create_database.sh user pgdatabase (template)
```

---

#### ./geocoding_pgsql_max_length.py

Script générique de géocodage des lignes cuivre (reseau_cu.ld), des immeubles fibre (reseau_fo.imb) et des adresses coax (reseau_coax.adresse).

##### Principe

Lie des entités depuis une base de données et essaie de géocoder.

##### Dépendances

- requests
- json
- \_pg

##### Lancement
```sh
./geocoding_pgsql.py pghost pgport pgdatabase pguser pgpassword api_url schema table score_min parall_workers parall_id
```

##### Paramètres
- **pghost** : adresse IP du serveur de base de données
- **pgport** : port de l'instance de la base de données
- **pgdatabase** : nom de la base de données
- **pguser** : utilisateur de la base de données
- **pgpassword** : mot de passe de l'utilisateur de la base de données
- **api_url** : url de l'API BAN à utiliser (format : 'http://xx.xx.xx.xx/search/')
- **schema** : schéma de la table à géocoder {reseau_cu, reseau_fo, reseau_coax}
- **table** : table à géocoder {ld, imb, adresse}
- **score_min*** : Score minimum acceptable pour géocoder [defaut : 0.6]
- **parall_workers*** : nombre d'instance lancées dans le cas de parallélisation du géocodage
- **parall_id*** : identifiant de l'instance (0 pour la première)

\* : facultatif.

##### Fonctionnement

Selectionne les entités en base, une par une, et réalise un appel sur l'API de géocodage. Puis met à jour l'entité en question.

**Entités prises en compte :**

```sql
code_ban IS NULL AND (geocoding_failure IS False OR geocoding_failure IS NULL)
```
donc n'ayant pas de code_ban et n'étant pas en erreur de géocodage.

**Données prises en compte :**

- numero_voie
- complement_voie
- type_voie
- nom_voie
- code_insee
- x
- y

**Succès**

- si cuivre ou fibre sans géométrie ou coax sans géométrie : mise à jour du code ban et de la géométrie
- sinon, mise à jour du code ban

**Echec**

SET geocoding_failure = True

##### Retours

**Aucune entité à traiter**
```
No address to process !
```

**Plus entité à traiter**
```
No more address to process !
```

##### Retours sur erreur

**Nombre de paramètres insuffisant (<9)**
```
Error ! Not enough params.\r\nNeed : pghost pgport pgdatabase pguser pgpassword api_url schema table score_min parall_workers parall_id
```

**Test connexion à la base de données**

- Mauvaise IP :
```
could not connect to server: Connection timed out
        Is the server running on host "xx.xx.xx.xx" and accepting
        TCP/IP connections on port xx?
```

- Mauvais port :
```
could not connect to server: Connection refused
        Is the server running on host "xx.xx.xx.xx" and accepting
        TCP/IP connections on port xx?
```

- Mauvaise base de données :
```
FATAL:  la base de données « xxx » n'existe pas
```

- Mauvais utilisateur / mot de passe :
```
FATAL:  authentification par mot de passe échouée pour l'utilisateur  « xxx »
```

**Test BAN API connexion**
- API joingnable mais retournant un code http > 200 :
```
API BAN error ! http_status_code=xxx
```

- Les autres cas :
```
API BAN error !
```

**Test schema - table**
```
No match for table xxx in schema xxx !
```


Surcouche de géocodage avec distance limite.
Une variable *maxLength* est définie dont la valeur est spécifique pour chaque technologie.

---

### Géocodage
#### geocoding_processus_{coax,cu,fo}.sh

Les trois scripts de processus de géocodage fonctionnent sensiblement pareil :
- Phase 1 : Géocodage
- Phase 2 : Normalisation des adresses
- Phase 3 : Géocodage

##### Lancement
```sh
./geocoding_processus_{coax,cu,fo}.sh pghost pgport pgdatabase pguser pgpassword api_url schema table score_min parall_workers
```

##### Paramètres
- **pghost** : adresse IP du serveur de base de données
- **pgport** : port de l'instance de la base de données
- **pgdatabase** : nom de la base de données
- **pguser** : utilisateur de la base de données
- **pgpassword** : mot de passe de l'utilisateur de la base de données
- **api_url** : url de l'API BAN à utiliser (format : 'http://xx.xx.xx.xx/search/')
- **schema** : schéma de la table à géocoder {reseau_cu, reseau_fo, reseau_coax}
- **table** : table à géocoder {ld, imb, adresse}
- **score_min*** : Score minimum acceptable pour géocoder [defaut : 0.6]
- **parall_workers*** : nombre d'instance lancées dans le cas de parallélisation du géocodage

##### Géocodage

Lancement en parallèle de x workers de géocodage python (./geocoding_pgsql.py)

Lancement d'une seule instance de géocodage afin de traiter les quelques entités non traitées précédemment.

##### Normalisation des adresses

Utilisation des scripts de normalisation des adresses avant de relacer un deuxième passage de géocodage.


### ./geocoding_processus_coax.sh

Cf. geocoding_processus_*.sh

### ./geocoding_processus_cu.sh

Cf. geocoding_processus_*.sh

### ./geocoding_processus_fo.sh

Cf. geocoding_processus_*.sh

Spécifiquement pour la fibre est exécutée une quatrième phase : Géocodage inverse

### Géocodage inverse

Utilisation du script SQL ../sql/reverse_geocoding_fo.sql afin d'éffectuer un géocodage inverse des immeubles fibre.

---
