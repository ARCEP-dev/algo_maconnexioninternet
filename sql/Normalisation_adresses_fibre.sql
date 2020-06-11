BEGIN;

-- lower case
UPDATE reseau_fo.imb SET (type_voie, nom_voie) = (lower(type_voie), lower(nom_voie)) WHERE geocoding_failure IS True;

-- Creation d'un index sur les noms de voie, les types de voie, les batiments
CREATE INDEX IF NOT EXISTS reseau_fo_imb_type_voie ON reseau_fo.imb USING btree (type_voie) WHERE geocoding_failure IS True;
CREATE INDEX IF NOT EXISTS reseau_fo_imb_nom_voie ON reseau_fo.imb USING btree (nom_voie) WHERE geocoding_failure IS True;
CREATE INDEX IF NOT EXISTS reseau_fo_imb_batiment ON reseau_fo.imb USING btree (batiment);

-- Suppression des caracteres speciaux
UPDATE reseau_fo.imb SET type_voie = ltrim(rtrim(type_voie)) WHERE geocoding_failure IS True AND (type_voie LIKE ' %' OR type_voie LIKE '% ');
UPDATE reseau_fo.imb SET type_voie = remove_multiple_spaces(type_voie) WHERE geocoding_failure IS True AND type_voie LIKE '%  %';
UPDATE reseau_fo.imb SET type_voie = replace(type_voie, '.', '') WHERE geocoding_failure IS True AND (type_voie LIKE '.%' OR type_voie LIKE '%.');
UPDATE reseau_fo.imb SET type_voie = replace(type_voie, '.', ' ') WHERE geocoding_failure IS True AND type_voie LIKE '%.%';
UPDATE reseau_fo.imb SET type_voie = replace(type_voie, '?', '') WHERE geocoding_failure IS True AND type_voie LIKE '%?%';
UPDATE reseau_fo.imb SET type_voie = replace(type_voie, ',', '') WHERE geocoding_failure IS True AND type_voie LIKE '%,%';

UPDATE reseau_fo.imb SET nom_voie = ltrim(rtrim(nom_voie)) WHERE geocoding_failure IS True AND (nom_voie LIKE ' %' OR nom_voie LIKE '% ');
UPDATE reseau_fo.imb SET nom_voie = remove_multiple_spaces(nom_voie) WHERE geocoding_failure IS True AND nom_voie LIKE '%  %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie, '.', '') WHERE geocoding_failure IS True AND (nom_voie LIKE '.%' OR nom_voie LIKE '%.');
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie, '.', ' ') WHERE geocoding_failure IS True AND nom_voie LIKE '%.%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie, '?', '') WHERE geocoding_failure IS True AND nom_voie LIKE '%?%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie, ',', '') WHERE geocoding_failure IS True AND nom_voie LIKE '%,%';

-- Type de voie
UPDATE reseau_fo.imb SET type_voie = 'allée' WHERE geocoding_failure IS True AND type_voie = 'all';
UPDATE reseau_fo.imb SET type_voie = 'avenue' WHERE geocoding_failure IS True AND type_voie = 'a';
UPDATE reseau_fo.imb SET type_voie = 'avenue' WHERE geocoding_failure IS True AND type_voie = 'av';
UPDATE reseau_fo.imb SET type_voie = 'avenue' WHERE geocoding_failure IS True AND type_voie = 'ave';
UPDATE reseau_fo.imb SET type_voie = 'avenue' WHERE geocoding_failure IS True AND type_voie LIKE 'avenue%';
UPDATE reseau_fo.imb SET type_voie = 'boulevard' WHERE geocoding_failure IS True AND type_voie = 'bd';
UPDATE reseau_fo.imb SET type_voie = 'boulevard' WHERE geocoding_failure IS True AND type_voie = 'bimb';
UPDATE reseau_fo.imb SET type_voie = 'boulevard' WHERE geocoding_failure IS True AND type_voie = 'brd';
UPDATE reseau_fo.imb SET type_voie = 'centre commercial' WHERE geocoding_failure IS True AND type_voie = 'ccal';
UPDATE reseau_fo.imb SET type_voie = 'centre' WHERE geocoding_failure IS True AND type_voie = 'ctre';
UPDATE reseau_fo.imb SET type_voie = 'chemin' WHERE geocoding_failure IS True AND type_voie = 'ch';
UPDATE reseau_fo.imb SET type_voie = 'chemin' WHERE geocoding_failure IS True AND type_voie = 'che';
UPDATE reseau_fo.imb SET type_voie = 'chemin' WHERE geocoding_failure IS True AND type_voie = 'chem';
UPDATE reseau_fo.imb SET type_voie = 'chateau' WHERE geocoding_failure IS True AND type_voie = 'chat';
UPDATE reseau_fo.imb SET type_voie = 'cour' WHERE geocoding_failure IS True AND type_voie = 'cr';
UPDATE reseau_fo.imb SET type_voie = 'cours' WHERE geocoding_failure IS True AND type_voie = 'crs';
UPDATE reseau_fo.imb SET type_voie = 'domaine' WHERE geocoding_failure IS True AND type_voie = 'dom';
UPDATE reseau_fo.imb SET type_voie = 'esplanade' WHERE geocoding_failure IS True AND type_voie = 'esp';
UPDATE reseau_fo.imb SET type_voie = 'espace' WHERE geocoding_failure IS True AND type_voie = 'espa';
UPDATE reseau_fo.imb SET type_voie = 'faubourg' WHERE geocoding_failure IS True AND type_voie = 'fb';
UPDATE reseau_fo.imb SET type_voie = 'faubourg' WHERE geocoding_failure IS True AND type_voie = 'fbg';
UPDATE reseau_fo.imb SET type_voie = 'galerie' WHERE geocoding_failure IS True AND type_voie = 'gal';
UPDATE reseau_fo.imb SET type_voie = 'immeuble' WHERE geocoding_failure IS True AND type_voie = 'imm';
UPDATE reseau_fo.imb SET type_voie = 'impasse' WHERE geocoding_failure IS True AND type_voie = 'imp';
UPDATE reseau_fo.imb SET type_voie = 'hameau' WHERE geocoding_failure IS True AND type_voie = 'ham';
UPDATE reseau_fo.imb SET type_voie = 'lotissement' WHERE geocoding_failure IS True AND type_voie = 'lot';
--UPDATE reseau_fo.imb SET type_voie = 'lieu-dit' WHERE geocoding_failure IS True AND type_voie = 'imb';
--UPDATE reseau_fo.imb SET type_voie = 'lieu-dit' WHERE geocoding_failure IS True AND type_voie = 'imbt';
UPDATE reseau_fo.imb SET type_voie = Null WHERE geocoding_failure IS True AND type_voie IN ('lieu-dit', 'lieu dit', 'ld');
UPDATE reseau_fo.imb SET type_voie = 'marché' WHERE geocoding_failure IS True AND type_voie = 'mar';
UPDATE reseau_fo.imb SET type_voie = 'palais' WHERE geocoding_failure IS True AND type_voie = 'pal';
UPDATE reseau_fo.imb SET type_voie = 'passage' WHERE geocoding_failure IS True AND type_voie = 'pas';
UPDATE reseau_fo.imb SET type_voie = 'passage' WHERE geocoding_failure IS True AND type_voie = 'pass';
UPDATE reseau_fo.imb SET type_voie = 'place' WHERE geocoding_failure IS True AND type_voie = 'pce';
UPDATE reseau_fo.imb SET type_voie = 'place' WHERE geocoding_failure IS True AND type_voie = 'pl';
UPDATE reseau_fo.imb SET type_voie = 'promenade' WHERE geocoding_failure IS True AND type_voie = 'pr';
UPDATE reseau_fo.imb SET type_voie = 'promenade' WHERE geocoding_failure IS True AND type_voie = 'pro';
UPDATE reseau_fo.imb SET type_voie = 'promenade' WHERE geocoding_failure IS True AND type_voie = 'prom';
UPDATE reseau_fo.imb SET type_voie = 'quartier' WHERE geocoding_failure IS True AND type_voie = 'qrt';
UPDATE reseau_fo.imb SET type_voie = 'quai' WHERE geocoding_failure IS True AND type_voie = 'qu';
UPDATE reseau_fo.imb SET type_voie = 'rue' WHERE geocoding_failure IS True AND type_voie = 'r';
UPDATE reseau_fo.imb SET type_voie = 'rue' WHERE geocoding_failure IS True AND type_voie = 'r.';
UPDATE reseau_fo.imb SET type_voie = 'rond-point' WHERE geocoding_failure IS True AND type_voie = 'rdpt';
UPDATE reseau_fo.imb SET type_voie = 'rond-point' WHERE geocoding_failure IS True AND type_voie = 'rd pt';
UPDATE reseau_fo.imb SET type_voie = 'rond-point' WHERE geocoding_failure IS True AND type_voie = 'rpt';
UPDATE reseau_fo.imb SET type_voie = 'résidence' WHERE geocoding_failure IS True AND type_voie = 'res';
UPDATE reseau_fo.imb SET type_voie = 'résidence' WHERE geocoding_failure IS True AND type_voie = 'rce';
UPDATE reseau_fo.imb SET type_voie = 'route' WHERE geocoding_failure IS True AND type_voie = 'rte';
UPDATE reseau_fo.imb SET type_voie = 'ruelle' WHERE geocoding_failure IS True AND type_voie = 'ruel';
UPDATE reseau_fo.imb SET type_voie = 'ruette' WHERE geocoding_failure IS True AND type_voie = 'ruet';
UPDATE reseau_fo.imb SET type_voie = 'sentier' WHERE geocoding_failure IS True AND type_voie = 'sen';
UPDATE reseau_fo.imb SET type_voie = 'sentier' WHERE geocoding_failure IS True AND type_voie = 'sent';
UPDATE reseau_fo.imb SET type_voie = 'sentier' WHERE geocoding_failure IS True AND type_voie = 'sente';
UPDATE reseau_fo.imb SET type_voie = 'sentier' WHERE geocoding_failure IS True AND type_voie = 'snte';
UPDATE reseau_fo.imb SET type_voie = 'square' WHERE geocoding_failure IS True AND type_voie = 'sq';
UPDATE reseau_fo.imb SET type_voie = 'square' WHERE geocoding_failure IS True AND type_voie = 'sqr';
UPDATE reseau_fo.imb SET type_voie = 'square' WHERE geocoding_failure IS True AND type_voie = 'squ';
UPDATE reseau_fo.imb SET type_voie = 'terrasse' WHERE geocoding_failure IS True AND type_voie = 'terr';
UPDATE reseau_fo.imb SET type_voie = 'tour' WHERE geocoding_failure IS True AND type_voie = 'tr';
UPDATE reseau_fo.imb SET type_voie = 'za' WHERE geocoding_failure IS True AND type_voie = 'z a';
--UPDATE reseau_fo.imb SET type_voie = 'zone artisanale' WHERE geocoding_failure IS True AND type_voie = 'za';
--UPDATE reseau_fo.imb SET type_voie = E'zone d\'aménagement concerté' WHERE geocoding_failure IS True AND type_voie = 'zac';
--UPDATE reseau_fo.imb SET type_voie = 'zone industrielle' WHERE geocoding_failure IS True AND type_voie = 'zi';
UPDATE reseau_fo.imb SET type_voie = 'village' WHERE geocoding_failure IS True AND type_voie = 'vge';
UPDATE reseau_fo.imb SET type_voie = 'cv' WHERE geocoding_failure IS True AND type_voie = 'voie com';
--UPDATE reseau_fo.imb SET type_voie = 'voie communale' WHERE geocoding_failure IS True AND type_voie = 'vc';

-- nom voie
-- specifique
UPDATE reseau_fo.imb SET nom_voie = 'president francois mitterrand' WHERE geocoding_failure IS True AND nom_voie LIKE 'president francois mitterrand / pdt mitterand';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'f mitterrand', 'francois mitterrand') WHERE geocoding_failure IS True AND nom_voie LIKE '% f mitterrand%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'f roosevelt', 'franklin roosevelt') WHERE geocoding_failure IS True AND nom_voie LIKE '% f roosevelt%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'j f kennedy', 'kennedy') WHERE geocoding_failure IS True AND nom_voie LIKE '%kennedy%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'john f kennedy', 'kennedy') WHERE geocoding_failure IS True AND nom_voie LIKE '%kennedy%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'j fitzgerald kennedy', 'kennedy') WHERE geocoding_failure IS True AND nom_voie LIKE '%kennedy%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'john kennedy', 'kennedy') WHERE geocoding_failure IS True AND nom_voie LIKE '%kennedy%';

UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'card', 'cardinal') WHERE geocoding_failure IS True AND nom_voie LIKE '% card %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'cdt', 'commandant') WHERE geocoding_failure IS True AND nom_voie LIKE '% cdt %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'cmmdt', 'commandant') WHERE geocoding_failure IS True AND nom_voie LIKE '% cmmdt %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'doct', 'docteur') WHERE geocoding_failure IS True AND nom_voie LIKE '% doct %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'gal', 'général') WHERE geocoding_failure IS True AND nom_voie LIKE '% gal %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'gen', 'général') WHERE geocoding_failure IS True AND nom_voie LIKE '% gen %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'mal', 'maréchal') WHERE geocoding_failure IS True AND nom_voie LIKE '% mal %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'mar', 'maréchal') WHERE geocoding_failure IS True AND nom_voie LIKE '% mar %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'pdt', 'président') WHERE geocoding_failure IS True AND nom_voie LIKE '% pdt %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'pres', 'président') WHERE geocoding_failure IS True AND nom_voie LIKE '% pres %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'prof', 'professeur') WHERE geocoding_failure IS True AND nom_voie LIKE '% prof %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'res ', 'résidence ') WHERE geocoding_failure IS True AND nom_voie LIKE '% res %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'saint-', 'saint ') WHERE geocoding_failure IS True AND nom_voie LIKE '% saint-%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'sainte-', 'sainte ') WHERE geocoding_failure IS True AND nom_voie LIKE '% sainte-%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'st.', 'saint ') WHERE geocoding_failure IS True AND nom_voie LIKE '% st. %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'st ', 'saint ') WHERE geocoding_failure IS True AND nom_voie LIKE '% st %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'ste.', 'sainte ') WHERE geocoding_failure IS True AND nom_voie LIKE '% ste. %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'ste ', 'sainte ') WHERE geocoding_failure IS True AND nom_voie LIKE '% ste %';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'jj ', 'jean-jacques ') WHERE geocoding_failure IS True AND nom_voie LIKE '%rousseau%';
UPDATE reseau_fo.imb SET nom_voie = replace(nom_voie,	'j j ', 'jean-jacques ') WHERE geocoding_failure IS True AND nom_voie LIKE '%rousseau%';

UPDATE reseau_fo.imb SET geocoding_failure = Null WHERE geocoding_failure IS True;

-- batiments NA et autres caracteres en NULL
UPDATE reseau_fo.imb SET batiment = Null WHERE batiment IN ('na',' ', '.', '..', '-', '_', '?','/', '|');


DROP INDEX IF EXISTS reseau_fo.reseau_fo_imb_type_voie;
DROP INDEX IF EXISTS reseau_fo.reseau_fo_imb_nom_voie;
DROP INDEX IF EXISTS reseau_fo.reseau_fo_imb_batiment;

REINDEX INDEX reseau_fo.reseau_fo_imb_code_ban_idx;
REINDEX INDEX reseau_fo.reseau_fo_imb_geocoding_failure_idx;

COMMIT;
