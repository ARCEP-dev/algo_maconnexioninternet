\timing

--- Réinitialisation : Suppression de toutes les entités de la table eligibilite.actuel ayant pour techno_id celui de la techno Cuivre.
DELETE FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code = 'CU');

---Maintenance de la base
REFRESH MATERIALIZED VIEW reseau_cu.pc_sr_nra;
REFRESH MATERIALIZED VIEW adresse.base_imb;

VACUUM FULL ANALYZE reseau_cu.nra;
VACUUM FULL ANALYZE reseau_cu.oc_nra;
VACUUM FULL ANALYZE reference.techno;
VACUUM FULL ANALYZE reseau_cu.oc_pc_sans_service;
VACUUM FULL ANALYZE reseau_cu.oc_ld_sans_service;

REINDEX TABLE reseau_cu.ld;
REINDEX TABLE reseau_cu.pc;
REINDEX TABLE reference.techno;
REINDEX TABLE reseau_cu.oc_pc_sans_service;
REINDEX TABLE reseau_cu.oc_ld_sans_service;


BEGIN;
---Cas des immeubles dont le code_ban ne se retrouve pas dans les ld géocodées

---Creation d'une table temporaire utilisée uniquement dans ce script
DROP TABLE IF EXISTS eli_cu_imb;
CREATE TABLE eli_cu_imb (
  id serial,
  immeuble_id integer NOT NULL,
  geom geometry,
  nra_id integer DEFAULT NULL,
  pc_id integer DEFAULT NULL,
  pc_affaiblissement real DEFAULT NULL,
  distance_pc_ld integer DEFAULT NULL,
  CONSTRAINT eli_cu_imb_pkey PRIMARY KEY (id)
);

-- AJout des immeubles dont les code_ban ne se retrouvent pas dans les lignes géocodées
INSERT INTO eli_cu_imb (immeuble_id, geom)
SELECT imb_id, imb_geom
FROM adresse.base_imb
WHERE NOT EXISTS (SELECT 1 FROM reseau_cu.ld WHERE ld.code_ban = base_imb.addr_code)
AND NOT EXISTS (SELECT 1 FROM reseau_fo.zlin_imb WHERE zlin_imb.code_imb = base_imb.imb_code);


-- Recherche de la ligne cuivre (ld) la plus proche dans un rayon de 200 mètres pour récupérer son pc_id et nra_id.
UPDATE eli_cu_imb
SET (pc_id, nra_id) = (
  SELECT ld.pc_id, nra_id
  FROM reseau_cu.ld
  INNER JOIN reseau_cu.pc_sr_nra ON pc_sr_nra.pc_id = ld.pc_id
  INNER JOIN reseau_cu.pc ON pc.id = ld.pc_id
  WHERE ST_DWithin(ld.geom, eli_cu_imb.geom, 200)
  ORDER BY ST_Distance(ld.geom, eli_cu_imb.geom) ASC, pc.affaiblissement DESC
  LIMIT 1);

-- Si aucune ligne cuivre n'a été trouvée dans les 200 mètres, recherche de la ligne cuivre (ld) la plus proche dans un rayon de 500 mètres pour récupérer son pc_id et nra_id.
UPDATE eli_cu_imb
SET (pc_id, nra_id) = (
  SELECT ld.pc_id, nra_id
  FROM reseau_cu.ld
  INNER JOIN reseau_cu.pc_sr_nra ON pc_sr_nra.pc_id = ld.pc_id
  INNER JOIN reseau_cu.pc ON pc.id = ld.pc_id
  WHERE ST_DWithin(ld.geom, eli_cu_imb.geom, 500)
  ORDER BY ST_Distance(ld.geom, eli_cu_imb.geom) ASC, pc.affaiblissement DESC
  LIMIT 1)
  WHERE nra_id IS NULL OR pc_id IS NULL;

CREATE INDEX IF NOT EXISTS eli_cu_imb_nra_id ON eli_cu_imb USING btree (nra_id NULLS FIRST);
CREATE INDEX IF NOT EXISTS eli_cu_imb_pc_id ON eli_cu_imb USING btree (pc_id NULLS FIRST);
CREATE INDEX IF NOT EXISTS eli_cu_imb_imb_id ON eli_cu_imb USING btree (immeuble_id NULLS FIRST);
CREATE INDEX IF NOT EXISTS eli_cu_imb_id ON eli_cu_imb USING btree (id NULLS FIRST);

-- Pour les immeubles qui seraient trop loin d'une ligne cuivre (plus de 500 m), recherche du pc le plus proche dans un rayon de 2 500 m.
UPDATE eli_cu_imb
SET (pc_id, nra_id) = (
  SELECT pc.id, nra_id
  FROM reseau_cu.pc
  INNER JOIN reseau_cu.pc_sr_nra ON pc_sr_nra.pc_id = pc.id
  WHERE ST_DWithin(pc.geom, eli_cu_imb.geom, 2500)
  ORDER BY ST_Distance(pc.geom, eli_cu_imb.geom) ASC, pc.affaiblissement DESC
  LIMIT 1)
WHERE nra_id IS NULL OR pc_id IS NULL;

-- Suppression des immeubles qui n'auraient pas eu de pc_id.
DELETE FROM eli_cu_imb WHERE pc_id IS NULL;

-- Mise à jour de la colonne pc_affaiblissement de l'immeuble, ainsi que le calcul de la longueur entre l'immeuble et son pc
UPDATE eli_cu_imb AS imb
SET (pc_affaiblissement, distance_pc_ld) = (
  SELECT pc.affaiblissement, ST_Distance(pc.geom, imb.geom)
  FROM reseau_cu.pc
  WHERE pc.id = imb.pc_id
  );

-- Pour une même adresse, on récupère le pc qui présente l'affaiblissement le plus important.
DROP TABLE IF EXISTS pc_max_aff;
CREATE TABLE pc_max_aff AS (
  SELECT code_ban, array_agg(pc.id)::integer[] AS list_pc_id, MAX(pc.affaiblissement) AS pc_affaiblissement_max, null::integer AS pc_id_affaiblissement_max, null::geometry AS pc_geom_affaiblissement_max
  FROM reseau_cu.pc
  LEFT JOIN reseau_cu.ld ON ld.pc_id = pc.id
  GROUP BY code_ban
);

UPDATE pc_max_aff
SET (pc_id_affaiblissement_max, pc_geom_affaiblissement_max) = (SELECT id, geom FROM reseau_cu.pc WHERE id = ANY (list_pc_id) AND pc.affaiblissement = pc_affaiblissement_max LIMIT 1);


-- Cas des immeubles dont les code_ban se retrouvent dans les ld géocodées

-- AJout des immeubles dont les code_ban se retrouvent dans les lignes géocodées
INSERT INTO eli_cu_imb (immeuble_id, geom, nra_id, pc_id, pc_affaiblissement, distance_pc_ld)
SELECT base_imb.imb_id, imb_geom, pc_sr_nra.nra_id, pc_max_aff.pc_id_affaiblissement_max, pc_max_aff.pc_affaiblissement_max, ST_Distance(ST_Transform(pc_geom_affaiblissement_max, 3857), ST_Transform(imb_geom, 3857))::integer
FROM adresse.base_imb
INNER JOIN pc_max_aff ON pc_max_aff.code_ban = addr_code
INNER JOIN reseau_cu.ld ON ld.code_ban = addr_code
INNER JOIN reseau_cu.pc_sr_nra ON pc_sr_nra.pc_id = pc_max_aff.pc_id_affaiblissement_max
WHERE NOT EXISTS (SELECT 1 FROM reseau_fo.zlin_imb WHERE zlin_imb.code_imb = base_imb.imb_code)
GROUP BY base_imb.imb_id, addr_code, imb_geom, pc_sr_nra.nra_id, pc_max_aff.pc_id_affaiblissement_max, pc_max_aff.pc_affaiblissement_max, pc_geom_affaiblissement_max;

-- Ajout des immeubles dont le code BAN se retrouve dans les ld géocodées, avec le code du pc, du nra, l'affaiblissement, ainsi que le calcul de la distance entre immeuble et pc.
/* La fonction calcul_affaiblissement_cuivre est définie dans le script "CREATE_Structure.sql" et permet de calculer l'affaiblissement de la ligne cuivre à l'immeuble à partir des affaiblissement au Point de Concentration
   La fonction calcul_debit_cuivre permet de calculer le débit cuivre à l'immeuble à partir de l'affaiblissement de la ligne à l'immeuble. La fonction va dépendre de la technologie du NRA (ADSL/VDSL) précisée par les opérateurs d'infrastructures et les opérateurs commerciaux.*/
INSERT INTO eligibilite.actuel (immeuble_id, operateur_id, techno_id, debit_montant, debit_descendant)
SELECT immeuble_id, oc.operateur_id, techno.id,
	calcul_debit_cuivre((CASE
		WHEN nra.vdsl AND techno_dsl = 1 THEN 'VDSL2'
		ELSE 'ADSL'
		END)::varchar(5), calcul_affaiblissement_cuivre(pc_affaiblissement, distance_pc_ld)::real, 'up'::varchar(4)),
	calcul_debit_cuivre((CASE
		WHEN nra.vdsl AND techno_dsl = 1 THEN 'VDSL2'
		ELSE 'ADSL'
		END)::varchar(5), calcul_affaiblissement_cuivre(pc_affaiblissement, distance_pc_ld)::real, 'down'::varchar(4))
FROM eli_cu_imb
INNER JOIN reseau_cu.nra AS nra ON nra.id = eli_cu_imb.nra_id
INNER JOIN reseau_cu.oc_nra AS oc ON oc.nra_id = nra.id
INNER JOIN reference.techno ON techno.code = 'CU';

-- Récap
SELECT 'eli_cu_imb' AS "table", COUNT(*) FROM eli_cu_imb
UNION
SELECT 'reseau_cu.ld' AS "table", COUNT(*) FROM reseau_cu.ld
UNION
SELECT 'reseau_cu.oc_nra' AS "table", COUNT(*) FROM reseau_cu.oc_nra
UNION
SELECT 'eligibilite.actuel/cu' AS "table", COUNT(*) FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code = 'CU')
ORDER BY "table";

COMMIT;
