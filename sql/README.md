## Description des scripts SQL

**[Normalisation des adresses pour la techno coax - (Normalisation_adresses_coax.sql)](#normalisation_adresses_coaxsql)**

**[Normalisation des adresses pour la techno cuivre - (Normalisation_adresses_cuivre.sql)](#normalisation_adresses_cuivresql)**

**[Normalisation des adresses pour la techno fibre - (Normalisation_adresses_fibre.sql)](#normalisation_adresses_fibresql)**

**[Géocodage Inverse de la fibre - (reverse_geocoding_fo.sql)](#reverse_geocoding_fosql)**

**[Génération de la base adresse/immeuble - (data_workflow_db_addr.sql)](#data_workflow_db_addrsql)**

**[Éligibilité actuelle de la techno cell - (eligibilite_cell_actuel.sql)](#eligibilite_cell_actuelsql)**

**[Éligibilité actuelle de la techno coax - (eligibilite_coax_actuel.sql)](#eligibilite_coax_actuelsql)**

**[Éligibilité actuelle de la techno cu - (eligibilite_cu_actuel.sql)](#eligibilite_cu_actuelsql)**

**[Éligibilité actuelle de la techno fo - (eligibilite_fo_actuel.sql)](#eligibilite_fo_actuelsql)**

**[Éligibilité actuelle de la techno hz - (eligibilite_hz_actuel.sql)](#eligibilite_hz_actuelsql)**

**[Éligibilité actuelle de la techno sat - (eligibilite_sat_actuel.sql)](#eligibilite_sat_actuelsql)**


### Normalisation des adresses (lors du géocodage)

Les différents scripts de normalisation des adresses ont un comportement assez semblable.

Passage en minuscules des adresses non géocodées. Création d'indexes, suppression des espaces multiples et caractères spéciaux.

Puis remplacement des abréviations par les noms longs (exemple : avenue pour av).

En fin d'exécution, passage à **Null** de *geocoding_failure*, suppression des indexes provisoires puis recalcule des indexes.

#### ./Normalisation_adresses_coax.sql

Normalisation des adresses du schéma coax. Affecte la table reseau_coax.adresse et sa colonne *nom_voie*.


#### ./Normalisation_adresses_cuivre.sql

Normalisation des adresses du schéma cu. Affecte la table reseau_cu.ld et sa colonne *nom_voie*.


#### ./Normalisation_adresses_fibre.sql

Normalisation des adresses du schéma fo. Affecte la table reseau_fo.imb et ses colonnes *type_voie* & *nom_voie*.

### Géocodage inverse

#### ./reverse_geocoding_fo.sql

Géocodage inverse des immeubles fibre en échec de géocodage.

L'opération consiste à associer un code ban à un immeuble en prenant en compte la distance géographique ainsi que la distance syntaxique dans la limite de 500 m.

Ce script n'est pas utilisé directement, il est appelé par le script bach de géocodage de la fibre.

---



### Création du référentiel d'immeubles, d'adresses et de locaux
#### ./data_workflow_db_addr.sql

Génération de la base adresses/immeubles

##### Préparation

Vidage en cascade des tables :
- adresse.adresse_immeuble,
- adresse.immeuble,

donc en cascade sont vidées :
- eligibilite.actuel,
- eligibilite.previsionnel.

Suppression de toutes les entités de la table *adresse.adresse* n'étant pas issues de la BAN.

Suppression des stats agrégées à l'iris, par un truncate de la table : adresse.iris.

Mise à Null des champs **nbr_log** & **nbr_loc** de la table *adresse.adresse*.



##### Ajout immeubles fibre géocodés dans adresse.immeuble

###### adresse.immeuble
Les immeubles issues d'IPE, contenus dans reseau_fo.imb, qui sont géocodés sont ajoutés dans la table *adresse.immeuble* s'ils ont le statut :
- Cible,
- Signé,
- En cours de déploiement,
- Raccordable sur demande,
- Déployé.

La valeur du champ **nbr_log** de l'IPE est conservée.

###### adresse.adresse
La valeur du champ **nbr_log** de la table *adresse.adresse* est mise en cohérence avec la somme des immeubles fibres.


##### Ajout immeubles fibre non géocodés à adresse.*

###### adresse.immeuble
Les immeubles issues d'IPE, contenus dans reseau_fo.imb, qui ne sont pas géocodés sont ajoutés dans la table *adresse.immeuble* s'ils ont le statut :
- Cible,
- Signé,
- En cours de déploiement,
- Raccordable sur demande,
- Déployé.

La valeur du champ **nbr_log** de l'IPE est conservée.

###### adresse.adresse
Les précédents immeubles sont agrégés par regroupement sur les colonnes : **numero_voie, complement_voie, type_voie, nom_voie, code_insee** pour créer les adresses.

La géométrie des adresses correspond au centroïde de ses immeubles.

La valeur du champ **nbr_log** de la table *adresse.adresse* est mis en cohérence avec la somme des immeubles fibres.

La valeur du champ **code** de la table *adresse.adresse* sera arbitrairement le code d'un immeuble de l'adresse.

##### Appareillement des adresses du FPB à la BAN

Afin de pouvoir faire des comparaisons géographique des conversion de SRID sont effectuées.

Le premier tour d'appareillement va associer une code_ban à l'adresse du FPB si les quatres champs suivant sont égaux : code insee, id fantoir, numero de voie et repetition.

Pour les adresse du FPB n'ayant pas pu être appareillées à la BAN lors du premeir tour, un second tour d'apapreillement va associer une code_ban à l'adresse du FPB si l'adresse BAN et l'adresse du FPB ont le même code insee, le même numéro de voie, la même répétition et si :
- soit la distance de levenshtein sur le nom de voie est au maximum de 7 et la distance entre la géométrie de l'adresse BAN et de l'immeuble fibre est inférieur à 70 mètres
- soit la distance de levenshtein sur le nom de voie est au maximum de 3 et la distance entre la géométrie de l'adresse BAN et de l'immeuble fibre est inférieur à 500 mètres

Suite à la modification sur la contrainte d'égalité de la répétition (les adresses yaant une répétition 'b' dans la BAN peuvent être associées aux adresses ayant une répérttition "bis" dans le FPB), le second tour d'apapreillement est relancé.

Pour les adresse du FPB n'ayant pas pu être appareillées à la BAN lors du second tour, un dernier tout d'appareillement est effectué en associant l'adresse BAN la plus proche à l'adresse FPB si la distance entre les deux adresses est inférieure à 200 mètres et si les deux adresses se situent dans la même commune.

##### Association des locaux des adresses du FPB géocodées aux adresses BAN correspondantes
Mise à jour des champs **nbr_log** & **nbr_loc** de la table *adresse.adresse* depuis les données du FPB en se basant sur les codes BAN.

##### Générer un immeuble "system" par adresse BAN si (nbr_log or nbr_loc) != null

Afin de garder le même modèle de données pour tous les cas de figure, il faut à minima un immeuble par adresse.

**Dans la zone très dense**, pour toute adresse :
- n'ayant pas d'immeuble,
- ayant un **nbr_log** ou **nbr_loc** non Null,

un immeuble est créé, qui a pour valeur de **nbr_log** et **nbr_loc** celles de son adresse.

**Hors de la zone très dense**, pour toute adresse :
- n'ayant pas d'immeuble,
- ayant un **nbr_log** ou **nbr_loc** non Null,
- située à plus de 40 mètres de tout immeuble,

un immeuble est créé, qui a pour valeur de **nbr_log** et **nbr_loc** celles de son adresse.


##### Correction de valeurs

Mise à Null des valeurs de répétition vides.
Passage en minuscules des valeurs de la colonne **rep**.


##### Finalisation

Recalcul des indexes.

Recalcul de la vue materialisée *adresse.base_imb*.

Recalcul de la vue materialisée *adresse.commune* qui permet le calcul des stats de log/loc pour region/departement/commune.

Peuplement des tables *adresse.epci* & *adresse.iris* des stats à l'EPCI et à l'IRIS.

##### Lancement
Placez vous dans le dossier contenant le fichier "data_workflow_db_addr_evol.sql" sur votre serveur et lancez la commande :

```plpgsql
psql -d pgdatabase -U pguser < ./data_workflow_db_addr_evol.sql
```

---

### Calcul des éligibilités

Les scripts SQL vont permettre de peupler la table éligibilité actuelle.
La table éligibilité prévisionnelle n'est actuellement pas utilisée.

Pour les technologies hertziennes, une limitation des débits montant et descendant est effectuée. Les valeurs maximum sont en dur dans les scripts.

<br/>

#### ./eligibilite_cell_actuel.sql

Suppression de toutes les entités de la table *eligibilite.actuel* ayant pour techno_id celui de la techno 4G Fixe.

##### Retraitement des polygones de couverture

Pour les polygones n'étant pas valides, correction des géométries afin qu'ils le deviennent.

Découpage des polygones en limitant leur nombre de sommets à 200.

Découpage des polygones à la commune.

Ajout de toutes les entités *adresse.immeuble* contenu dans les zones de couverture qui ne sont pas saturées.

##### Lancement
Placez vous dans le dossier contenant le fichier "eligibilite_cell_actuel.sql" sur votre serveur et lancez la commande :
```plpgsql
psql -d pgdatabase -U pguser < ./eligibilite_cell_actuel.sql
```

<br/>

#### ./eligibilite_coax_actuel.sql

Suppression de toutes les entités de la table *eligibilite.actuel* ayant pour techno_id celui de la techno Coaxial.

##### Préparation des données commerciales

Génération de la présence commerciale au **pcc** pour ceux qui auraient communiqué à la **tdr**.

##### Éligibilité à l'adresse

Ajout des entités qui sont géocodées.

##### Éligibilité à l'ampli

Ajout des entités *adresse.adresse* non présentes précédemment et qui sont situées à moins de 50 mètres d'un ampli n'ayant pas d'adresse rattachée.

##### Lancement
Placez vous dans le dossier contenant le fichier "eligibilite_coax_actuel.sql" sur votre serveur et lancez la commande :
```plpgsql
psql -d pgdatabase -U pguser < ./eligibilite_coax_actuel.sql
```

<br/>

#### ./eligibilite_cu_actuel.sql

Suppression de toutes les entités de la table *eligibilite.actuel* ayant pour techno_id celui de la techno Cuivre.

##### Cas des immeubles dont le code_ban ne se retrouve pas dans les ld géocodées

Sélection des immeubles dont le code ban de l'adresse ne se retrouve pas dans les ld géocodées.

Recherche de la ligne cuivre (ld) la plus proche dans un rayon de 500 mètres pour récupérer son pc_id et nra_id.

Pour les immeubles qui seraient trop loin d'une ligne cuivre (plus de 500 m), recherche du pc le plus proche dans un rayon de 2.500 m.

Suppression des immeubles qui n'auraient pas eu de pc_id.

Mise à jour de la colonne **pc_affaiblissement** de l'immeuble, ainsi que le calcul de la longueur entre l'immeuble et son pc.

Pour une même adresse, on récupère le pc qui présente l'affaiblissement le plus important.

##### Cas des immeubles dont le code_ban se retrouve dans les ld géocodées

Ajout des immeubles dont le code BAN se retrouve dans les ld géocodées, avec le code du pc, du nra, l'affaiblissement, ainsi que le calcul de la distance entre immeuble et pc.

##### Finalisation

Ces deux "sous-traitements" peuplent une même table temporaire.

Ajout dans la table *eligibilite.actuel* des entités précédentes en calculant affaiblissement et débit en fonction des technologies xDSL.

##### Remarque

Les immeubles sont soit en VDSL soit par défaut en ADSL.

##### Lancement
Placez vous dans le dossier contenant le fichier "eligibilite_cu_actuel.sql" sur votre serveur et lancez la commande :
```plpgsql
psql -d pgdatabase -U pguser < ./eligibilite_cu_actuel.sql
```

<br/>

#### ./eligibilite_fo_actuel.sql

Suppression de toutes les entités de la table *eligibilite.actuel* ayant pour techno_id celui de la techno FO.

Ajout de toutes les entités *reseau_fo.imb* dont le statut est Raccordable sur demande ou Déployé et dont le PM est à l'état déployé et dont la date de mise en service commerciale est au plus celle du jour.

##### Lancement
Placez vous dans le dossier contenant le fichier "eligibilite_fo_actuel.sql" sur votre serveur et lancez la commande :
```plpgsql
psql -d pgdatabase -U pguser < ./eligibilite_fo_actuel.sql
```

<br/>

#### ./eligibilite_hz_actuel.sql

Suppression de toutes les entités de la table *eligibilite.actuel* ayant pour techno_id celui des technos {THDRadio,WiMax,WiFi,WiFiMax}.

Ajout de toutes les entités *adresse.immeuble* contenu dans les zones de couverture.

##### Lancement
Placez vous dans le dossier contenant le fichier "eligibilite_hz_actuel.sql" sur votre serveur et lancez la commande :
```plpgsql
psql -d pgdatabase -U pguser < ./eligibilite_hz_actuel.sql
```

<br/>

#### ./eligibilite_sat_actuel.sql

Suppression de toutes les entités de la table *eligibilite.actuel* ayant pour techno_id celui de la techno SAT.

##### Retraitement des polygones de couverture

Pour les polygones n'étant pas valides, correction des géométries afin qu'ils le deviennent.

Découpage des polygones en limitant leur nombre de sommets à 200.

Découpage des polygones à la commune.

Ajout de toutes les entités *adresse.immeuble* contenu dans les zones de couverture.

##### Lancement
Placez vous dans le dossier contenant le fichier "eligibilite_sat_actuel.sql" sur votre serveur et lancez la commande :
```plpgsql
psql -d pgdatabase -U pguser < ./eligibilite_sat_actuel.sql
```
---
