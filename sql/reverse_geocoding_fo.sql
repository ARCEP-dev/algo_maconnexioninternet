BEGIN;

-- Besoin de l'EXTENSION fuzzystrmatch (extension installée par le script "CREATE_Structure.sql")

/*Le géocodage inverse va associer une code_ban à l'immeuble fibre si l'adresse BAN et l'immeuble fibre ont le même code insee, le même numéro et si : 
	- soit la distance de levenshtein sur le nom de voie est au maximum de 7 et la distance entre la géométrie de l'adresse BAN et de l'immeuble fibre est inférieur à 70 mètres
	- soit la distance de levenshtein sur le nom de voie est au maximum de 3 et la distance entre la géométrie de l'adresse BAN et de l'immeuble fibre est inférieur à 500 mètres
*/

UPDATE reseau_fo.imb
SET code_ban = (SELECT code
                FROM adresse.adresse
                WHERE adresse.source = 'ban'
                AND ST_SRID(adresse.geom) = ST_SRID(imb.geom)
                AND ST_DWithin(adresse.geom, imb.geom, 500)
                AND imb.code_insee = adresse.code_insee
                AND ((levenshtein(lower(adresse.nom_voie), lower(imb.type_voie || ' ' || imb.nom_voie)) <= 7 AND ST_DWithin(adresse.geom, imb.geom, 70))
                  OR (levenshtein(lower(adresse.nom_voie), lower(imb.type_voie || ' ' || imb.nom_voie)) <= 3))
                AND imb.numero_voie = adresse.numero
                ORDER BY ST_Distance(adresse.geom, imb.geom) ASC
                LIMIT 1)
WHERE code_ban IS NULL AND geocoding_failure IS True AND geom IS NOT NULL;

COMMIT;
