BEGIN;

-- lower case
UPDATE reseau_cu.ld SET nom_voie = lower(nom_voie) WHERE geocoding_failure IS True;

-- Creation d'un index sur les noms de voie
CREATE INDEX IF NOT EXISTS reseau_cu_ld_nom_voie ON reseau_cu.ld USING btree (nom_voie) WHERE geocoding_failure IS True;

-- Suppression des caracteres speciaux
UPDATE reseau_cu.ld SET nom_voie = ltrim(rtrim(nom_voie)) WHERE geocoding_failure IS True AND (nom_voie LIKE ' %' OR nom_voie LIKE '% ');
UPDATE reseau_cu.ld SET nom_voie = remove_multiple_spaces(nom_voie) WHERE geocoding_failure IS True AND nom_voie LIKE '%  %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, '.', '') WHERE geocoding_failure IS True AND (nom_voie LIKE '.%' OR nom_voie LIKE '%.');
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, '?', '') WHERE geocoding_failure IS True AND nom_voie LIKE '%?%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, ',', '') WHERE geocoding_failure IS True AND nom_voie LIKE '%,%';

REINDEX INDEX reseau_cu.reseau_cu_ld_nom_voie;

-- Type de voie
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'a ', 'avenue ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'a %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'aerd ', 'aérodrome ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'aerd %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'aerg ', 'aérogare ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'aerg %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'all ', 'allée ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'all %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'av ', 'avenue ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'av %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ave ', 'avenue ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ave %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'balc ', 'balcon ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'balc %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'barr ', 'barrière ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'barr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'bass ', 'bassin ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'bass %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'bd ', 'boulevard ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'bd %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'bld ', 'boulevard ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'bld %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'brd ', 'boulevard ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'brd %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'brg ', 'barrage ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'brg %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'butt ', 'butte ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'butt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'carr ', 'carrefour ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'carr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'cas ', 'caserne ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'cas %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ccal ', 'centre commercial ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ccal %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'cd ', 'chemin départemental ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'cd %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ch ', 'chemin ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ch %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'chal ', 'chalet ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'chal %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'chat ', 'chateau ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'chat %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'chau ', 'chaussée ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'chau %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'che ', 'chemin ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'che %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'chem ', 'chemin ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'chem %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'chp ', 'champ ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'chp %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'clim ', 'climat ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'clim %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'clr ', 'clairiere ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'clr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'cont ', 'contour ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'cont %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'cott ', 'cottage ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'cott %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'cr ', 'cour ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'cr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'crs ', 'cours ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'crs %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ctre ', 'centre ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ctre %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'dom ', 'domaine ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'dom %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ecl ', 'écluse ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ecl %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'esc ', 'escalier ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'esc %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'esp ', 'esplanade ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'esp %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'espa ', 'espace ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'espa %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'etg ', 'étang ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'etg %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'fb ', 'faubourg ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'fb %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'fbg ', 'faubourg ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'fbg %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ferm ', 'ferme ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ferm %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'font ', 'fontaine ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'font %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'foss ', 'fosse ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'foss %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'frt ', 'forêt ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'frt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'gal ', 'galerie ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'gal %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'gdav ', 'grande avenue ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'gdav %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'gdpl ', 'grande place ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'gdpl %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'gdr ', 'grande rue ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'gdr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'grge ', 'grange ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'grge %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ham ', 'hameau ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ham %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'hipp ', 'hippodrome ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'hipp %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'imm ', 'immeuble ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'imm %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'imp ', 'impasse ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'imp %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'jard ', 'jardin ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'jard %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ld ', 'lieu-dit ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ld %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ldt ', 'lieu-dit ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ldt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'lot ', 'lotissement ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'lot %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'mais ', 'maison ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'mais %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'mar ', 'marché ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'mar %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'marc ', 'marche ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'marc %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'mch ', 'marché ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'mch %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'metr ', 'métro ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'metr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'mnt ', 'montée ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'mnt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pal ', 'palais ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pal %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'parv ', 'parvis ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'parv %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pas ', 'passage ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pas %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pass ', 'passage ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pass %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pav ', 'pavillon ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pav %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pce ', 'place ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pce %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pel ', 'pelouse ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pel %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'piec ', 'pièce ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'piec %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pk', 'point kilométrique')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pk %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pkg ', 'parking ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pkg %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pl ', 'place ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pl %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'plai ', 'plaine ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'plai %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pnte ', 'pointe ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pnte %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'port ', 'port ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'port %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'prai ', 'prairie ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'prai %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'pro ', 'promenade ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'pro %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'prom ', 'promenade ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'prom %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'prte ', 'porte ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'prte %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ptr ', 'petite rue ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ptr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'qrt ', 'quartier ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'qrt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'qu ', 'quai ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'qu %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'quar ', 'quartier ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'quar %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'r ', 'rue ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'r %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'rce ', 'résidence ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'rce %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'rd pt ', 'rond-point ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'rd pt %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'rd', 'route départementale')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'rd %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'rdpt ', 'rond-point ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'rdpt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'res ', 'résidence ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'res %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'rle ', 'ruelle ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'rle %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'rn', 'route nationale')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'rn %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'rpe ', 'rampe ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'rpe %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'rte ', 'route ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'rte %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ruel ', 'ruelle ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ruel %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ruet ', 'ruette ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ruet %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'sen ', 'sentier ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'sen %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'sent ', 'sentier ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'sent %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'sente ', 'sentier ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'sente %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'snte ', 'sentier ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'snte %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'sq ', 'square ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'sq %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'sqr ', 'square ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'sqr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'squ ', 'square ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'squ %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'st ', 'station ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'st %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'terr ', 'terrasse ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'terr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'tr ', 'tour ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'tr %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'trav ', 'traverse ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'trav %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'val ', 'val ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'val %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'vall ', 'vallée ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'vall %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'voie com', 'voie communale')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'voie com %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'voie com ', 'vc ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'voie com %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'vc', 'voie communale')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'vc %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'ven ', 'venelle ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'ven %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'vge ', 'village ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'vge %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'vla ', 'villa ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'vla %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'z a', 'zone artisanale')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'z a %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'z a ', 'za ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'z a %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'za', 'zone artisanale')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'za %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie, 'zi', 'zone industrielle')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'zi %';
--UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'zac', E'zone d\'aménagement concerté')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE 'zac %';

-- nom voie
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'card', 'cardinal')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% card %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'cdt', 'commandant')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% cdt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'cmmdt', 'commandant')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% cmmdt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'doct', 'docteur')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% doct %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'gal', 'général')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% gal %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'gen', 'général')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% gen %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'mal', 'maréchal')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% mal %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'mar', 'maréchal')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% mar %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'pdt', 'président')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% pdt %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'pres', 'président')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% pres %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'prof', 'professeur')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% prof %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'res ', 'résidence ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% res %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'saint-', 'saint ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% saint-%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'sainte-', 'sainte ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% sainte-%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'st ', 'saint ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% st %';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'ste ', 'sainte ')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '% ste %';

--accent
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'general', 'général')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%general%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'republique', 'république')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%republique%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'liberte', 'liberté')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%liberte%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'president', 'président')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%president%';

--article
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'e mairie', 'e de la mairie')::varchar(50) WHERE nom_voie LIKE '%e mairie%' AND geocoding_failure IS True;
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'e république', 'e de la république')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%e république%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'd république', 'd de la république')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%d république%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'e liberté', 'e de la liberté')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%e liberté%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'd liberté', 'd de la liberté')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%d liberté%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'e général', 'e du général')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%e général%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'd général', 'd du général')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%d général%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'e président', 'e du président')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%e président%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'd président', 'd du président')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%d président%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'e maréchal', 'e du maréchal')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%e maréchal%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'd maréchal', 'd du maréchal')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%d maréchal%';

-- specifique
UPDATE reseau_cu.ld SET nom_voie = 'le bourg' WHERE geocoding_failure IS True AND nom_voie IN ('bourg le', 'brg');
UPDATE reseau_cu.ld SET nom_voie = 'grande rue' WHERE geocoding_failure IS True AND nom_voie IN ('gdr', 'gde rue');
UPDATE reseau_cu.ld SET nom_voie = 'rue notre dame des champs' WHERE geocoding_failure is true AND nom_voie = 'rue n d des champs';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'jj', 'jean-jacques')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%jj%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'j j', 'jean-jacques')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%j j%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'j-j', 'jean-jacques')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%j-j%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'j f kennedy', 'kennedy')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%kennedy%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'john f kennedy', 'kennedy')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%kennedy%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'john kennedy', 'kennedy')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%kennedy%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'j b clement', 'Jean-Baptiste Clément')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%j b clement%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'p v couturier', 'paul vaillant couturier')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%p v couturier%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'i et f', 'Frédéric et Irène')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%i et f joliot curie%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'f et i', 'Frédéric et Irène')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%f et i joliot curie%';
UPDATE reseau_cu.ld SET nom_voie = replace(nom_voie,	'p et m', 'pierre et marie')::varchar(50) WHERE geocoding_failure IS True AND nom_voie LIKE '%p et m curie%';

UPDATE reseau_cu.ld SET geocoding_failure = Null WHERE geocoding_failure IS True;

DROP INDEX IF EXISTS reseau_cu.reseau_cu_ld_nom_voie;

REINDEX INDEX reseau_cu.reseau_cu_ld_code_ban_idx;
REINDEX INDEX reseau_cu.reseau_cu_ld_geocoding_failure_idx;

COMMIT;
