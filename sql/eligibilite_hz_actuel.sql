\timing
BEGIN;

--- Réinitialisation : Suppression de toutes les entités de la table eligibilite.actuel ayant pour techno_id celui des techno {THDRadio,WiMax,WiFi,WiFiMax}.
DELETE FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code IN ('THDR', 'WMX', 'WIFI', 'WIMX'));

--- Ajout de toutes les entités adresse.immeuble contenu dans les zones de couverture.
INSERT INTO eligibilite.actuel (immeuble_id, operateur_id, techno_id, debit_montant, debit_descendant, limitation, saturation)
SELECT imb_id, oc.operateur_id, site.techno_id,
LEAST(oc.debit_montant, (CASE WHEN site.techno_id = (SELECT id FROM reference.techno WHERE code = 'THDR') THEN 7999 ELSE 2999 END)),
LEAST(oc.debit_descendant, (CASE WHEN site.techno_id = (SELECT id FROM reference.techno WHERE code = 'THDR') THEN 99999 ELSE 29999 END)),
oc.limitation_donnee, NOT site.ouverture_commerciale
FROM reseau_hz.oc
INNER JOIN reseau_hz.reseau ON reseau.id = oc.reseau_id
INNER JOIN reseau_hz.couverture ON couverture.reseau_id = reseau.id
INNER JOIN reseau_hz.site ON site.id = couverture.site_id
INNER JOIN adresse.base_imb ON ST_Contains(couverture.geom, imb_geom);

COMMIT;
