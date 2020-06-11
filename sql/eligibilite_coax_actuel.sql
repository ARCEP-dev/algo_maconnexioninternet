\timing
BEGIN;

--- Réinitialisation : Suppression de toutes les entités de la table eligibilite.actuel ayant pour techno_id celui de la techno Coaxiale.
DELETE FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code = 'COAX');

-- Génération de la présence commerciale au pcc pour ceux qui auraient communiqué à la tdr.
INSERT INTO reseau_coax.oc_pcc (operateur_id, pcc_id, debit_montant, debit_descendant, fichier_id)
SELECT oc_tdr.operateur_id, pcc.id, oc_tdr.debit_montant, oc_tdr.debit_descendant, oc_tdr.fichier_id
FROM reseau_coax.oc_tdr
INNER JOIN reseau_coax.pcc ON pcc.tdr_id = oc_tdr.tdr_id;

---Creation de tables temporaires utilisées uniquement dans ce script
CREATE TEMPORARY TABLE eli_coax_addr (
  id serial,
  adresse_id integer DEFAULT NULL,
  pcc_id integer DEFAULT NULL,
  CONSTRAINT eli_coax_addr_pkey PRIMARY KEY (id)
) ON COMMIT DROP;

CREATE TEMPORARY TABLE eli_coax_addr_pcc (
  id serial,
  adresse_id integer DEFAULT NULL,
  pcc_id integer DEFAULT NULL,
  CONSTRAINT eli_coax_addr_pcc_pkey PRIMARY KEY (id)
) ON COMMIT DROP;


-- Eligibilite à l'adresse
---Ajout dans une table temporaire des entités qui sont géocodées.
INSERT INTO eli_coax_addr (adresse_id, pcc_id)
SELECT adresse.id AS adresse_id, coaddr.pcc_id AS pcc_id
FROM reseau_coax.adresse AS coaddr
INNER JOIN adresse.adresse ON adresse.code = coaddr.code_ban
GROUP BY adresse.id, pcc_id; -- Limitation : quelques doublons lorsque plusieurs ampli à une même adresse.


CREATE INDEX IF NOT EXISTS eli_coax_addr_adresse_id_idx ON eli_coax_addr USING btree (adresse_id);
CREATE INDEX IF NOT EXISTS eli_coax_addr_pcc_id_idx ON eli_coax_addr USING btree (pcc_id);

--- Ajout des informations d'éligibilité au câble des entités adresse.immeuble géocodées
INSERT INTO eligibilite.actuel (immeuble_id, operateur_id, techno_id, debit_montant, debit_descendant)
SELECT base_imb.imb_id, oc_pcc.operateur_id, techno.id, oc_pcc.debit_montant, oc_pcc.debit_descendant
FROM eli_coax_addr
INNER JOIN adresse.base_imb ON base_imb.addr_id = eli_coax_addr.adresse_id
INNER JOIN reseau_coax.oc_pcc ON oc_pcc.pcc_id = eli_coax_addr.pcc_id
INNER JOIN reference.techno ON techno.code = 'COAX'
WHERE NOT EXISTS (SELECT 1 FROM reseau_coax.oc_prise_sans_service AS ws WHERE ws.operateur_id = oc_pcc.operateur_id AND ws.code_ban = base_imb.addr_code);


-- Eligibilite à l'ampli
---Ajout dans une table temporaire des entités non présentes précédemment et dont les adresses sont situées à moins de 50 mètres d'un ampli n'ayant pas d'adresse rattachée.
INSERT INTO eli_coax_addr_pcc (adresse_id)
SELECT adresse.id AS adresse_id
FROM adresse.adresse
INNER JOIN reseau_coax.tdr ON ST_Contains(tdr.geom, adresse.geom)
INNER JOIN reseau_coax.pcc ON ST_DWithin(pcc.geom, adresse.geom, 50)
INNER JOIN reseau_coax.oc_pcc ON oc_pcc.pcc_id = pcc.id
WHERE NOT EXISTS (SELECT 1 FROM eli_coax_addr WHERE eli_coax_addr.adresse_id = adresse.id)
AND NOT EXISTS (SELECT 1 FROM reseau_coax.adresse WHERE adresse.pcc_id = pcc.id)
GROUP BY adresse.id;


CREATE INDEX IF NOT EXISTS eli_coax_addr_adresse_pcc_id_idx ON eli_coax_addr_pcc USING btree (adresse_id);

UPDATE eli_coax_addr_pcc
SET pcc_id = (
  SELECT pcc.id
  FROM reseau_coax.pcc
  INNER JOIN adresse.adresse ON adresse.id = adresse_id AND ST_DWithin(pcc.geom, adresse.geom, 50)
  ORDER BY ST_Distance(pcc.geom, adresse.geom) ASC
  LIMIT 1)
WHERE pcc_id IS NULL;

---Ajout des informations d'éligibilité au câble des entités adresse.immeuble non présentes précédemment et dont les adresses sont situées à moins de 50 mètres d'un ampli n'ayant pas d'adresse rattachée.
INSERT INTO eligibilite.actuel (immeuble_id, operateur_id, techno_id, debit_montant, debit_descendant)
SELECT base_imb.imb_id, oc_pcc.operateur_id, techno.id, oc_pcc.debit_montant, oc_pcc.debit_descendant
FROM eli_coax_addr_pcc
INNER JOIN adresse.base_imb ON base_imb.addr_id = eli_coax_addr_pcc.adresse_id
INNER JOIN reseau_coax.oc_pcc ON oc_pcc.pcc_id = eli_coax_addr_pcc.pcc_id
INNER JOIN reference.techno ON techno.code = 'COAX'
WHERE NOT EXISTS (SELECT 1 FROM reseau_coax.oc_prise_sans_service AS ws WHERE ws.operateur_id = oc_pcc.operateur_id AND ws.code_ban = base_imb.addr_code);


-- Récap
SELECT 'eli_coax_addr' AS "table", COUNT(*) FROM eli_coax_addr
UNION
SELECT 'eli_coax_addr_pcc' AS "table", COUNT(*) FROM eli_coax_addr_pcc
UNION
SELECT 'reseau_coax.adresse' AS "table", COUNT(*) FROM reseau_coax.adresse
UNION
SELECT 'eligibilite.actuel/coax' AS "table", COUNT(*) FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code = 'COAX')
ORDER BY "table";

COMMIT;
