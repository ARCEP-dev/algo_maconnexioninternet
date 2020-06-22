BEGIN;

---Installation de postgis sur la base
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

--------------------------------------- CREATION DES SCHEMAS ---------------------------------------

CREATE SCHEMA admin;
CREATE SCHEMA adresse;
CREATE SCHEMA eligibilite;
CREATE SCHEMA reference;
CREATE SCHEMA reseau_hz;
CREATE SCHEMA reseau_sat;
CREATE SCHEMA reseau_cu;
CREATE SCHEMA reseau_coax;
CREATE SCHEMA reseau_fo;
CREATE SCHEMA reseau_cell;

--------------------------------------- CREATION DES FONCTIONS ---------------------------------------

-- Création des fonctions utilisées dans les scripts
CREATE OR REPLACE FUNCTION updated_at_column() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language plpgsql;


CREATE OR REPLACE FUNCTION remove_multiple_spaces(string text) RETURNS text AS $$
  BEGIN
    IF(string LIKE '%  %') THEN
      RETURN remove_multiple_spaces(replace(string, '  ', ' '));
    ELSE
      RETURN string;
    END IF;
  END;
$$ LANGUAGE plpgsql;

---Fonction permettant de calculer l'affaiblissement de la ligne cuivre à l'immeuble à partir des affaiblissement au Point de Concentration (utilisée dans le script d'éligibilité cuivre)
CREATE OR REPLACE FUNCTION calcul_affaiblissement_cuivre(affaiblissement real, longueur_pc_ld integer, longueur_technique integer DEFAULT 100) RETURNS real AS $$
  BEGIN
    RETURN (affaiblissement - 3.0 + ((longueur_pc_ld * |/2) + longueur_technique)* 15/1000);
  END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION calcul_affaiblissement_cuivre IS 'affaiblissement est la valeur nra-pc en dB, longueur_pc_ld est la longueur à vol d''oiseau entre le pc et la prise terminale en m, longueur_technique est la longueur dans le nra et en partie privative avec 100 m par défaut.';

---Fonction permettant de calculer le débit cuivre à l'immeuble à partir de l'affaiblissement de la ligne à l'immeuble (utilisée dans le script d'éligibilité cuivre)
CREATE OR REPLACE FUNCTION calcul_debit_cuivre(techno varchar(5), affaiblissement real, sens varchar(4) DEFAULT 'down') RETURNS integer AS $$
  DECLARE debit real;
  BEGIN
    CASE techno
      WHEN 'ADSL' THEN
        CASE sens
          WHEN 'down' THEN
            CASE
              WHEN affaiblissement <= 78 THEN debit := (-0.2928109 + 24.2928109/(1 + (affaiblissement/27.81209)^3.271444)) * 1000;
              ELSE debit := 0;
            END CASE;
          WHEN 'up' THEN debit := 1000;
          ELSE RETURN null;
        END CASE;
      WHEN 'VDSL2' THEN
        CASE sens
          WHEN 'down' THEN
            CASE
              WHEN affaiblissement < 18 THEN debit := (-13.63789 + 113.63789/(1 + (affaiblissement/6.365011)^0.8638044)) * 1000;
              WHEN affaiblissement >= 18 THEN debit := calcul_debit_cuivre('ADSL',affaiblissement,'down');
              ELSE debit := 0;
            END CASE;
          WHEN 'up' THEN
            CASE
              WHEN affaiblissement < 10 THEN debit := 7 * 1000;
              WHEN affaiblissement < 14 THEN debit := 3 * 1000;
              WHEN affaiblissement < 78 THEN debit := 1 * 1000;
              ELSE debit := 0;
            END CASE;
          ELSE RETURN null;
        END CASE;
      ELSE RETURN null;
    END CASE;
    IF debit > 0.0 THEN
      RETURN debit::integer;
    ELSE
      RETURN 0;
    END IF;
  END;
  $$ LANGUAGE plpgsql;
COMMENT ON FUNCTION calcul_debit_cuivre IS 'Retourne le débit en kbit/s correspondant à l''affaiblissement fourni.';

---Fonction qui associe un débit calculé à se classe de débit
CREATE OR REPLACE FUNCTION classe_debit(debit real) RETURNS integer AS $$
  BEGIN
    IF debit >= 0.0
      THEN RETURN (SELECT id FROM reference.classe_debit WHERE actif IS True AND ((debit >= min AND debit < max) OR (debit >= min AND max IS NULL)));
    ELSE
      RETURN null;
    END IF;
  END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION classe_debit IS 'Retourne la clasee de débit correspondante au débit fourni en kbit/s.';


--------------------------------------- CREATION DES TABLES ---------------------------------------

-- Création des tables du schéma Référence
CREATE TABLE reference.fibre_etat(
  id smallserial,
  code character varying(5) NOT NULL,
  nom character varying(25) NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_fibre_etat_pkey PRIMARY KEY (id),
  CONSTRAINT reference_fibre_etat_ukey UNIQUE (code)
);

CREATE TABLE reference.operateur(
  id smallserial,
  code character varying(5) NOT NULL,
  code_interop character varying(5),
  nom character varying(150) NOT NULL,
  couleur character varying(7),
  parent_id smallint DEFAULT NULL,
  actif boolean NOT NULL DEFAULT True,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_operateur_pkey PRIMARY KEY (id),
  CONSTRAINT reference_operateur_unique_code UNIQUE (code),
  CONSTRAINT reference_operateur_parent FOREIGN KEY (parent_id) REFERENCES reference.operateur (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE reference.classe_debit(
  id smallserial,
  code character varying(6) NOT NULL,
  nom character varying(25) NOT NULL,
  min integer NOT NULL,
  max integer DEFAULT NULL,
  actif boolean NOT NULL DEFAULT True,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_classe_debit_pkey PRIMARY KEY (id),
  CONSTRAINT reference_classe_debit_ukey UNIQUE (nom)
);

CREATE TABLE reference.techno(
  id smallserial,
  code character varying(4) NOT NULL,
  nom character varying(25) NOT NULL,
  parent_id smallint DEFAULT NULL,
  actif boolean NOT NULL DEFAULT True,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_techno_pkey PRIMARY KEY (id),
  CONSTRAINT reference_techno_unique UNIQUE (code),
  CONSTRAINT reference_techno_parent FOREIGN KEY (parent_id) REFERENCES reference.techno (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE reference.perimetre(
  id smallserial,
  geom geometry(MultiPolygon),
  code character varying(5) NOT NULL,
  nom character varying(25) NOT NULL,
  epsg smallint DEFAULT NULL,
  actif boolean NOT NULL DEFAULT True,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_perimetre_pkey PRIMARY KEY (id),
  CONSTRAINT reference_perimetre_unique_code UNIQUE (code)
);

CREATE TABLE reference.fichier_type(
  id smallserial,
  techno_id smallint NOT NULL,
  code character varying(50) NOT NULL,
  nom character varying(50) NOT NULL,
  extension character varying(5)[],
  is_oi boolean NOT NULL,
  is_oc boolean NOT NULL,
  actif boolean NOT NULL DEFAULT True,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_fichier_type_pkey PRIMARY KEY (id),
  CONSTRAINT reference_fichier_type_ukey UNIQUE (code),
  CONSTRAINT reference_fichier_techno_id FOREIGN KEY (techno_id) REFERENCES reference.techno (id)
);

CREATE TABLE reference.operateur_techno(
  id smallserial,
  operateur_id smallint NOT NULL,
  techno_id smallint NOT NULL,
  is_oi boolean NOT NULL,
  is_oc boolean NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_operateur_techno_pkey PRIMARY KEY (id),
  CONSTRAINT reference_operateur_techno_ukey UNIQUE (operateur_id, techno_id),
  CONSTRAINT reference_operateur_techno_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reference_operateur_techno_techno_id FOREIGN KEY (techno_id) REFERENCES reference.techno (id)
);

CREATE TABLE reference.operateur_fichier(
  id smallserial,
  operateur_id smallint NOT NULL,
  fichier_type_id smallint NOT NULL,
  perimetre_id smallint NOT NULL,
  required boolean NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_operateur_fichier_pkey PRIMARY KEY (id),
  CONSTRAINT reference_operateur_fichier_unique UNIQUE (operateur_id, fichier_type_id, perimetre_id),
  CONSTRAINT reference_operateur_fichier_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reference_operateur_fichier_fichier_type_id FOREIGN KEY (fichier_type_id) REFERENCES reference.fichier_type (id),
  CONSTRAINT reference_operateur_fichier_perimetre_id FOREIGN KEY (perimetre_id) REFERENCES reference.perimetre (id)
);

CREATE TABLE reference.commune_zonage_type(
  id smallserial,
  nom character varying(25) NOT NULL,
  actif boolean NOT NULL DEFAULT True,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_commune_zonage_type_pkey PRIMARY KEY (id)
);

CREATE TABLE reference.engagmt_type(
  id smallserial,
  code character varying(5) NOT NULL,
  nom character varying(10) NOT NULL,
  actif boolean NOT NULL DEFAULT True,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_engagmt_type_pkey PRIMARY KEY (id),
  CONSTRAINT reference_engagmt_type_unique UNIQUE (nom)
);

-- Tables applicatives
CREATE TABLE reference.utilisateur(
  id serial,
  operateur_id integer NOT NULL,
  nom_utilisateur character varying(255) NOT NULL,
  email character varying(255) NOT NULL,
  role character varying(8) NOT NULL,
  condensat character varying(255) NOT NULL,
  nombre_essais integer NOT NULL,
  ticket character varying(255),
  validite_ticket timestamp,
  actif boolean NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_utilisateur_pkey PRIMARY KEY (id),
  CONSTRAINT reference_utilisateur_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur(id)
 );

 CREATE TABLE reference.parametre(
  id serial,
  code character varying(10) NOT NULL,
  valeur character varying(255),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_parametre_pkey PRIMARY KEY (id),
  CONSTRAINT reference_parametre_unique UNIQUE(code)
 );
COMMENT ON TABLE reference.parametre IS 'Table listant les divers paramètres du traitement et l''application : (seuils en nombre de lignes, nb jours avant, nb jours après)';

CREATE TABLE reference.trimestre(
  id serial,
  numero integer NOT NULL,
  date_limite character varying(4) NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_trimestre_pkey PRIMARY KEY (id),
  CONSTRAINT reference_trimestre_unique UNIQUE(numero)
);

CREATE TABLE reference.relance(
  id serial,
  nombre_jours integer NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_relance_pkey PRIMARY KEY (id),
  CONSTRAINT reference_relance_unique UNIQUE(nombre_jours)
);

CREATE TABLE reference.derogation(
  id serial,
  operateur_id integer NOT NULL,
  date date NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT reference_derogation_pkey PRIMARY KEY (id),
  CONSTRAINT reference_derogation_unique UNIQUE(operateur_id, date),
  CONSTRAINT reference_derogation_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id)
);


-- Création des tables du schéma admin (tables de référence sur les entités administratives)
CREATE TABLE admin.region(
  id serial,
  geom geometry(MultiPolygon),
  code character varying(2),
  nom character varying(35),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_region_pkey PRIMARY KEY (id),
  CONSTRAINT admin_region_ukey UNIQUE (code)
);

CREATE TABLE admin.departement(
  id serial,
  geom geometry(MultiPolygon),
  region_id integer NOT NULL,
  code character varying(3),
  nom character varying(30),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_departement_pkey PRIMARY KEY (id),
  CONSTRAINT admin_departement_ukey UNIQUE (code),
  CONSTRAINT admin_departement_region_id FOREIGN KEY (region_id) REFERENCES admin.region (id)
);

CREATE TABLE admin.epci(
  id serial,
  geom geometry(MultiPolygon),
  code character varying(9),
  type character varying(9),
  nom character varying(90),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_epci_pkey PRIMARY KEY (id),
  CONSTRAINT admin_epci_ukey UNIQUE (code)
);

CREATE TABLE admin.commune(
  id serial,
  geom geometry(MultiPolygon),
  departement_id integer NOT NULL,
  statut character varying(24),
  code_insee character varying(5),
  nom character varying(50),
  epci_id integer,
  population integer,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_commune_pkey PRIMARY KEY (id),
  CONSTRAINT admin_commune_ukey UNIQUE (code_insee),
  CONSTRAINT admin_commune_departement_id FOREIGN KEY (departement_id) REFERENCES admin.departement (id),
  CONSTRAINT admin_commune_epci_id FOREIGN KEY (epci_id) REFERENCES admin.epci (id)
);

CREATE TABLE admin.arrondissement(
  id serial,
  geom geometry(Polygon),
  code_insee character varying(5),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_arrondissement_pkey PRIMARY KEY (id),
  CONSTRAINT admin_arrondissement_ukey UNIQUE (code_insee)
);

CREATE TABLE admin.iris(
  id serial,
  geom geometry(MultiPolygon),
  code_insee character varying(5) NOT NULL,
  iris character varying(4),
  code character varying(9),
  nom character varying(60),
  type character varying(1),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_iris_pkey PRIMARY KEY (id),
  CONSTRAINT admin_iris_ukey UNIQUE (code_insee, code)
);

CREATE TABLE admin.insee_cog(
  id serial,
  code_insee_ancien character varying(5) NOT NULL,
  code_insee_actuel character varying(5) NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_insee_cog_pkey PRIMARY KEY (id),
  CONSTRAINT admin_insee_cog_ukey UNIQUE (code_insee_ancien, code_insee_actuel)
);

CREATE TABLE admin.commune_zonage(
  id serial,
  code_insee character varying(5) NOT NULL,
  zonage_type_id integer NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_commune_zonage_pkey PRIMARY KEY (id),
  CONSTRAINT admin_commune_zonage_ukey UNIQUE (code_insee, zonage_type_id),
  CONSTRAINT admin_commune_zonage_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee),
  CONSTRAINT admin_commune_zonage_zonage_type_id FOREIGN KEY (zonage_type_id) REFERENCES reference.commune_zonage_type (id)
);

CREATE TABLE admin.commune_capacite(
  id serial,
  code_insee character varying(5) NOT NULL,
  logements integer,
  locaux integer,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT admin_commune_capacite_pkey PRIMARY KEY (id),
  CONSTRAINT admin_commune_capacite_ukey UNIQUE (code_insee),
  CONSTRAINT admin_commune_capacite_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);

CREATE MATERIALIZED VIEW admin.com_dept_reg AS (
  SELECT commune.id AS commune_id, commune.code_insee AS code_insee, departement.id AS departement_id, departement.code AS departement_code, region.id AS region_id, region.code AS region_code
  FROM admin.commune
  LEFT JOIN admin.departement ON departement.id = commune.departement_id
  LEFT JOIN admin.region ON region.id = departement.region_id
);

-- Création des tables du schéma adresse (ces tables sont utilisées pour produire le referentiel commun d'immeubles, d'adresses et de locaux)
CREATE TABLE adresse.adresse(
  id serial,
  code character varying(30),
  source character varying(5) NOT NULL, -- valeurs : ban, fo, zlin, cu, etc...
  geom geometry(Point),
  id_fantoir character varying(4),
  numero integer,
  rep character varying(6),
  nom_voie character varying(50),
  nom_ld character varying(50),
  code_insee character varying(5) NOT NULL,
  alias character varying(50),
  nom_afnor character varying(255),
  nom_commune character varying(255),
  nbr_log integer DEFAULT NULL,
  nbr_loc integer DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT adresse_adresse_pkey PRIMARY KEY (id),
  CONSTRAINT adresse_adresse_unique UNIQUE (code),
  CONSTRAINT adresse_adresse_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);


CREATE TABLE adresse.immeuble(
  id serial,
  geom geometry(Point),
  iris_id integer,
  source character varying(5) NOT NULL, -- valeurs : ban, fo, zlin, cu, etc...
  code character varying(30), -- md5('name')::character varying(6)
  num_immeuble character varying(25), -- identifiant de l'immeuble: numero, lettre, nom
  type character varying(25), -- app/maison
  nbr_log integer DEFAULT NULL,
  nbr_loc integer DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  code_insee character varying(5) NOT NULL,
  CONSTRAINT adresse_immeuble_pkey PRIMARY KEY (id),
  CONSTRAINT adresse_immeuble_iris_id FOREIGN KEY (iris_id) REFERENCES admin.iris (id),
  CONSTRAINT adresse_immeuble_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);


CREATE TABLE adresse.adresse_immeuble(
  id serial,
  adresse_id integer NOT NULL,
  immeuble_id integer NOT NULL,
  CONSTRAINT adresse_adresse_immeuble_pkey PRIMARY KEY (id),
  CONSTRAINT adresse_adresse_immeuble_unique UNIQUE (adresse_id, immeuble_id),
  CONSTRAINT adresse_adresse_immeuble_adresse_fkey FOREIGN KEY (adresse_id) REFERENCES adresse.adresse (id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT adresse_adresse_immeuble_immeuble_fkey FOREIGN KEY (immeuble_id) REFERENCES adresse.immeuble (id) ON UPDATE NO ACTION ON DELETE NO ACTION
);


CREATE TABLE adresse.fpb(
  id serial,
  geom geometry(Point),
  code character varying(24),
  numero integer,
  rep character varying(6),
  nom_voie character varying(150),
  code_insee character varying(5),
  code_ban character varying(30),
  parcelles json,
  nbr_log integer,
  nbr_loc integer,
  created_at timestamp without time zone,
  updated_at timestamp without time zone,
  source_ban character varying(30),
  source_geocodage character varying(30),
  CONSTRAINT adresse_fpb_pkey PRIMARY KEY (id),
  CONSTRAINT adresse_fpb_unique UNIQUE (code),
  CONSTRAINT adresse_fpb_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);



CREATE TABLE adresse.adresse_bati( -- lien adresse IGN <-> bati IGN
  id serial,
  code character varying(24),
  code_insee character varying(5),
  id_adr character varying(24),
  code_adresse character varying(24),
  id_bat character varying(24),
  type_lien character varying(20),
  nb_adr integer,
  nb_bati integer,
  origin_bat character varying(8),
  type_bat character varying(25),
  surf_bat numeric(18,2),
  haut_bat integer,
  z_min_bat numeric(7,2),
  z_max_bat numeric(7,2),
  CONSTRAINT adresse_adresse_bati_pkey PRIMARY KEY (id),
  CONSTRAINT adresse_adresse_bati_ukey UNIQUE (code),
  CONSTRAINT adresse_adresse_bati_code_adresse FOREIGN KEY (code_adresse) REFERENCES adresse.adresse (code)
);


CREATE MATERIALIZED VIEW adresse.base_imb AS (
  SELECT addr.id AS addr_id, addr.code AS addr_code, addr.source AS addr_source, addr.geom AS addr_geom, addr.id_fantoir AS addr_id_fantoir, addr.numero AS addr_numero, addr.rep AS addr_rep, addr.nom_voie AS addr_nom_voie, addr.nom_ld AS addr_nom_ld, addr.code_insee AS code_insee, addr.alias AS addr_alias, addr.nom_afnor AS addr_nom_afnor, addr.nom_commune AS addr_nom_commune, addr.nbr_log AS addr_nbr_log, addr.nbr_loc AS addr_nbr_loc,
  imb.id AS imb_id, imb.geom AS imb_geom, imb.iris_id AS imb_iris_id, imb.source AS imb_source, imb.code AS imb_code, imb.num_immeuble AS imb_num, imb.code_insee AS imb_code_insee, imb.type AS imb_type, imb.nbr_log AS imb_nbr_log, imb.nbr_loc AS imb_nbr_loc
  FROM adresse.adresse AS addr
  INNER JOIN adresse.adresse_immeuble AS addr_imb ON addr_imb.adresse_id = addr.id
  INNER JOIN adresse.immeuble AS imb ON imb.id = addr_imb.immeuble_id
);


CREATE TABLE adresse.iris(
  id serial,
  iris_id integer NOT NULL,
  nbr_log integer,
  nbr_loc integer,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT adresse_iris_pkey PRIMARY KEY (id),
  CONSTRAINT adresse_iris_ukey UNIQUE (iris_id),
  CONSTRAINT adresse_iris_iris_id FOREIGN KEY (iris_id) REFERENCES admin.iris (id)
);

CREATE MATERIALIZED VIEW adresse.commune AS (
  SELECT com_dept_reg.commune_id AS commune_id, SUM(COALESCE(imb_nbr_log, 0)) AS nbr_log, SUM(COALESCE(imb_nbr_loc, 0)) AS nbr_loc
  FROM admin.com_dept_reg
  LEFT JOIN adresse.base_imb ON base_imb.code_insee = com_dept_reg.code_insee
  GROUP BY com_dept_reg.commune_id
);

CREATE TABLE adresse.epci(
  id serial,
  epci_id integer NOT NULL,
  nbr_log integer,
  nbr_loc integer,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT adresse_epci_pkey PRIMARY KEY (id),
  CONSTRAINT adresse_epci_ukey UNIQUE (epci_id),
  CONSTRAINT adresse_epci_epci_id FOREIGN KEY (epci_id) REFERENCES admin.epci (id)
);

CREATE OR REPLACE VIEW adresse.departement AS (
  SELECT com_dept_reg.departement_id AS departement_id, SUM(nbr_log) AS nbr_log, SUM(nbr_loc) AS nbr_loc
  FROM adresse.commune
  INNER JOIN admin.com_dept_reg ON com_dept_reg.commune_id = commune.commune_id
  GROUP BY com_dept_reg.departement_id
);

CREATE OR REPLACE VIEW adresse.region AS (
  SELECT com_dept_reg.region_id AS region_id, SUM(nbr_log) AS nbr_log, SUM(nbr_loc) AS nbr_loc
  FROM adresse.commune
  INNER JOIN admin.com_dept_reg ON com_dept_reg.commune_id = commune.commune_id
  GROUP BY com_dept_reg.region_id
);


-- Création des tables du schéma réseau_cu (ce schéma contient toutes les données d'entrée sur la technologie cuivre)
CREATE TABLE reseau_cu.nra(
  id serial,
  code character varying(8) NOT NULL,
  nom character varying(50),
  code_insee character varying(5) NOT NULL,
  code_insee_a character varying(5) DEFAULT NULL,
  nbr_podi integer,
  nbr_ld integer,
  type_collecte character varying(2),
  reseau_structurant boolean,
  adsl boolean,
  vdsl boolean,
  plafonnement_debit smallint DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cu_nra_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cu_nra_unique UNIQUE (code),
  CONSTRAINT reseau_cu_nra_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);

CREATE TABLE reseau_cu.sr(
  id serial,
  nra_id integer NOT NULL,
  code character varying(20) NOT NULL,
  code_insee character varying(5) NOT NULL,
  code_insee_a character varying(5) DEFAULT NULL,
  nbr_ld integer,
  affaiblissement_min real DEFAULT NULL,
  affaiblissement_max real DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cu_sr_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cu_sr_unique UNIQUE (code),
  CONSTRAINT reseau_cu_sr_nra_id FOREIGN KEY (nra_id) REFERENCES reseau_cu.nra (id),
  CONSTRAINT reseau_cu_sr_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);

CREATE TABLE reseau_cu.pc(
  id serial,
  geom geometry(Point),
  sr_id integer NOT NULL,
  code character varying(28) NOT NULL,
  code_insee character varying(5) NOT NULL,
  code_insee_a character varying(5) DEFAULT NULL,
  nbr_ld integer,
  affaiblissement real DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cu_pc_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cu_pc_unique UNIQUE (sr_id, code),
  CONSTRAINT reseau_cu_pc_sr_id FOREIGN KEY (sr_id) REFERENCES reseau_cu.sr (id),
  CONSTRAINT reseau_cu_pc_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);

CREATE TABLE reseau_cu.ld(
  id serial,
  geom geometry(Point),
  numero integer,
  active boolean NOT NULL,
  pc_id integer NOT NULL,
  affaiblissement real,
  incompatible_hd boolean,
  technique boolean,
  batiment character varying(70),
  numero_voie integer,
  nom_voie character varying(50) DEFAULT NULL,
  code_insee character varying(5) NOT NULL,
  code_insee_a character varying(5) DEFAULT NULL,
  code_ban character varying(26),
  fictive boolean DEFAULT False,
  geocoding_failure boolean DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cu_ld_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cu_ld_unique UNIQUE (numero, active),
  CONSTRAINT reseau_cu_ld_pc_id FOREIGN KEY (pc_id) REFERENCES reseau_cu.pc (id),
  CONSTRAINT reseau_cu_ld_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);

CREATE TABLE reseau_cu.oc_nra(
  id serial,
  operateur_id smallint,
  nra_id integer NOT NULL,
  techno_dsl smallint,
  type_presence smallint,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cu_oc_nra_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cu_oc_nra_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_cu_oc_nra_nra_id FOREIGN KEY (nra_id) REFERENCES reseau_cu.nra (id)
);

CREATE TABLE reseau_cu.oc_pc_sans_service(
  id serial,
  operateur_id smallint,
  pc_id integer NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cu_oc_pc_sans_service_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cu_oc_pc_sans_service_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_cu_oc_pc_sans_service_pc_id FOREIGN KEY (pc_id) REFERENCES reseau_cu.pc (id)
);

CREATE TABLE reseau_cu.oc_ld_sans_service(
  id serial,
  operateur_id smallint,
  pc_id integer NOT NULL,
  ld_id integer NOT NULL,
  code_ban character varying(26),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT oc_ld_sans_service_pkey PRIMARY KEY (id),
  CONSTRAINT oc_ld_sans_service_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT oc_ld_sans_service_pc_id FOREIGN KEY (pc_id) REFERENCES reseau_cu.pc (id),
  CONSTRAINT oc_ld_sans_service_ld_id FOREIGN KEY (ld_id) REFERENCES reseau_cu.ld (id)
);

CREATE MATERIALIZED VIEW reseau_cu.pc_sr_nra AS (
  SELECT pc.id AS pc_id, sr.id AS sr_id, sr.nra_id AS nra_id
  FROM reseau_cu.pc
  INNER JOIN reseau_cu.sr ON sr.id = pc.sr_id
);

-- Création des tables du schéma réseau_fo (ce schéma contient toutes les données d'entrée sur la technologie fibre)
CREATE TABLE reseau_fo.zlin_imb(
  id serial,
  code_imb character varying(30) NOT NULL,
  batiment character varying(70),
  numero_voie smallint,
  complement character varying(6),
  type_voie character varying(50),
  nom_voie character varying(100),
  code_insee character varying(5) NOT NULL,
  code_insee_a character varying(5) DEFAULT NULL,
  nbr_log smallint,
  nbr_loc smallint,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_fo_zlin_imb_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_fo_zlin_code_imb_ukey UNIQUE (code_imb),
  CONSTRAINT reseau_fo_zlin_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);

CREATE TABLE reseau_fo.pm(
  id serial,
  id_source integer,
  code character varying(22),
  etat_id integer NOT NULL,
  date_install date,
  operateur_id smallint,
  capa_max integer,
  code_insee character varying(5) NOT NULL,
  code_insee_a character varying(5) DEFAULT NULL,
  nb_lgt integer,
  nb_lgt_calc integer,
  nb_lgt_mad_calc integer,
  date_mes_commerc date,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_fo_pm_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_fo_pm_ukey UNIQUE (code),
  CONSTRAINT reseau_fo_pm_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_fo_pm_etat_fkey FOREIGN KEY (etat_id) REFERENCES reference.fibre_etat (id),
  CONSTRAINT reseau_fo_pm_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);

CREATE TABLE reseau_fo.zapm(
  id serial,
  id_source integer,
  geom geometry(MultiPolygon),
  pm_id integer NOT NULL,
  potentiel boolean,
  date_consultation date,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_fo_zapm_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_fo_zapm_pm_fkey FOREIGN KEY (pm_id) REFERENCES reseau_fo.pm (id)
);

CREATE TABLE reseau_fo.imb(
  id serial,
  id_source integer,
  geom geometry(POINT),
  operateur_id smallint,
  code_imb character varying(30) NOT NULL,
  code_ban character varying(26),
  batiment character varying(70),
  numero_voie integer,
  complement_voie character varying(6),
  type_voie character varying(50),
  nom_voie character varying(50),
  code_insee character varying(5) NOT NULL,
  code_insee_a character varying(5) DEFAULT NULL,
  etat_id integer NOT NULL,
  type_imb character varying(5),
  nbr_log integer,
  pm_id integer NOT NULL,
  geocoding_failure boolean DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_fo_imb_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_fo_imb_ukey UNIQUE (code_imb),
  CONSTRAINT reseau_fo_imb_pm_fkey FOREIGN KEY (pm_id) REFERENCES reseau_fo.pm (id),
  CONSTRAINT reseau_fo_imb_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_fo_imb_pm_etat_fkey FOREIGN KEY (etat_id) REFERENCES reference.fibre_etat (id),
  CONSTRAINT reseau_fo_imb_code_insee FOREIGN KEY (code_insee) REFERENCES admin.commune (code_insee)
);

CREATE TABLE reseau_fo.oc_pm(
  id serial,
  operateur_id smallint,
  pm_id integer NOT NULL,
  debit_montant integer,
  debit_descendant integer,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_fo_oc_pm_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_fo_oc_pm_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id)
);

CREATE TABLE reseau_fo.oc_imb_sans_service(
  id serial,
  operateur_id smallint,
  pm_id integer NOT NULL,
  imb_id integer NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_fo_oc_imb_sans_service_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_fo_oc_imb_sans_service_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_fo_oc_imb_sans_service_pm_id FOREIGN KEY (pm_id) REFERENCES reseau_fo.pm (id),
  CONSTRAINT reseau_fo_oc_imb_sans_service_imb_id FOREIGN KEY (imb_id) REFERENCES reseau_fo.imb (id)
);

-- Création des tables du schéma réseau_coax (ce schéma contient toutes les données d'entrée sur la technologie câble)
CREATE TABLE reseau_coax.tdr(
  id serial,
  geom geometry(MultiPolygon),
  operateur_id smallint,
  code character varying(20),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_coax_tdr_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_coax_tdr_ukey UNIQUE (code),
  CONSTRAINT reseau_coax_tdr_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id)
);

CREATE TABLE reseau_coax.pcc(
  id serial,
  geom geometry(POINT),
  tdr_id integer NOT NULL,
  code character varying(25),
  code_insee character varying(5),
  nbr_prise smallint,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_coax_pcc_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_coax_pcc_ukey UNIQUE (code),
  CONSTRAINT reseau_coax_pcc_tdr_id FOREIGN KEY (tdr_id) REFERENCES reseau_coax.tdr (id)
);

CREATE TABLE reseau_coax.adresse(
  id serial,
  geom geometry(POINT),
  tdr_id integer NOT NULL,
  pcc_id integer NOT NULL,
  nbr_prise smallint,
  code_ban character varying(26),
  numero_voie smallint,
  complement character varying(6),
  type_voie character varying(50),
  nom_voie character varying(100),
  code_insee character varying(5) NOT NULL,
  geocoding_failure boolean DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_coax_adresse_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_coax_adresse_tdr_id FOREIGN KEY (tdr_id) REFERENCES reseau_coax.tdr (id),
  CONSTRAINT reseau_coax_adresse_pcc_id FOREIGN KEY (pcc_id) REFERENCES reseau_coax.pcc (id)
);

CREATE TABLE reseau_coax.oc_tdr(
  id serial,
  operateur_id smallint,
  tdr_id integer NOT NULL,
  debit_montant integer,
  debit_descendant integer,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_coax_oc_tdr_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_coax_oc_tdr_unique UNIQUE (operateur_id, tdr_id),
  CONSTRAINT reseau_coax_oc_tdr_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_coax_oc_tdr_tdr_id FOREIGN KEY (tdr_id) REFERENCES reseau_coax.tdr (id)
);

CREATE TABLE reseau_coax.oc_pcc(
  id serial,
  operateur_id smallint,
  pcc_id integer NOT NULL,
  debit_montant integer,
  debit_descendant integer,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_coax_oc_pcc_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_coax_oc_pcc_unique UNIQUE (operateur_id, pcc_id),
  CONSTRAINT reseau_coax_oc_pcc_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_coax_oc_pcc_pcc_id FOREIGN KEY (pcc_id) REFERENCES reseau_coax.pcc (id)
);

CREATE TABLE reseau_coax.oc_prise_sans_service(
  id serial,
  operateur_id smallint,
  code_ban character varying(26),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_coax_oc_prise_sans_service_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_coax_oc_prise_sans_service_unique UNIQUE (operateur_id, code_ban),
  CONSTRAINT reseau_coax_oc_prise_sans_service_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id)
);

-- Création des tables du schéma réseau_cell (ce schéma contient toutes les données d'entrée sur la technologie 4G fixe)
CREATE TABLE reseau_cell.reseau(
  id serial,
  operateur_id integer NOT NULL,
  code character varying(20),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cell_reseau_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cell_reseau_ukey UNIQUE (code),
  CONSTRAINT reseau_cell_reseau_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id)
);

CREATE TABLE reseau_cell.site(
  id serial,
  geom geometry(Point),
  reseau_id integer NOT NULL,
  code character varying(20),
  code_insee character varying(5),
  techno_id smallint NOT NULL,
  ouverture_commerciale boolean,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cell_site_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cell_site_ukey UNIQUE (code),
  CONSTRAINT reseau_cell_site_reseau_id FOREIGN KEY (reseau_id) REFERENCES reseau_cell.reseau (id),
  CONSTRAINT reseau_cell_site_techno_id FOREIGN KEY (techno_id) REFERENCES reference.techno (id)
);

CREATE TABLE reseau_cell.couverture(
  id serial,
  geom geometry,
  operateur_id integer NOT NULL,
  reseau_id integer NOT NULL,
  site_id integer DEFAULT NULL,
  saturation boolean NOT NULL DEFAULT FALSE,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cell_couverture_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cell_couverture_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_cell_couverture_site_id FOREIGN KEY (site_id) REFERENCES reseau_cell.site (id)
);

CREATE TABLE reseau_cell.oc(
  id serial,
  operateur_id integer NOT NULL,
  reseau_id integer NOT NULL,
  debit_montant integer,
  debit_descendant integer,
  limitation_donnee smallint, -- en GB
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_cell_oc_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_cell_oc_ukey UNIQUE (operateur_id, reseau_id),
  CONSTRAINT reseau_cell_oc_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_cell_oc_reseau_id FOREIGN KEY (reseau_id) REFERENCES reseau_cell.reseau (id)
);

-- Création des tables du schéma réseau_hz (ce schéma contient toutes les données d'entrée sur les technologies radio)
CREATE TABLE reseau_hz.reseau(
  id serial,
  operateur_id smallint,
  code character varying(20),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_hz_reseau_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_hz_reseau_ukey UNIQUE (code),
  CONSTRAINT reseau_hz_reseau_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id)
  );

CREATE TABLE reseau_hz.site(
  id serial,
  reseau_id smallint,
  code character varying(20),
  code_insee character varying(5),
  techno_id smallint NOT NULL,
  bande_frequence character varying(40),
  type_collecte smallint,
  ouverture_commerciale boolean,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_hz_site_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_hz_site_ukey UNIQUE (code),
  CONSTRAINT reseau_hz_site_techno_id FOREIGN KEY (techno_id) REFERENCES reference.techno (id)
);

CREATE TABLE reseau_hz.couverture(
  id serial,
  geom geometry,
  operateur_id smallint,
  reseau_id integer NOT NULL,
  site_id integer DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_hz_couverture_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_hz_couverture_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id)
);

CREATE TABLE reseau_hz.oc(
  id serial,
  operateur_id smallint,
  reseau_id integer NOT NULL,
  debit_montant integer,
  debit_descendant integer,
  limitation_donnee smallint, -- en GB
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_hz_oc_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_hz_oc_ukey UNIQUE (operateur_id, reseau_id),
  CONSTRAINT reseau_hz_oc_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_hz_oc_reseau_id FOREIGN KEY (reseau_id) REFERENCES reseau_hz.reseau (id)
);

-- Création des tables du schéma réseau_sat (ce schéma contient toutes les données d'entrée sur la technologie satellite)
CREATE TABLE reseau_sat.reseau(
  id serial,
  geom geometry,
  operateur_id smallint,
  code character varying(33),
  bande_frequence character varying(40),
  ouverture_commerciale boolean,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_sat_reseau_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_sat_reseau_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id)
);

CREATE TABLE reseau_sat.oc(
  id serial,
  operateur_id smallint,
  reseau_id integer NOT NULL,
  debit_montant integer,
  debit_descendant integer,
  limitation_donnee smallint, -- en GB
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  fichier_id integer NOT NULL,
  CONSTRAINT reseau_sat_oc_pkey PRIMARY KEY (id),
  CONSTRAINT reseau_sat_oc_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT reseau_sat_oc_reseau_id FOREIGN KEY (reseau_id) REFERENCES reseau_sat.reseau (id)
);

-- Création des tables du schéma éligibilité :
--- la table eligibilite.actuel présente un triplé d'éligibilité (immeuble, technologie, débit) par ligne. Ces informations d'éligibilité se retrouvent dans la carte DEBITS de Ma connexion internet, en cliquant sur un immeuble
--- la table eligibilite.previsionnel n'est actuellement pas utilisée (vide)

CREATE TABLE eligibilite.actuel(
  id serial,
  immeuble_id integer NOT NULL,
  operateur_id smallint,
  techno_id smallint NOT NULL,
  debit_montant integer NOT NULL,
  debit_descendant integer NOT NULL,
  limitation integer DEFAULT NULL,
  saturation boolean DEFAULT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT eligibilite_actuel_pkey PRIMARY KEY (id),
  CONSTRAINT eligibilite_actuel_immeuble_id FOREIGN KEY (immeuble_id) REFERENCES adresse.immeuble (id),
  CONSTRAINT eligibilite_actuel_operateur_id FOREIGN KEY (operateur_id) REFERENCES reference.operateur (id),
  CONSTRAINT eligibilite_actuel_techno_id FOREIGN KEY (techno_id) REFERENCES reference.techno (id)
);

CREATE TABLE eligibilite.previsionnel(
  id serial,
  immeuble_id integer NOT NULL,
  operateur_id smallint,
  techno_id smallint NOT NULL,
  debit_montant integer NOT NULL,
  debit_descendant integer NOT NULL,
  date character varying(10),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT NULL,
  CONSTRAINT eligibilite_previsionnel_pkey PRIMARY KEY (id),
  CONSTRAINT eligibilite_previsionnel_immeuble_id FOREIGN KEY (immeuble_id) REFERENCES adresse.immeuble (id),
  CONSTRAINT eligibilite_previsionnel_techno_id FOREIGN KEY (techno_id) REFERENCES reference.techno (id)
);

--------------------------------------- CREATION DES INDEXS ---------------------------------------
-- Création des index du schema admin
CREATE INDEX admin_region_geom_idx ON admin.region USING gist (geom);
CREATE INDEX admin_departement_geom_idx ON admin.departement USING gist (geom);
CREATE INDEX admin_epci_geom_idx ON admin.epci USING gist (geom);
CREATE INDEX admin_commune_geom_idx ON admin.commune USING gist (geom);
CREATE INDEX admin_arrondissement_geom_idx ON admin.arrondissement USING gist (geom);
CREATE INDEX admin_iris_geom_idx ON admin.iris USING gist (geom);

-- Création des index du schema adresse
CREATE INDEX adresse_adresse_geom_idx ON adresse.adresse USING gist (geom);
CREATE INDEX adresse_adresse_source_idx ON adresse.adresse USING btree (source);
CREATE INDEX adresse_adresse_code_insee_idx ON adresse.adresse USING btree (code_insee);
CREATE INDEX adresse_immeuble_geom_idx ON adresse.immeuble USING gist (geom);
CREATE INDEX adresse_immeuble_source_idx ON adresse.immeuble USING btree (source);
CREATE INDEX adresse_immeuble_code_insee_idx ON adresse.immeuble USING btree (code_insee);
CREATE INDEX adresse_adresse_immeuble_adresse_id_idx ON adresse.adresse_immeuble USING btree (adresse_id);
CREATE INDEX adresse_adresse_immeuble_immeuble_id_idx ON adresse.adresse_immeuble USING btree (immeuble_id);

CREATE INDEX adresse_base_imb_addr_id_idx ON adresse.base_imb USING btree (addr_id);
CREATE INDEX adresse_base_imb_imb_id_idx ON adresse.base_imb USING btree (imb_id);
CREATE INDEX adresse_base_imb_addr_geom_idx ON adresse.base_imb USING gist (addr_geom);
CREATE INDEX adresse_base_imb_imb_geom_idx ON adresse.base_imb USING gist (imb_geom);
CREATE INDEX adresse_base_imb_code_insee_idx ON adresse.base_imb USING btree (code_insee);
CREATE INDEX adresse_base_imb_addr_source_idx ON adresse.base_imb USING btree (addr_source);
CREATE INDEX adresse_base_imb_imb_source_idx ON adresse.base_imb USING btree (imb_source);
CREATE INDEX adresse_base_imb_addr_code_idx ON adresse.base_imb USING btree (addr_code);
CREATE INDEX adresse_base_imb_imb_code_idx ON adresse.base_imb USING btree (imb_code);


-- Création des index du schema reseau_cu
CREATE INDEX reseau_cu_nra_code_insee_idx ON reseau_cu.nra USING btree (code_insee ASC NULLS LAST);

--CREATE INDEX reseau_cu_sr_geom_idx ON reseau_cu.sr USING gist (geom);
CREATE INDEX reseau_cu_sr_code_insee_idx ON reseau_cu.sr USING btree (code_insee);

CREATE INDEX reseau_cu_pc_geom_idx ON reseau_cu.pc USING gist (geom);
CREATE INDEX reseau_cu_pc_sr_id_idx ON reseau_cu.pc USING btree (sr_id);
CREATE INDEX reseau_cu_pc_code_insee_idx ON reseau_cu.pc USING btree (code_insee);

CREATE INDEX reseau_cu_ld_geom_idx ON reseau_cu.ld USING gist (geom);
CREATE INDEX reseau_cu_ld_pc_id_idx ON reseau_cu.ld USING btree (pc_id ASC);
CREATE INDEX reseau_cu_ld_code_insee_idx ON reseau_cu.ld USING btree (code_insee ASC);
CREATE INDEX reseau_cu_ld_code_ban_idx ON reseau_cu.ld USING btree (code_ban ASC NULLS FIRST);
CREATE INDEX reseau_cu_ld_geocoding_failure_idx ON reseau_cu.ld USING btree (geocoding_failure NULLS FIRST);

CREATE INDEX reseau_cu_pc_sr_nra_idx ON reseau_cu.pc_sr_nra USING btree (pc_id);

-- Création des index du schema reseau_fo
CREATE INDEX reseau_fo_zlin_imb_code_insee_idx ON reseau_fo.zlin_imb USING btree (code_insee ASC);

CREATE INDEX reseau_fo_pm_code_insee_idx ON reseau_fo.pm USING btree (code_insee ASC);

CREATE INDEX reseau_fo_zapm_geom_idx ON reseau_fo.zapm USING gist (geom);

CREATE INDEX reseau_fo_imb_geom_idx ON reseau_fo.imb USING gist (geom);
CREATE INDEX reseau_fo_imb_code_insee_idx ON reseau_fo.imb USING btree (code_insee ASC);
CREATE INDEX reseau_fo_imb_code_ban_idx ON reseau_fo.imb USING btree (code_ban ASC NULLS FIRST);
CREATE INDEX reseau_fo_imb_geocoding_failure_idx ON reseau_fo.imb USING btree (geocoding_failure NULLS FIRST);

-- Création des index du schema reseau_coax
CREATE INDEX reseau_coax_tdr_geom_idx ON reseau_coax.tdr USING gist (geom);

CREATE INDEX reseau_coax_pcc_geom_idx ON reseau_coax.pcc USING gist (geom);
CREATE INDEX reseau_coax_pcc_code_insee_idx ON reseau_coax.pcc USING btree (code_insee);

CREATE INDEX reseau_coax_adresse_geom_idx ON reseau_coax.adresse USING gist (geom);
CREATE INDEX reseau_coax_adresse_code_insee_idx ON reseau_coax.adresse USING btree (code_insee);
CREATE INDEX reseau_coax_adresse_code_ban_idx ON reseau_coax.adresse USING btree (code_ban ASC NULLS FIRST);
CREATE INDEX reseau_coax_adresse_geocoding_failure_idx ON reseau_coax.adresse USING btree (geocoding_failure NULLS FIRST);

-- Création des index du schema reseau_cell
CREATE INDEX reseau_cell_site_geom_idx ON reseau_cell.site USING gist (geom);
CREATE INDEX reseau_cell_site_code_insee_idx ON reseau_cell.site USING btree (code_insee);

CREATE INDEX reseau_cell_couverture_geom_idx ON reseau_cell.couverture USING gist (geom);
CREATE INDEX reseau_cell_couverture_saturation_idx ON reseau_cell.couverture USING btree (saturation);

-- Création des index du schema reseau_hz
CREATE INDEX reseau_hz_site_code_insee_idx ON reseau_hz.site USING btree (code_insee);

CREATE INDEX reseau_hz_couverture_geom_idx ON reseau_hz.couverture USING gist (geom);

-- Création des index du schema eligibilite
CREATE INDEX eligibilite_actuel_immeuble_id_idx ON eligibilite.actuel USING btree (immeuble_id);
CREATE INDEX eligibilite_actuel_operateur_id_idx ON eligibilite.actuel USING btree (operateur_id);
CREATE INDEX eligibilite_actuel_techno_id_idx ON eligibilite.actuel USING btree (techno_id);
CREATE INDEX eligibilite_actuel_debit_descendant_idx ON eligibilite.actuel USING btree (debit_descendant);

CREATE INDEX eligibilite_previsionnel_immeuble_id_idx ON eligibilite.previsionnel USING btree (immeuble_id);
CREATE INDEX eligibilite_previsionnel_operateur_id_idx ON eligibilite.previsionnel USING btree (operateur_id);
CREATE INDEX eligibilite_previsionnel_techno_id_idx ON eligibilite.previsionnel USING btree (techno_id);
CREATE INDEX eligibilite_previsionnel_debit_descendant_idx ON eligibilite.previsionnel USING btree (debit_descendant);


--------------------------------------- CREATION DES VUES ---------------------------------------

-- Création des vues administratives
CREATE OR REPLACE VIEW tables_geom_list AS (
	SELECT f_table_schema AS schema, f_table_name AS table, f_geometry_column AS geometry_column, coord_dimension AS dimension, srid, type
	FROM geometry_columns);

CREATE OR REPLACE VIEW tables_list AS (
  SELECT table_schema AS schema, table_name AS table, table_type AS type
  FROM information_schema.tables
  WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
  AND table_name NOT IN ('geography_columns', 'geometry_columns', 'raster_columns', 'raster_overviews', 'spatial_ref_sys')
  ORDER BY table_schema,table_name);

--------------------------------------- CREATION DES TRIGGERS ---------------------------------------

-- Création des Triggers du schema admin
CREATE TRIGGER admin_region_updated_at BEFORE UPDATE ON admin.region FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER admin_departement_updated_at BEFORE UPDATE ON admin.departement FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER admin_epci_updated_at BEFORE UPDATE ON admin.epci FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER admin_commune_updated_at BEFORE UPDATE ON admin.commune FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER admin_arrondissement_updated_at BEFORE UPDATE ON admin.arrondissement FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER admin_iris_updated_at BEFORE UPDATE ON admin.iris FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER admin_insee_cog_updated_at BEFORE UPDATE ON admin.insee_cog FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER admin_commune_zonage_updated_at BEFORE UPDATE ON admin.commune_zonage FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER admin_commune_capacite_updated_at BEFORE UPDATE ON admin.commune_capacite FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

-- Création des Triggers du schema reference
CREATE TRIGGER reference_fibre_etat_updated_at BEFORE UPDATE ON reference.fibre_etat FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_operateur_updated_at BEFORE UPDATE ON reference.operateur FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_classe_debit_updated_at BEFORE UPDATE ON reference.classe_debit FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_techno_updated_at BEFORE UPDATE ON reference.techno FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_perimetre_updated_at BEFORE UPDATE ON reference.perimetre FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_fichier_type_updated_at BEFORE UPDATE ON reference.fichier_type FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_operateur_techno_updated_at BEFORE UPDATE ON reference.operateur_techno FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_operateur_fichier_updated_at BEFORE UPDATE ON reference.operateur_fichier FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_commune_zonage_type_updated_at BEFORE UPDATE ON reference.commune_zonage_type FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_engagmt_type_updated_at BEFORE UPDATE ON reference.engagmt_type FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_utilisateur_updated_at BEFORE UPDATE ON reference.utilisateur FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_parametre_updated_at BEFORE UPDATE ON reference.parametre FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_trimestre_updated_at BEFORE UPDATE ON reference.trimestre FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_relance_updated_at BEFORE UPDATE ON reference.relance FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reference_derogation_updated_at BEFORE UPDATE ON reference.derogation FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

-- Création des Triggers du schema adresse
CREATE TRIGGER adresse_adresse_updated_at BEFORE UPDATE ON adresse.adresse FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER adresse_immeuble_updated_at BEFORE UPDATE ON adresse.immeuble FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER adresse_adresse_immeuble_updated_at BEFORE UPDATE ON adresse.adresse_immeuble FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER adresse_fpb_updated_at BEFORE UPDATE ON adresse.fpb FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER adresse_adresse_bati_updated_at BEFORE UPDATE ON adresse.adresse_bati FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER adresse_iris_updated_at BEFORE UPDATE ON adresse.iris FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER adresse_epci_updated_at BEFORE UPDATE ON adresse.epci FOR EACH ROW EXECUTE PROCEDURE updated_at_column();


-- Création des Triggers du schema eligibilite
CREATE TRIGGER eligibilite_actuel_updated_at BEFORE UPDATE ON eligibilite.actuel FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER eligibilite_previsionnel_updated_at BEFORE UPDATE ON eligibilite.previsionnel FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

-- Création des Triggers du schema reseau_cu
CREATE TRIGGER reseau_cu_nra_updated_at BEFORE UPDATE ON reseau_cu.nra FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cu_sr_updated_at BEFORE UPDATE ON reseau_cu.sr FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cu_pc_updated_at BEFORE UPDATE ON reseau_cu.pc FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cu_ld_updated_at BEFORE UPDATE ON reseau_cu.ld FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cu_oc_nra_updated_at BEFORE UPDATE ON reseau_cu.oc_nra FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cu_oc_pc_sans_service_updated_at BEFORE UPDATE ON reseau_cu.oc_pc_sans_service FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cu_oc_ld_sans_service_updated_at BEFORE UPDATE ON reseau_cu.oc_ld_sans_service FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

-- Création des Triggers du schema reseau_fo
CREATE TRIGGER reseau_fo_zlin_imb_updated_at BEFORE UPDATE ON reseau_fo.zlin_imb FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_fo_pm_updated_at BEFORE UPDATE ON reseau_fo.pm FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_fo_zapm_updated_at BEFORE UPDATE ON reseau_fo.zapm FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_fo_imb_updated_at BEFORE UPDATE ON reseau_fo.imb FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_fo_oc_pm_updated_at BEFORE UPDATE ON reseau_fo.oc_pm FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_fo_oc_imb_sans_service_updated_at BEFORE UPDATE ON reseau_fo.oc_imb_sans_service FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

-- Création des Triggers du schema reseau_coax
CREATE TRIGGER reseau_coax_tdr_updated_at BEFORE UPDATE ON reseau_coax.tdr FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_coax_pcc_updated_at BEFORE UPDATE ON reseau_coax.pcc FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_coax_adresse_updated_at BEFORE UPDATE ON reseau_coax.adresse FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_coax_oc_tdr_updated_at BEFORE UPDATE ON reseau_coax.oc_tdr FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_coax_oc_pcc_updated_at BEFORE UPDATE ON reseau_coax.oc_pcc FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_coax_oc_prise_sans_service_updated_at BEFORE UPDATE ON reseau_coax.oc_prise_sans_service FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

-- Création des Triggers du schema reseau_cell
CREATE TRIGGER reseau_cell_reseau_updated_at BEFORE UPDATE ON reseau_cell.reseau FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cell_site_updated_at BEFORE UPDATE ON reseau_cell.site FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cell_couverture_updated_at BEFORE UPDATE ON reseau_cell.couverture FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_cell_oc_updated_at BEFORE UPDATE ON reseau_cell.oc FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

-- Création des Triggers du schema reseau_sat
CREATE TRIGGER reseau_sat_reseau_updated_at BEFORE UPDATE ON reseau_sat.reseau FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_sat_oc_updated_at BEFORE UPDATE ON reseau_sat.oc FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

-- Création des Triggers du schema reseau_hz
CREATE TRIGGER reseau_hz_reseau_updated_at BEFORE UPDATE ON reseau_hz.reseau FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_hz_site_updated_at BEFORE UPDATE ON reseau_hz.site FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_hz_couverture_updated_at BEFORE UPDATE ON reseau_hz.couverture FOR EACH ROW EXECUTE PROCEDURE updated_at_column();
CREATE TRIGGER reseau_hz_oc_updated_at BEFORE UPDATE ON reseau_hz.oc FOR EACH ROW EXECUTE PROCEDURE updated_at_column();

CREATE SEQUENCE public.eli_cu_imb_id_seq;

COMMIT;
