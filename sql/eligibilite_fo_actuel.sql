\timing
BEGIN;

--- Réinitialisation : Suppression de toutes les entités de la table eligibilite.actuel ayant pour techno_id celui de la techno Fibre.
DELETE FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code = 'FO');

---Creation d'une table temporaire utilisée uniquement dans ce script
CREATE TEMPORARY TABLE eligibilite_fibre(
  id serial,
  imb_fo_id integer NOT NULL,
  operateur_id smallint,
  pm_id integer NOT NULL,
  debit_montant integer,
  debit_descendant integer,
  CONSTRAINT eligibilite_fibre_pkey PRIMARY KEY (id)
) ON COMMIT DROP;

-- Ajout de toutes les entités reseau_fo.imb dont le statut est Raccordable sur demande ou Déployé et dont le PM est à l'état déployé et dont la date de mise en service commerciale est au plus celle du jour.
INSERT INTO eligibilite_fibre(pm_id, imb_fo_id, operateur_id, debit_montant, debit_descendant)
SELECT pm.id, imb.id, oc.operateur_id, oc.debit_montant, oc.debit_descendant
FROM reseau_fo.imb
INNER JOIN reseau_fo.pm ON pm.id = imb.pm_id
INNER JOIN reseau_fo.oc_pm AS oc ON oc.pm_id = imb.pm_id
INNER JOIN reference.fibre_etat AS etat_imb ON etat_imb.id = imb.etat_id AND etat_imb.code IN ('RACD', 'DEPL')
INNER JOIN reference.fibre_etat AS etat_pm ON etat_pm.id = pm.etat_id AND etat_pm.code IN ('DEPL')
WHERE pm.date_mes_commerc IS NULL OR pm.date_mes_commerc <= NOW();


CREATE INDEX eligibilite_fibre_sans_service_idx ON eligibilite_fibre USING btree (operateur_id, pm_id, imb_fo_id);

-- Supression des lignes qui sont indiquées sans service par les opérateur commerciaux (pour une ligne donnée, cette dernière n'est supprimée que pour les opérateurs commerciaux qui ont indiqué que la ligne était sans service)
DELETE FROM eligibilite_fibre AS e
WHERE EXISTS (SELECT 1 FROM reseau_fo.oc_imb_sans_service AS sub WHERE sub.operateur_id = operateur_id AND sub.pm_id = e.pm_id  AND sub.imb_id = e.imb_fo_id);

--- Ajout de toutes les informations d'éligibilité à la fibre des entités adresse.immeuble dont le statut est Raccordable sur demande ou Déployé et dont le PM est à l'état déployé et dont la date de mise en service commerciale est au plus celle du jour.
INSERT INTO eligibilite.actuel (immeuble_id, operateur_id, techno_id, debit_montant, debit_descendant)
SELECT base_imb.imb_id, fibre.operateur_id, techno.id, fibre.debit_montant, fibre.debit_descendant
FROM eligibilite_fibre AS fibre
INNER JOIN reseau_fo.imb ON imb.id = fibre.imb_fo_id
INNER JOIN reference.techno ON techno.code = 'FO'
INNER JOIN adresse.base_imb ON addr_source IN ('ban', 'fo') AND imb_code = imb.code_imb;

-- Récap
SELECT 'eligibilite_fibre' AS "table", COUNT(*) FROM eligibilite_fibre
UNION
SELECT 'reseau_fo.imb' AS "table", COUNT(*) FROM reseau_fo.imb
UNION
SELECT 'reseau_fo.oc_pm' AS "table", COUNT(*) FROM reseau_fo.oc_pm
UNION
SELECT 'eligibilite.actuel/fo' AS "table", COUNT(*) FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code = 'FO')
ORDER BY "table";

COMMIT;
