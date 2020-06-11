\timing
BEGIN;

--- Réinitialisation : Suppression de toutes les entités de la table eligibilite.actuel ayant pour techno_id celui de la techno 4G Fixe.
DELETE FROM eligibilite.actuel WHERE techno_id IN (SELECT id FROM reference.techno WHERE code = '4GF');

--- Découpage des polygones en limitant leur nombre de sommets à 200 et pour les polygones n'étant pas valides, correction des géométries afin qu'ils le deviennent.
CREATE TEMPORARY TABLE reseau_cell_couverture ON COMMIT DROP AS (
  SELECT id, ST_MakeValid(ST_Subdivide(geom, 200)) AS geom, reseau_id, saturation
  FROM reseau_cell.couverture
  WHERE ST_isValid(geom)
  UNION
  SELECT id, ST_MakeValid(ST_Subdivide(ST_MakeValid(geom), 200)) AS geom, reseau_id, saturation
  FROM reseau_cell.couverture
  WHERE ST_isValid(geom) IS FALSE
);

CREATE INDEX reseau_cell_couverture_geom_idx ON reseau_cell_couverture USING gist(geom);

--- Découpage des polygones à la commune.
CREATE TEMPORARY TABLE reseau_cell_couverture_subdivided ON COMMIT DROP AS (
  SELECT couv.id, ST_MakeValid(ST_Subdivide(ST_Intersection(com.geom,couv.geom), 200)) AS geom, reseau_id, saturation
  FROM reseau_cell_couverture AS couv
  INNER JOIN admin.commune AS com ON ST_Intersects(com.geom, couv.geom)
);

CREATE INDEX reseau_cell_couverture_subdivided_geom_idx ON reseau_cell_couverture_subdivided USING gist(geom);
CREATE INDEX reseau_cell_couverture_subdivided_id_idx ON reseau_cell_couverture_subdivided USING btree(id);
CREATE INDEX reseau_cell_couverture_subdivided_saturation_idx ON reseau_cell_couverture_subdivided USING btree(saturation);
CREATE INDEX reseau_cell_couverture_subdivided_reseau_id_idx ON reseau_cell_couverture_subdivided USING btree(reseau_id);

--- Ajout de toutes les informations d'éligibilité à la 4G fixe des entités adresse.immeuble contenues dans les zones de couverture qui ne sont pas saturées
INSERT INTO eligibilite.actuel (immeuble_id, operateur_id, techno_id, debit_montant, debit_descendant, limitation, saturation)
SELECT imb_id, oc.operateur_id, techno.id, LEAST(oc.debit_montant, 7999), LEAST(oc.debit_descendant, 29999), oc.limitation_donnee, couverture.saturation
FROM reseau_cell.oc
INNER JOIN reseau_cell.reseau ON reseau.id = oc.reseau_id
INNER JOIN reseau_cell_couverture_subdivided AS couverture ON couverture.reseau_id = reseau.id AND saturation IS False
INNER JOIN reference.techno ON techno.code = '4GF'
INNER JOIN adresse.base_imb ON ST_Contains(couverture.geom, imb_geom);

COMMIT;
