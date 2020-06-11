# Publication d'une base de donnée réduite et des scripts utilisés pour la production de la carte Ma connexion internet

## Contexte

L'Arcep a publié le 10 avril 2020 [Ma Connexion Internet](https://maconnexioninternet.arcep.fr/), une carte interactive en version bêta, qui permet de connaître les technologies d’accès à internet disponibles à leur adresse et d’être mieux informés sur les déploiements de la fibre.


Cette carte permet d’afficher, pour une adresse donnée :  
- l’ensemble des opérateurs disponibles ;  
- les technologies d’accès disponibles : réseau filaire (fibre, câble, ou cuivre (DSL)) ou réseau hertzien (4G fixe, HD et THD radio, satellite) ;  
- les débits maximum pouvant être obtenus.

La mise à disposition de la version bêta marque l’ouverture d’une phase de travail avec les acteurs du secteur dans laquelle l’Arcep fait appel aux contributeurs. Cette démarche de transparence et de partage se concrétise aujourd’hui par la publication d’un extrait de notre base de données et d’algorithmes permettant aux utilisateurs intéressés de reproduire et d’analyser les traitements réalisés par l’Arcep au cours de la production de Ma connexion internet.



## Composition du dépôt
### Dossier script
- [script_README.md](./script/script_README.md)
- geocoding_processus_coax.sh
- geocoding_processus_cu.sh
- geocoding_processus_fo.sh
- geocoding_pgsql_max_length.py
- geocoding_processus_{coax,cu,fo}.sh


### Dossier sql
- [sql_README.md](./script/sql_README.md)
- Normalisation_adresses_coax.sql
- Normalisation_adresses_cuivre.sql
- Normalisation_adresses_fibre.sql
- reverse_geocoding_fo.sql
- eligibilite_cell_actuel.sql
- eligibilite_coax_actuel
- eligibilite_cu_actuel
- eligibilite_fo_actuel.sql
- eligibilite_hz_actuel.sql
-  eligibilite_sat_actuel.sql
- data_workflow_db_addr_evol


### Base de données
- fichier ""BDD_reduite_MCI.tar" de la base de données réduite à télécharger sur la [page datagouv de MaConnexionInternet](https://www.data.gouv.fr/fr/datasets/ma-connexion-internet-beta/#resource-ccaf9b17-22be-4009-8269-9301c6f17cbf)

## Composition de la base de données
### Schémas de la base de données
- Admin
- Reference
- Reseau_cu
- Reseau_fo
- Reseau_coax
- Reseau_hz
- Reseau_cell
- Reseau_sat
- Adresse
- Eligibilite

## Jeu de données
Les données publiées sont les données d’entrée de Ma connexion internet pour une liste de communes dont les codes INSEE commencent soit par les 3 chiffres "452" (communes situées dans le département du Loiret) soit par les 4 chiffres "4700" (communes situées dans le département du Lot-et-Garonne). Ce jeu de données contient 122 364 immeubles et 652 224 locaux se répartissant dans les zones suivantes :  
-	1 commune de ZTD
-	11 communes en ZMD Privée
-	92 communes en ZMD publique

## Brouillage des valeurs des champs confidentiels
- les emplacements des points de concentration cuivre (reseau_cu.pc) ont été placés au centroïdes des communes;
- les emplacements des lignes cuivre (reseau_cu.la) ont été placés au centroïdes des communes;
- les emplacements des points de concentration câble (pcc.geom) ont été placés au centroïdes des communes;
- les activations des lignes (ld.active) ont été modifiés avec des données aléatoires;
- les types de présence des opérateurs commerciaux sur les NRA (oc_nra.type_presence) ont été modifiés avec des données aléatoires;
- les nombres de logements des immeubles du fichier IPE ont été modifiés en associant aléatoirement des nombres entre 1 et 10 (cette modification est due à des questions de droit de propriété intellectuelle).

## Restauration de la Base de donnée réduite publiée

Prérequis : Avoir installé postgreSQL.

Créer une base de donnée avec la commande
```sql
 CREATE DATABASE MCI_beta_reduite;
```
Pour restaurer la base placez vous dans le dossier contenant l'archive "BDD_reduite_MCI.tar" sur votre serveur et lancez la commande :

```pgsql
pg_restore -U pghost -d MCI_beta_reduite ./export_BDD_publi.tar
```
- pghost : adresse IP du serveur de base de données

## Contact

Adresse mail contributionmci@arcep.fr
