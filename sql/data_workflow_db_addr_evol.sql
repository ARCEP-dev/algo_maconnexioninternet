\timing

BEGIN;

---------------- REINITIALISATION ----------------
/*modifications ajoutées par rapport au script initial*/
---Mis à null des logements de la table FPB---
UPDATE adresse.fpb
SET code_ban=null
WHERE code_ban is not null;
REFRESH MATERIALIZED VIEW admin.com_dept_reg;
REFRESH MATERIALIZED VIEW adresse.base_imb;
REFRESH MATERIALIZED VIEW adresse.commune;

DROP SEQUENCE IF EXISTS adresse.adresse_id_seq CASCADE;
CREATE SEQUENCE adresse.adresse_id_seq;
/* fin de modifications ajoutées par rapport au script initial*/

-- Suppression de tous les immeubles et des adresses non originaires de la BAN
TRUNCATE adresse.adresse_immeuble, adresse.immeuble RESTART IDENTITY CASCADE;
DELETE FROM adresse.adresse WHERE source = 'fo';

-- Suppression des stats agrégées à l'epci et à l'iris.
TRUNCATE adresse.epci, adresse.iris RESTART IDENTITY;

-- Mise à Null des champs nbr_log & nbr_loc de la table adresse.adresse.
UPDATE adresse.adresse
SET (nbr_log, nbr_loc) = (null, null);

REINDEX TABLE adresse.adresse;
SELECT SETVAL('adresse.adresse_id_seq', (SELECT MAX(id) FROM adresse.adresse), true);

---------------- AJOUT DES IMMEUBLES FIBRE ----------------

-- Ajout immeubles fibre géocodés dans adresse.immeuble
/*
Les immeubles issues d'IPE, contenus dans reseau_fo.imb, qui sont géocodés sont ajoutés dans la table adresse.immeuble s'ils
ont le statut :
- Cible,
- Signé,
- En cours de déploiement,
- Raccordable sur demande,
- Déployé.
*/

DROP SEQUENCE IF EXISTS fibre_imb_id_seq;
CREATE SEQUENCE fibre_imb_id_seq;

CREATE TEMPORARY TABLE fibre_imb (
  id integer NOT NULL,
  fo_imb_id integer,
  geom geometry(POINT),
  code_imb character varying(30) NOT NULL,
  code_ban character varying(26),
  batiment character varying(70),
  numero_voie integer,
  complement_voie character varying(6),
  type_voie character varying(50),
  nom_voie character varying(50),
  code_insee character varying(5) NOT NULL,
  type_imb character varying(5),
  nbr_log integer,
  CONSTRAINT fibre_imb_pkey PRIMARY KEY (id)
) ON COMMIT DROP;

SELECT SETVAL('fibre_imb_id_seq', (SELECT MAX(id) FROM adresse.immeuble), true);

INSERT INTO fibre_imb (id, fo_imb_id, geom, code_imb, code_ban, batiment, numero_voie, complement_voie, type_voie, nom_voie, code_insee, type_imb, nbr_log)
SELECT nextval('fibre_imb_id_seq'), rfi.id, rfi.geom, rfi.code_imb, rfi.code_ban, rfi.batiment, rfi.numero_voie, rfi.complement_voie, rfi.type_voie, rfi.nom_voie, rfi.code_insee, rfi.type_imb, rfi.nbr_log
FROM reseau_fo.imb rfi 
LEFT JOIN reference.fibre_etat rfe_imb ON rfi.etat_id=rfe_imb.id
LEFT JOIN reseau_fo.pm rfp ON rfi.pm_id=rfp.id
LEFT JOIN reference.fibre_etat rfe_pm ON rfp.etat_id=rfe_pm.id
WHERE rfe_imb.code not in ('ABAN')
AND EXISTS (SELECT 1 FROM adresse.adresse WHERE adresse.code = rfi.code_ban);

CREATE INDEX fibre_imb_code_ban_idx_tmp ON fibre_imb USING btree (code_ban);

INSERT INTO adresse.immeuble (id, source, code, geom, iris_id, num_immeuble, code_insee, type, nbr_log, nbr_loc)
SELECT imb.id, 'fo', imb.code_imb, imb.geom, i.id, imb.batiment::varchar(25), imb.code_insee, imb.type_imb, imb.nbr_log, null
FROM fibre_imb AS imb
LEFT JOIN admin.iris AS i ON i.code_insee = imb.code_insee AND ST_Contains(i.geom, imb.geom);

INSERT INTO adresse.adresse_immeuble (adresse_id, immeuble_id)
SELECT a.id, i.id
FROM fibre_imb AS i, adresse.adresse AS a
WHERE i.code_ban = a.code;

-- La valeur du champ nbr_log de la table adresse.adresse est mise en cohérence avec la somme des immeubles fibres.
UPDATE adresse.adresse
SET (nbr_log, nbr_loc) = (
  SELECT SUM(i.nbr_log), SUM(i.nbr_loc)
  FROM adresse.immeuble i
  INNER JOIN adresse.adresse_immeuble ai ON ai.immeuble_id = i.id AND ai.adresse_id = adresse.id
)
WHERE EXISTS (SELECT 1 FROM fibre_imb WHERE fibre_imb.code_ban = adresse.code);

-- Récap
SELECT 'fibre_imb' AS "table", COUNT(*) FROM fibre_imb
UNION
SELECT 'reseau_fo.imb' AS "table", COUNT(*) FROM reseau_fo.imb
ORDER BY "table";

DROP SEQUENCE IF EXISTS fibre_imb_id_seq;
DROP TABLE IF EXISTS fibre_imb;


-- Ajout immeubles fibre non géocodés à adresse.*
/*
Les immeubles issues d'IPE, contenus dans reseau_fo.imb, qui ne sont pas géocodés sont ajoutés dans la table adresse.immeuble s'ils
ont le statut :
- Cible,
- Signé,
- En cours de déploiement,
- Raccordable sur demande,
- Déployé.
*/

CREATE SEQUENCE fibre_imb_id_seq;

CREATE TEMPORARY TABLE fibre_imb (
  id integer NOT NULL,
  fo_imb_id integer,
  geom geometry(POINT),
  code_imb character varying(30) NOT NULL,
  --code_ban character varying(26),
  batiment character varying(70),
  numero_voie integer,
  complement_voie character varying(6),
  type_voie character varying(50),
  nom_voie character varying(50),
  code_insee character varying(5) NOT NULL,
  type_imb character varying(5),
  nbr_log integer,
  CONSTRAINT fibre_imb_pkey PRIMARY KEY (id)
) ON COMMIT DROP;

SELECT SETVAL('fibre_imb_id_seq', (SELECT MAX(id) FROM adresse.immeuble), true);

INSERT INTO fibre_imb (id, fo_imb_id, geom, code_imb, batiment, numero_voie, complement_voie, type_voie, nom_voie, code_insee, type_imb, nbr_log)
SELECT nextval('fibre_imb_id_seq'), rfi.id, rfi.geom, rfi.code_imb, rfi.batiment, rfi.numero_voie, rfi.complement_voie, rfi.type_voie, rfi.nom_voie, rfi.code_insee, rfi.type_imb, rfi.nbr_log
FROM reseau_fo.imb rfi
LEFT JOIN reference.fibre_etat rfe_imb ON rfi.etat_id=rfe_imb.id
LEFT JOIN reseau_fo.pm rfp ON rfi.pm_id=rfp.id
LEFT JOIN reference.fibre_etat rfe_pm ON rfp.etat_id=rfe_pm.id
WHERE rfe_imb.code not in ('ABAN')
AND NOT EXISTS (SELECT 1 FROM adresse.adresse WHERE adresse.code = rfi.code_ban);

--- Création des adresses à partir des immeubles précédents
/*
Les précédents immeubles sont agrégés par regroupement sur les colonnes : 
numero_voie, complement_voie, type_voie, nom_voie, code_insee pour créer les adresses.
*/
CREATE TEMPORARY TABLE fibre_addr (
  id serial,
  nbr_imb_addr integer, -- Nombre d\'immeubles par adresse
  fibre_imb_id_list integer[],
  geom geometry(POINT),
  code_imb character varying(30) DEFAULT NULL,
  numero_voie integer,
  complement_voie character varying(6),
  type_voie character varying(50),
  nom_voie character varying(50),
  code_insee character varying(5) NOT NULL,
  nbr_log integer,
  --nbr_loc integer, données absentes d'IPE
  CONSTRAINT fibre_addr_pkey PRIMARY KEY (id)
) ON COMMIT DROP;

SELECT SETVAL('fibre_addr_id_seq', (SELECT MAX(id) FROM adresse.adresse), true);

INSERT INTO fibre_addr (nbr_imb_addr, fibre_imb_id_list, geom, numero_voie, complement_voie, type_voie, nom_voie, code_insee, nbr_log)
SELECT count(*), array_agg(id), null::geometry(Point), numero_voie, complement_voie, type_voie, nom_voie, code_insee, SUM(nbr_log)
FROM fibre_imb
WHERE nom_voie IS NOT NULL
GROUP BY numero_voie, complement_voie, type_voie, nom_voie, code_insee;

-- La géométrie des adresses correspond au centroïde de ses immeubles.
UPDATE fibre_addr
SET geom = (SELECT ST_Centroid(ST_Union(geom))
            FROM fibre_imb
            WHERE id = ANY (fibre_imb_id_list)
            GROUP BY fibre_imb_id_list[1]
          );

-- La valeur du champ code de la table adresse.adresse sera arbitrairement le code d'un immeuble de l'adresse.
UPDATE fibre_addr
SET code_imb = fibre_imb.code_imb
FROM fibre_imb
WHERE fibre_imb.id = fibre_addr.fibre_imb_id_list[1];

-- Récap
SELECT count(*), 'fibre_addr' AS table
FROM fibre_addr
UNION
SELECT count(*), 'fibre_imb' AS table
FROM fibre_imb;


INSERT INTO adresse.immeuble (id, source, code, geom, iris_id, num_immeuble, code_insee, type, nbr_log, nbr_loc)
SELECT id, 'fo', code_imb, geom, null, batiment::varchar(25), code_insee, type_imb, nbr_log, null
FROM fibre_imb;

INSERT INTO adresse.adresse (id, code, source, geom, nbr_log, nbr_loc, id_fantoir, numero, rep, nom_voie, nom_ld, code_insee, alias, nom_afnor, nom_commune)
SELECT fibre_addr.id, code_imb, 'fo', fibre_addr.geom, nbr_log, null, null, numero_voie, complement_voie::varchar(6),
  COALESCE(type_voie || ' ' || nom_voie, nom_voie)::varchar(50),
  null, c.code_insee, null, null, c.nom
FROM fibre_addr
INNER JOIN admin.commune c ON c.code_insee = fibre_addr.code_insee;

INSERT INTO adresse.adresse_immeuble (adresse_id, immeuble_id)
SELECT a.id, i.id
FROM fibre_imb i, fibre_addr a
WHERE i.id = ANY (fibre_imb_id_list);


SELECT SETVAL('adresse.adresse_id_seq', (SELECT MAX(id) FROM adresse.adresse), true);
DROP SEQUENCE IF EXISTS fibre_imb_id_seq;
DROP TABLE IF EXISTS fibre_imb;

-- Récap
SELECT 'adresse.immeuble' AS "table", COUNT(*) FROM adresse.immeuble
UNION
SELECT 'adresse.adresse' AS "table", COUNT(*) FROM adresse.adresse
UNION
SELECT 'adresse.adresse_immeuble' AS "table", COUNT(*) FROM adresse.adresse_immeuble
ORDER BY "table";

-- Stat
SELECT COUNT(*) || ' adresse(s) avec un seul immeuble' AS stats FROM adresse.adresse WHERE EXISTS (SELECT 1 FROM adresse.adresse_immeuble WHERE adresse_immeuble.adresse_id = adresse.id GROUP BY adresse_immeuble.adresse_id HAVING COUNT(*) = 1)
UNION
SELECT COUNT(*) || ' adresse(s) avec plusieurs immeubles' AS stats FROM adresse.adresse WHERE EXISTS (SELECT 1 FROM adresse.adresse_immeuble WHERE adresse_immeuble.adresse_id = adresse.id GROUP BY adresse_immeuble.adresse_id HAVING COUNT(*) > 1);

-- Erreur
SELECT COUNT(*) || ' immeuble(s) sans lien avec une adresse' AS erreur FROM adresse.immeuble WHERE NOT EXISTS (SELECT 1 FROM adresse.adresse_immeuble WHERE adresse_immeuble.immeuble_id = immeuble.id)
UNION
SELECT COUNT(*) || ' adresse(s) sans immeuble' AS erreur FROM adresse.adresse WHERE NOT EXISTS (SELECT 1 FROM adresse.adresse_immeuble WHERE adresse_immeuble.adresse_id = adresse.id);


COMMIT;

------------------------------------------------- APPAREILLEMENT DES ADRESSES DU FPB A LA BAN ---------------------------------------
BEGIN;
---Conversion dans le SRID local
UPDATE adresse.fpb
SET geom=ST_Transform(geom,2154)
WHERE code_insee not ilike '97%';

UPDATE adresse.fpb
SET geom=ST_Transform(geom,32620)
WHERE code_insee ilike '971%' or code_insee ilike '972%' or code_insee ilike '977%'or code_insee ilike '978%';

UPDATE adresse.fpb
SET geom=ST_Transform(geom,2972)
WHERE code_insee ilike '973%';

UPDATE adresse.fpb
SET geom=ST_Transform(geom,2975)
WHERE code_insee ilike '974%';

UPDATE adresse.fpb
SET geom=ST_Transform(geom,4471)
WHERE code_insee ilike '976%';

UPDATE adresse.fpb set rep=NULL where rep='';
UPDATE adresse.fpb set code_ban=NULL where code_ban='';

-- tag permettant de savoir quelle étape du géocodage a permis de ratacher le FPB
ALTER TABLE adresse.fpb add column if not exists source_geocodage character varying (30);

---Réinitialisation
UPDATE adresse.fpb set source_geocodage=NULL AND code_ban=NULL;

CREATE INDEX IF NOT EXISTS adresse_code_fpb_idx_tmp ON adresse.adresse USING btree ((adresse.code_insee || '-' || adresse.id_fantoir || '-' || adresse.numero || COALESCE(adresse.rep, '')));
CREATE INDEX IF NOT EXISTS adresse_fpb_geom_idx ON adresse.fpb USING gist (geom);
CREATE INDEX IF NOT EXISTS adresse_fpb_code_insee_idx ON adresse.fpb USING btree (code_insee);
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- Appareillement par identité des quadruplets
/*
Le premier tour d'appareillement va associer une code_ban à l'adresse du FPB si les quatres champs suivant sont égaux : code insee, id fantoir, numero de voie et repetition.
*/
UPDATE adresse.fpb
SET source_geocodage='match_fpb_ban', code_ban=  (SELECT code
				FROM adresse.adresse
				WHERE fpb.code = adresse.code_insee || '-' || adresse.id_fantoir || '-' || adresse.numero || COALESCE(adresse.rep, '') AND adresse.source='ban' AND adresse.id_fantoir is not null
				LIMIT 1)
				WHERE (code_ban IS NULL or code_ban=''); -- Si plusieurs adresses BAN matchent, on retient celle qui est la plus proche
DROP INDEX adresse.adresse_code_fpb_idx_tmp;

-- Apapreillement à 500 mètres avec conditions spécifiques
/*
Pour les adresse du FPB n'ayant pas pu être appareillées à la BAN lors du premeir tour, un second tour d'apapreillement va associer une code_ban à l'adresse du FPB si l'adresse BAN et l'adresse du FPB ont le même code insee, le même numéro de voie, la même répétition et si :
- soit la distance de levenshtein sur le nom de voie est au maximum de 7 et la distance entre la géométrie de l'adresse BAN et de l'immeuble fibre est inférieur à 70 mètres
- soit la distance de levenshtein sur le nom de voie est au maximum de 3 et la distance entre la géométrie de l'adresse BAN et de l'immeuble fibre est inférieur à 500 mètres
*/
UPDATE adresse.fpb afpb
SET source_geocodage='geocodage_inverse', code_ban = (	SELECT code
                FROM adresse.adresse
                WHERE
				ST_SRID(adresse.geom) = ST_SRID(afpb.geom)
                AND ST_DWithin(adresse.geom, afpb.geom, 500)
                AND afpb.code_insee = adresse.code_insee
                AND ((levenshtein(lower(adresse.nom_voie), lower(afpb.nom_voie)) <= 7 AND ST_DWithin(adresse.geom, afpb.geom, 70))
                OR (levenshtein(lower(adresse.nom_voie), lower(afpb.nom_voie)) <= 3))
                AND afpb.numero = adresse.numero
				AND (COALESCE(adresse.rep, '') = COALESCE(adresse.rep, ''))
                ORDER BY ST_Distance(adresse.geom, afpb.geom) ASC
                LIMIT 1)
				WHERE code_ban IS NULL AND geom IS NOT NULL;

-- Amélioration b / bis
UPDATE adresse.fpb afpb
SET source_geocodage='amelioration_b_bis_ban_fpb', code_ban = (SELECT code
                FROM adresse.adresse
                WHERE adresse.source = 'ban'
				AND adresse.rep='b'
                AND ST_SRID(adresse.geom) = ST_SRID(afpb.geom)
                AND ST_DWithin(adresse.geom, afpb.geom, 500)
                AND afpb.code_insee = adresse.code_insee
                AND ((levenshtein(lower(adresse.nom_voie), lower(afpb.nom_voie)) <= 7 AND ST_DWithin(adresse.geom, afpb.geom, 70))
                OR (levenshtein(lower(adresse.nom_voie), lower(afpb.nom_voie)) <= 3))
                AND afpb.numero = adresse.numero
                ORDER BY ST_Distance(adresse.geom, afpb.geom) ASC
                LIMIT 1)
				WHERE code_ban IS NULL AND geom IS NOT NULL and rep='bis';


-- Géocodage inverse 200 mètres (réallocation)
/*
Pour les adresse du FPB n'ayant pas pu être appareillées à la BAN lors du second tour, un dernier tout d'appareillement est effectué 
en associant l'adresse BAN la plus proche à l'adresse FPB si la distance entre les deux adresses est inférieure à 200 mètres 
et si les deux adresses se situent dans la même commune.
*/
UPDATE adresse.fpb afpb
SET source_geocodage='geocodage_inverse_200_metres', code_ban = (SELECT code
                FROM adresse.adresse
                WHERE ST_SRID(adresse.geom) = ST_SRID(afpb.geom)
                AND ST_DWithin(adresse.geom, afpb.geom, 200)
                AND afpb.code_insee = adresse.code_insee
                ORDER BY ST_Distance(adresse.geom, afpb.geom) ASC
                LIMIT 1)
				WHERE code_ban IS NULL AND geom IS NOT NULL;

DROP INDEX IF EXISTS adresse_fpb_geom_idx;
DROP INDEX IF EXISTS adresse_fpb_code_insee_idx;

SELECT source_geocodage, count(*) FROM adresse.fpb GROUP BY source_geocodage;

COMMIT;

BEGIN;
-- Association du nombre de locaux des adresses du FPB géocodées, aux adresses BAN correspondantes

CREATE INDEX IF NOT EXISTS adresse_fpb_code_ban_idx ON adresse.fpb USING btree (code_ban);

UPDATE adresse.adresse aa SET (nbr_log,nbr_loc)= 
	(SELECT SUM(af.nbr_log), SUM(af.nbr_loc)
	FROM adresse.fpb af 
	WHERE af.code_ban=aa.code)
WHERE
	aa.source='ban'
	AND aa.nbr_log is null AND aa.nbr_loc is null; 

DROP INDEX IF EXISTS adresse.adresse_fpb_code_ban_idx;
COMMIT;


------------------------------------------------- GENERATION DES IMMEUBLES BAN ---------------------------------------
/*
Afin de garder le même modèle de données pour tous les cas de figure, il faut à minima un immeuble par adresse.

Dans la zone très dense, pour toute adresse n'ayant pas d'immeuble et ayant un nbr_log ou nbr_loc non Null un immeuble est créé, qui a pour valeur de nbr_log et nbr_loc celles de son adresse.

Hors de la zone très dense, pour toute adresse n'ayant pas d'immeuble, ayant un nbr_log ou nbr_loc non Null et située à plus de 40 mètres de tout immeuble deja existant, un immeuble est créé, qui a pour valeur de nbr_log et nbr_loc celles de son adresse.
*/
BEGIN;

CREATE INDEX IF NOT EXISTS adresse_immeuble_code_insee_idx ON adresse.immeuble USING gist (geom);
CREATE INDEX IF NOT EXISTS adresse_immeuble_geom_idx ON adresse.immeuble USING gist (geom);

CREATE TEMPORARY TABLE ban_imb (
  id serial,
  addr_id integer,
  geom geometry(Point) NOT NULL,
  code_insee character varying(5) NOT NULL,
  nbr_log integer DEFAULT NULL,
  nbr_loc integer DEFAULT NULL,
  CONSTRAINT ban_imb_pkey PRIMARY KEY (id)
) ON COMMIT DROP;

SELECT SETVAL('ban_imb_id_seq', (SELECT MAX(id) FROM adresse.immeuble), true);


INSERT INTO ban_imb (addr_id, geom, code_insee, nbr_log, nbr_loc)
SELECT id, geom, code_insee, nbr_log, nbr_loc
FROM adresse.adresse aa
WHERE source = 'ban'
AND geom IS NOT NULL
AND (NOT EXISTS (SELECT 1 
				FROM adresse.immeuble ai 
				WHERE ST_SRID(ai.geom)=ST_SRID(aa.geom) AND ST_DWithin(ai.geom,aa.geom,40))
	OR aa.code_insee in (select acz.code_insee from admin.commune_zonage acz left join reference.commune_zonage_type rczt on acz.zonage_type_id=rczt.id WHERE rczt.nom='ZTD' and rczt.actif is true)
	) 
AND NOT EXISTS (SELECT 1
                FROM adresse.adresse_immeuble
                WHERE aa.id = adresse_id)
				;


DROP INDEX IF EXISTS adresse_immeuble_code_insee_idx;
DROP INDEX IF EXISTS adresse_fpb_code_ban_idx;

-- Récap
SELECT count(*), 'ban_imb' AS table
FROM ban_imb;

INSERT INTO adresse.immeuble (id, source, code, geom, code_insee, nbr_log, nbr_loc)
SELECT id, 'ban', md5('system')::character varying(6), geom, code_insee, nbr_log, nbr_loc
FROM ban_imb;

INSERT INTO adresse.adresse_immeuble (adresse_id, immeuble_id)
SELECT addr_id, id
FROM ban_imb;

COMMIT;


------------------------------------------------- 	FORMATAGE DU NOMBRE DE LOGEMENTS ET LOCAUX ET NETTOYAGE DES DONNEES ---------------------------------------

BEGIN;

-- Suppression des valeurs nbr_log et nbr_loc lorsqu'on n'a pas rattaché d'immeuble
UPDATE adresse.adresse aa SET nbr_log=0,nbr_loc=0 WHERE NOT EXISTS (SELECT 1 FROM adresse.adresse_immeuble aai WHERE aa.id=aai.adresse_id);

-- Corrections de valeurs
CREATE INDEX adresse_rep_idx ON adresse.adresse USING btree (rep) WHERE rep IS NOT NULL;

-- Mise à zéro des valeurs de log/loc Null
UPDATE adresse.immeuble
SET nbr_log = 0
WHERE nbr_log IS NULL;

UPDATE adresse.immeuble
SET nbr_loc = 0
WHERE nbr_loc IS NULL;

-- Mise à null des valeurs de nom_ld vides
UPDATE adresse.adresse
SET nom_ld = Null
WHERE nom_ld = '';

-- Mise à null des valeurs de répétition vides
UPDATE adresse.adresse
SET rep = Null
WHERE rep = '';

UPDATE adresse.adresse
SET rep = lower(rep);

UPDATE adresse.adresse
SET rep = 'quater'
WHERE rep IN ('qua', 'qa');

DROP INDEX IF EXISTS adresse.adresse_adresse_nbr_log_nbr_loc_tmp;
DROP INDEX IF EXISTS adresse.adresse_rep_idx;

REINDEX TABLE adresse.adresse;
REINDEX TABLE adresse.immeuble;
REINDEX TABLE adresse.adresse_immeuble;

REFRESH MATERIALIZED VIEW adresse.base_imb;

-- Calcul des stats de log/loc pour commune/departement/region
REFRESH MATERIALIZED VIEW adresse.commune;

-- Calcul des stats de log/loc pour epci
INSERT INTO adresse.epci (epci_id, nbr_log, nbr_loc)
SELECT epci.id, SUM(nbr_log), SUM(nbr_loc)
FROM adresse.commune
INNER JOIN admin.commune AS com ON com.id = commune_id
INNER JOIN admin.epci ON epci.id = com.epci_id
GROUP BY epci.id;

-- Calcul des stats de log/loc à l'iris
INSERT INTO adresse.iris (iris_id, nbr_log, nbr_loc)
SELECT iris.id, SUM(imb_nbr_log), SUM(imb_nbr_loc)
FROM admin.iris iris
LEFT JOIN adresse.base_imb imb ON ST_Contains(iris.geom, imb.imb_geom) AND ST_SRID(iris.geom) = ST_SRID(imb.imb_geom)
GROUP BY iris.id;


COMMIT;

-- Récap
SELECT 'adresse.adresse' AS "table", COUNT(*) FROM adresse.adresse
UNION
SELECT 'adresse.adresse_bati' AS "table", COUNT(*) FROM adresse.adresse_bati
UNION
SELECT 'adresse.adresse_immeuble' AS "table", COUNT(*) FROM adresse.adresse_immeuble
UNION
SELECT 'adresse.commune' AS "table", COUNT(*) FROM adresse.commune
UNION
SELECT 'adresse.departement' AS "table", COUNT(*) FROM adresse.departement
UNION
SELECT 'adresse.epci' AS "table", COUNT(*) FROM adresse.epci
UNION
SELECT 'adresse.fpb' AS "table", COUNT(*) FROM adresse.fpb
UNION
SELECT 'adresse.immeuble' AS "table", COUNT(*) FROM adresse.immeuble
UNION
SELECT 'adresse.iris' AS "table", COUNT(*) FROM adresse.iris
UNION
SELECT 'adresse.region' AS "table", COUNT(*) FROM adresse.region
ORDER BY "table";

-- Sources
SELECT 'adresse.adresse' AS "table", source, COUNT(*) FROM adresse.adresse GROUP BY source
UNION
SELECT 'adresse.immeuble' AS "table", source, COUNT(*) FROM adresse.immeuble GROUP BY source
ORDER BY "table", source;

-- Erreur
SELECT COUNT(*) || ' immeuble(s) sans lien avec une adresse' AS erreur FROM adresse.immeuble WHERE NOT EXISTS (SELECT 1 FROM adresse.adresse_immeuble WHERE adresse_immeuble.immeuble_id = immeuble.id);