BEGIN;

-- lower case
UPDATE reseau_coax.adresse SET nom_voie = lower(nom_voie) WHERE geocoding_failure IS True;

-- Creation d'un index sur les noms de voie
CREATE INDEX IF NOT EXISTS reseau_coax_adresse_nom_voie ON reseau_coax.adresse USING btree (nom_voie) WHERE geocoding_failure IS True;

-- Suppression des caracteres speciaux
UPDATE reseau_coax.adresse SET nom_voie = ltrim(rtrim(nom_voie)) WHERE geocoding_failure IS True AND (nom_voie LIKE ' %' OR nom_voie LIKE '% ');
UPDATE reseau_coax.adresse SET nom_voie = remove_multiple_spaces(nom_voie) WHERE geocoding_failure IS True AND nom_voie LIKE '%  %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, '.', '') WHERE geocoding_failure IS True AND (nom_voie LIKE '.%' OR nom_voie LIKE '%.');
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, '?', '') WHERE geocoding_failure IS True AND nom_voie LIKE '%?%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, ',', '') WHERE geocoding_failure IS True AND nom_voie LIKE '%,%';

REINDEX INDEX reseau_coax.reseau_coax_adresse_nom_voie;

-- Type de voie
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'a ', 'avenue ') WHERE geocoding_failure IS True AND nom_voie LIKE 'a %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'aerd ', 'aérodrome ') WHERE geocoding_failure IS True AND nom_voie LIKE 'aerd %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'aerg ', 'aérogare ') WHERE geocoding_failure IS True AND nom_voie LIKE 'aerg %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'all ', 'allée ') WHERE geocoding_failure IS True AND nom_voie LIKE 'all %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'av ', 'avenue ') WHERE geocoding_failure IS True AND nom_voie LIKE 'av %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ave ', 'avenue ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ave %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'balc ', 'balcon ') WHERE geocoding_failure IS True AND nom_voie LIKE 'balc %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'barr ', 'barrière ') WHERE geocoding_failure IS True AND nom_voie LIKE 'barr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'bass ', 'bassin ') WHERE geocoding_failure IS True AND nom_voie LIKE 'bass %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'bd ', 'boulevard ') WHERE geocoding_failure IS True AND nom_voie LIKE 'bd %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'bld ', 'boulevard ') WHERE geocoding_failure IS True AND nom_voie LIKE 'bld %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'brd ', 'boulevard ') WHERE geocoding_failure IS True AND nom_voie LIKE 'brd %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'brg ', 'barrage ') WHERE geocoding_failure IS True AND nom_voie LIKE 'brg %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'butt ', 'butte ') WHERE geocoding_failure IS True AND nom_voie LIKE 'butt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'carr ', 'carrefour ') WHERE geocoding_failure IS True AND nom_voie LIKE 'carr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'cas ', 'caserne ') WHERE geocoding_failure IS True AND nom_voie LIKE 'cas %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ccal ', 'centre commercial ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ccal %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'cd ', 'chemin départemental ') WHERE geocoding_failure IS True AND nom_voie LIKE 'cd %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ch ', 'chemin ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ch %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'chal ', 'chalet ') WHERE geocoding_failure IS True AND nom_voie LIKE 'chal %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'chat ', 'chateau ') WHERE geocoding_failure IS True AND nom_voie LIKE 'chat %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'chau ', 'chaussée ') WHERE geocoding_failure IS True AND nom_voie LIKE 'chau %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'che ', 'chemin ') WHERE geocoding_failure IS True AND nom_voie LIKE 'che %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'chem ', 'chemin ') WHERE geocoding_failure IS True AND nom_voie LIKE 'chem %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'chp ', 'champ ') WHERE geocoding_failure IS True AND nom_voie LIKE 'chp %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'clim ', 'climat ') WHERE geocoding_failure IS True AND nom_voie LIKE 'clim %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'clr ', 'clairiere ') WHERE geocoding_failure IS True AND nom_voie LIKE 'clr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'cont ', 'contour ') WHERE geocoding_failure IS True AND nom_voie LIKE 'cont %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'cott ', 'cottage ') WHERE geocoding_failure IS True AND nom_voie LIKE 'cott %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'cr ', 'cour ') WHERE geocoding_failure IS True AND nom_voie LIKE 'cr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'crs ', 'cours ') WHERE geocoding_failure IS True AND nom_voie LIKE 'crs %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ctre ', 'centre ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ctre %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'dom ', 'domaine ') WHERE geocoding_failure IS True AND nom_voie LIKE 'dom %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ecl ', 'écluse ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ecl %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'esc ', 'escalier ') WHERE geocoding_failure IS True AND nom_voie LIKE 'esc %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'esp ', 'esplanade ') WHERE geocoding_failure IS True AND nom_voie LIKE 'esp %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'espa ', 'espace ') WHERE geocoding_failure IS True AND nom_voie LIKE 'espa %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'etg ', 'étang ') WHERE geocoding_failure IS True AND nom_voie LIKE 'etg %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'fb ', 'faubourg ') WHERE geocoding_failure IS True AND nom_voie LIKE 'fb %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'fbg ', 'faubourg ') WHERE geocoding_failure IS True AND nom_voie LIKE 'fbg %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ferm ', 'ferme ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ferm %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'font ', 'fontaine ') WHERE geocoding_failure IS True AND nom_voie LIKE 'font %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'foss ', 'fosse ') WHERE geocoding_failure IS True AND nom_voie LIKE 'foss %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'frt ', 'forêt ') WHERE geocoding_failure IS True AND nom_voie LIKE 'frt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'gal ', 'galerie ') WHERE geocoding_failure IS True AND nom_voie LIKE 'gal %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'gdav ', 'grande avenue ') WHERE geocoding_failure IS True AND nom_voie LIKE 'gdav %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'gdpl ', 'grande place ') WHERE geocoding_failure IS True AND nom_voie LIKE 'gdpl %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'gdr ', 'grande rue ') WHERE geocoding_failure IS True AND nom_voie LIKE 'gdr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'grge ', 'grange ') WHERE geocoding_failure IS True AND nom_voie LIKE 'grge %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ham ', 'hameau ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ham %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'hipp ', 'hippodrome ') WHERE geocoding_failure IS True AND nom_voie LIKE 'hipp %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'imm ', 'immeuble ') WHERE geocoding_failure IS True AND nom_voie LIKE 'imm %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'imp ', 'impasse ') WHERE geocoding_failure IS True AND nom_voie LIKE 'imp %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'jard ', 'jardin ') WHERE geocoding_failure IS True AND nom_voie LIKE 'jard %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ld ', 'lieu-dit ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ld %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ldt ', 'lieu-dit ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ldt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'lot ', 'lotissement ') WHERE geocoding_failure IS True AND nom_voie LIKE 'lot %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'mais ', 'maison ') WHERE geocoding_failure IS True AND nom_voie LIKE 'mais %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'mar ', 'marché ') WHERE geocoding_failure IS True AND nom_voie LIKE 'mar %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'marc ', 'marche ') WHERE geocoding_failure IS True AND nom_voie LIKE 'marc %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'mch ', 'marché ') WHERE geocoding_failure IS True AND nom_voie LIKE 'mch %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'metr ', 'métro ') WHERE geocoding_failure IS True AND nom_voie LIKE 'metr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'mnt ', 'montée ') WHERE geocoding_failure IS True AND nom_voie LIKE 'mnt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pal ', 'palais ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pal %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'parv ', 'parvis ') WHERE geocoding_failure IS True AND nom_voie LIKE 'parv %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pas ', 'passage ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pas %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pass ', 'passage ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pass %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pav ', 'pavillon ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pav %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pce ', 'place ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pce %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pel ', 'pelouse ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pel %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'piec ', 'pièce ') WHERE geocoding_failure IS True AND nom_voie LIKE 'piec %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pk', 'point kilométrique') WHERE geocoding_failure IS True AND nom_voie LIKE 'pk %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pkg ', 'parking ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pkg %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pl ', 'place ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pl %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'plai ', 'plaine ') WHERE geocoding_failure IS True AND nom_voie LIKE 'plai %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pnte ', 'pointe ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pnte %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'port ', 'port ') WHERE geocoding_failure IS True AND nom_voie LIKE 'port %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'prai ', 'prairie ') WHERE geocoding_failure IS True AND nom_voie LIKE 'prai %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'pro ', 'promenade ') WHERE geocoding_failure IS True AND nom_voie LIKE 'pro %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'prom ', 'promenade ') WHERE geocoding_failure IS True AND nom_voie LIKE 'prom %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'prte ', 'porte ') WHERE geocoding_failure IS True AND nom_voie LIKE 'prte %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ptr ', 'petite rue ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ptr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'qrt ', 'quartier ') WHERE geocoding_failure IS True AND nom_voie LIKE 'qrt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'qu ', 'quai ') WHERE geocoding_failure IS True AND nom_voie LIKE 'qu %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'quar ', 'quartier ') WHERE geocoding_failure IS True AND nom_voie LIKE 'quar %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'r ', 'rue ') WHERE geocoding_failure IS True AND nom_voie LIKE 'r %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'rce ', 'résidence ') WHERE geocoding_failure IS True AND nom_voie LIKE 'rce %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'rd pt ', 'rond-point ') WHERE geocoding_failure IS True AND nom_voie LIKE 'rd pt %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'rd', 'route départementale') WHERE geocoding_failure IS True AND nom_voie LIKE 'rd %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'rdpt ', 'rond-point ') WHERE geocoding_failure IS True AND nom_voie LIKE 'rdpt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'res ', 'résidence ') WHERE geocoding_failure IS True AND nom_voie LIKE 'res %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'rle ', 'ruelle ') WHERE geocoding_failure IS True AND nom_voie LIKE 'rle %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'rn', 'route nationale') WHERE geocoding_failure IS True AND nom_voie LIKE 'rn %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'rpe ', 'rampe ') WHERE geocoding_failure IS True AND nom_voie LIKE 'rpe %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'rte ', 'route ') WHERE geocoding_failure IS True AND nom_voie LIKE 'rte %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ruel ', 'ruelle ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ruel %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ruet ', 'ruette ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ruet %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'sen ', 'sentier ') WHERE geocoding_failure IS True AND nom_voie LIKE 'sen %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'sent ', 'sentier ') WHERE geocoding_failure IS True AND nom_voie LIKE 'sent %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'sente ', 'sentier ') WHERE geocoding_failure IS True AND nom_voie LIKE 'sente %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'snte ', 'sentier ') WHERE geocoding_failure IS True AND nom_voie LIKE 'snte %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'sq ', 'square ') WHERE geocoding_failure IS True AND nom_voie LIKE 'sq %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'sqr ', 'square ') WHERE geocoding_failure IS True AND nom_voie LIKE 'sqr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'squ ', 'square ') WHERE geocoding_failure IS True AND nom_voie LIKE 'squ %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'st ', 'station ') WHERE geocoding_failure IS True AND nom_voie LIKE 'st %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'terr ', 'terrasse ') WHERE geocoding_failure IS True AND nom_voie LIKE 'terr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'tr ', 'tour ') WHERE geocoding_failure IS True AND nom_voie LIKE 'tr %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'trav ', 'traverse ') WHERE geocoding_failure IS True AND nom_voie LIKE 'trav %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'val ', 'val ') WHERE geocoding_failure IS True AND nom_voie LIKE 'val %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'vall ', 'vallée ') WHERE geocoding_failure IS True AND nom_voie LIKE 'vall %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'voie com', 'voie communale') WHERE geocoding_failure IS True AND nom_voie LIKE 'voie com %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'voie com ', 'vc ') WHERE geocoding_failure IS True AND nom_voie LIKE 'voie com %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'vc', 'voie communale') WHERE geocoding_failure IS True AND nom_voie LIKE 'vc %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'ven ', 'venelle ') WHERE geocoding_failure IS True AND nom_voie LIKE 'ven %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'vge ', 'village ') WHERE geocoding_failure IS True AND nom_voie LIKE 'vge %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'vla ', 'villa ') WHERE geocoding_failure IS True AND nom_voie LIKE 'vla %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'z a', 'zone artisanale') WHERE geocoding_failure IS True AND nom_voie LIKE 'z a %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'z a ', 'za ') WHERE geocoding_failure IS True AND nom_voie LIKE 'z a %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'za', 'zone artisanale') WHERE geocoding_failure IS True AND nom_voie LIKE 'za %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie, 'zi', 'zone industrielle') WHERE geocoding_failure IS True AND nom_voie LIKE 'zi %';
--UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'zac', E'zone d\'aménagement concerté') WHERE geocoding_failure IS True AND nom_voie LIKE 'zac %';

-- nom voie
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'card', 'cardinal') WHERE geocoding_failure IS True AND nom_voie LIKE '% card %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'cdt', 'commandant') WHERE geocoding_failure IS True AND nom_voie LIKE '% cdt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'cmmdt', 'commandant') WHERE geocoding_failure IS True AND nom_voie LIKE '% cmmdt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'doct', 'docteur') WHERE geocoding_failure IS True AND nom_voie LIKE '% doct %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'gal', 'général') WHERE geocoding_failure IS True AND nom_voie LIKE '% gal %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'gen', 'général') WHERE geocoding_failure IS True AND nom_voie LIKE '% gen %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'mal', 'maréchal') WHERE geocoding_failure IS True AND nom_voie LIKE '% mal %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'mar', 'maréchal') WHERE geocoding_failure IS True AND nom_voie LIKE '% mar %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'pdt', 'président') WHERE geocoding_failure IS True AND nom_voie LIKE '% pdt %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'pres', 'président') WHERE geocoding_failure IS True AND nom_voie LIKE '% pres %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'prof', 'professeur') WHERE geocoding_failure IS True AND nom_voie LIKE '% prof %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'res ', 'résidence ') WHERE geocoding_failure IS True AND nom_voie LIKE '% res %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'saint-', 'saint ') WHERE geocoding_failure IS True AND nom_voie LIKE '% saint-%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'sainte-', 'sainte ') WHERE geocoding_failure IS True AND nom_voie LIKE '% sainte-%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'st ', 'saint ') WHERE geocoding_failure IS True AND nom_voie LIKE '% st %';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'ste ', 'sainte ') WHERE geocoding_failure IS True AND nom_voie LIKE '% ste %';

--accent
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'general', 'général') WHERE geocoding_failure IS True AND nom_voie LIKE '%general%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'republique', 'république') WHERE geocoding_failure IS True AND nom_voie LIKE '%republique%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'liberte', 'liberté') WHERE geocoding_failure IS True AND nom_voie LIKE '%liberte%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'president', 'président') WHERE geocoding_failure IS True AND nom_voie LIKE '%president%';

--article
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'e mairie', 'e de la mairie') WHERE nom_voie LIKE '%e mairie%' AND geocoding_failure IS True;
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'e république', 'e de la république') WHERE geocoding_failure IS True AND nom_voie LIKE '%e république%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'd république', 'd de la république') WHERE geocoding_failure IS True AND nom_voie LIKE '%d république%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'e liberté', 'e de la liberté') WHERE geocoding_failure IS True AND nom_voie LIKE '%e liberté%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'd liberté', 'd de la liberté') WHERE geocoding_failure IS True AND nom_voie LIKE '%d liberté%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'e général', 'e du général') WHERE geocoding_failure IS True AND nom_voie LIKE '%e général%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'd général', 'd du général') WHERE geocoding_failure IS True AND nom_voie LIKE '%d général%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'e président', 'e du président') WHERE geocoding_failure IS True AND nom_voie LIKE '%e président%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'd président', 'd du président') WHERE geocoding_failure IS True AND nom_voie LIKE '%d président%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'e maréchal', 'e du maréchal') WHERE geocoding_failure IS True AND nom_voie LIKE '%e maréchal%';
UPDATE reseau_coax.adresse SET nom_voie = replace(nom_voie,	'd maréchal', 'd du maréchal') WHERE geocoding_failure IS True AND nom_voie LIKE '%d maréchal%';

UPDATE reseau_coax.adresse SET geocoding_failure = Null WHERE geocoding_failure IS True;

DROP INDEX IF EXISTS reseau_coax.reseau_coax_adresse_nom_voie;

REINDEX INDEX reseau_coax.reseau_coax_adresse_code_ban_idx;
REINDEX INDEX reseau_coax.reseau_coax_adresse_geocoding_failure_idx;

COMMIT;
