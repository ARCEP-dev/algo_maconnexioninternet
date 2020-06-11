\timing
BEGIN;

--- Réinitialisation : Suppression de toutes les entités de la table eligibilite.actuel ayant pour techno_id celui de la techno Satellite.
DELETE FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code = 'SAT');

--- Découpage des polygones en limitant leur nombre de sommets à 200 et pour les polygones n'étant pas valides, correction des géométries afin qu'ils le deviennent.
CREATE TEMPORARY TABLE reseau_sat_couverture ON COMMIT DROP AS (
  SELECT id, ST_MakeValid(ST_Subdivide(geom, 200)) AS geom, ouverture_commerciale
  FROM reseau_sat.reseau
  WHERE ST_isValid(geom)
  UNION
  SELECT id, ST_MakeValid(ST_Subdivide(ST_MakeValid(geom), 200)) AS geom, ouverture_commerciale
  FROM reseau_sat.reseau
  WHERE ST_isValid(geom) IS FALSE
);

CREATE INDEX reseau_sat_couverture_geom_idx ON reseau_sat_couverture USING gist(geom);

--- Découpage des polygones à la commune.
CREATE TEMPORARY TABLE reseau_sat_couverture_subdivided ON COMMIT DROP AS (
  SELECT couv.id, ST_MakeValid(ST_Subdivide(ST_Intersection(com.geom, couv.geom), 200)) AS geom, ouverture_commerciale
  FROM reseau_sat_couverture AS couv
  INNER JOIN admin.commune AS com ON ST_Intersects(com.geom, couv.geom)
);

CREATE INDEX reseau_sat_couverture_subdivided_geom_idx ON reseau_sat_couverture_subdivided USING gist(geom);
CREATE INDEX reseau_sat_couverture_subdivided_id_idx ON reseau_sat_couverture_subdivided USING btree(id);

--- Ajout de toutes les informations d'éligibilité aux technologies radio des entités adresse.immeuble contenues dans les zones de couverture
INSERT INTO eligibilite.actuel (immeuble_id, operateur_id, techno_id, debit_montant, debit_descendant, limitation, saturation)
SELECT imb_id, oc.operateur_id, techno.id, LEAST(oc.debit_montant, 29999), LEAST(oc.debit_descendant, 29999), oc.limitation_donnee, NOT reseau.ouverture_commerciale
FROM reseau_sat.oc
INNER JOIN reseau_sat_couverture_subdivided AS reseau ON reseau.id = oc.reseau_id
INNER JOIN reference.techno ON techno.code = 'SAT'
INNER JOIN adresse.base_imb ON ST_Contains(reseau.geom, imb_geom);

COMMIT;
