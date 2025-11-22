

-- ============================================
-- 1. UTILISATEUR (Authentification multi-rôles)
-- ============================================
CREATE TABLE UTILISATEUR (
  user_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  login VARCHAR2(50) UNIQUE NOT NULL,
  password_hash VARCHAR2(64) NOT NULL,
  nom VARCHAR2(100) NOT NULL,
  prenom VARCHAR2(100) NOT NULL,
  email VARCHAR2(100) UNIQUE NOT NULL,
  telephone VARCHAR2(20),
  role VARCHAR2(20) NOT NULL CHECK (role IN ('AGRICULTEUR', 'TECHNICIEN', 'INSPECTEUR', 'ADMIN')),
  statut VARCHAR2(10) DEFAULT 'ACTIF' CHECK (statut IN ('ACTIF', 'INACTIF', 'BLOQUE')),
  region_affectation VARCHAR2(50),
  tentatives_echec NUMBER DEFAULT 0,
  date_derniere_connexion TIMESTAMP,
  date_creation TIMESTAMP DEFAULT SYSDATE,
  date_modification TIMESTAMP
);

-- ============================================
-- 2. CHAMP (Grande zone de culture)
-- ============================================
CREATE TABLE CHAMP (
  champ_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id NUMBER NOT NULL REFERENCES UTILISATEUR(user_id),
  nom VARCHAR2(100) NOT NULL,
  superficie NUMBER(10,2) NOT NULL,
  type_champs VARCHAR2(50), -- 'Maraîchage', 'Céréales', 'Arboriculture'
  type_sol VARCHAR2(50), -- 'Argileux', 'Sableux', 'Limoneux'
  systeme_irrigation VARCHAR2(50), -- 'Goutte-à-goutte', 'Aspersion', 'Gravitaire'
  adresse VARCHAR2(200),
  region VARCHAR2(50),
  ville VARCHAR2(50),
  code_postal VARCHAR2(10),
  latitude NUMBER(10,7),
  longitude NUMBER(10,7),
  date_plantation DATE,
  statut VARCHAR2(20) DEFAULT 'ACTIF' CHECK (statut IN ('ACTIF', 'INACTIF', 'EN_REPOS')),
  date_creation TIMESTAMP DEFAULT SYSDATE,
  date_modification TIMESTAMP
);

COMMENT ON TABLE CHAMP IS 'Zone de culture principale appartenant à un agriculteur';

-- ============================================
-- 3. TYPE_CULTURE (Types de cultures possibles)
-- ============================================
CREATE TABLE TYPE_CULTURE (
  type_culture_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom VARCHAR2(50) UNIQUE NOT NULL, -- 'Tomates', 'Blé', 'Oranges', 'Carottes', etc.
  categorie VARCHAR2(50), -- 'Légumes', 'Céréales', 'Fruits', 'Tubercules'
  cycle_croissance_jours NUMBER, -- Durée moyenne du cycle
  coefficient_cultural_kc NUMBER(3,2), -- Coefficient pour calcul besoins en eau
  description VARCHAR2(500),
  date_creation TIMESTAMP DEFAULT SYSDATE
);

COMMENT ON TABLE TYPE_CULTURE IS 'Référentiel des types de cultures avec leurs caractéristiques';

-- ============================================
-- 4. PARCELLE (Sous-division avec capteurs)
-- ============================================
CREATE TABLE PARCELLE (
  parcelle_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  champ_id NUMBER NOT NULL REFERENCES CHAMP(champ_id) ,
  type_culture_id NUMBER REFERENCES TYPE_CULTURE(type_culture_id),
  nom VARCHAR2(100) NOT NULL,
  superficie NUMBER(10,2) NOT NULL,
  latitude NUMBER(10,7),
  longitude NUMBER(10,7),
  date_plantation DATE,
  date_recolte_prevue DATE,
  statut VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (statut IN ('ACTIVE', 'INACTIVE', 'EN_REPOS')),
  date_creation TIMESTAMP DEFAULT SYSDATE,
  date_modification TIMESTAMP
);

COMMENT ON TABLE PARCELLE IS 'Subdivision d''un champ équipée de capteurs IoT avec une culture spécifique';

-- ============================================
-- 5. SEUIL_CULTURE (Seuils par type de culture)
-- ============================================
CREATE TABLE SEUIL_CULTURE (
  seuil_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  type_culture_id NUMBER NOT NULL REFERENCES TYPE_CULTURE(type_culture_id),
  type_seuil VARCHAR2(50) NOT NULL, -- 'HUMIDITE', 'TEMPERATURE', 'DEBIT', 'PRESSION'
  seuil_min NUMBER(10,2) NOT NULL,
  seuil_max NUMBER(10,2) NOT NULL,
  unite_mesure VARCHAR2(10), -- '°C', 'L/h', 'Bar', '%'
  tolerance_pourcentage NUMBER(5,2) DEFAULT 5, -- Marge d'erreur avant alerte
  stade_croissance VARCHAR2(50), -- 'SEMIS', 'CROISSANCE', 'FLORAISON', 'MATURATION'
  date_application TIMESTAMP DEFAULT SYSDATE,
  date_modification TIMESTAMP,
  UNIQUE(type_culture_id, type_seuil, stade_croissance)
);

COMMENT ON TABLE SEUIL_CULTURE IS 'Seuils de mesures recommandés par type de culture et stade de croissance';

-- ============================================
-- 6. CAPTEUR (Appareil IoT)
-- ============================================
CREATE TABLE CAPTEUR (
  capteur_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parcelle_id NUMBER NOT NULL REFERENCES PARCELLE(parcelle_id) ,
  numero_serie VARCHAR2(50) UNIQUE NOT NULL,
  modele VARCHAR2(50),
  type_capteur VARCHAR2(50) NOT NULL, -- 'Débit', 'Pression', 'Humidité', 'Météo'
  statut VARCHAR2(20) DEFAULT 'ACTIF' CHECK (statut IN ('ACTIF', 'INACTIF', 'EN_PANNE', 'MAINTENANCE')),
  niveau_batterie NUMBER(3) CHECK (niveau_batterie BETWEEN 0 AND 100),
  frequence_mesure NUMBER DEFAULT 15, -- Minutes
  date_installation DATE,
  date_derniere_mesure TIMESTAMP,
  date_derniere_maintenance TIMESTAMP,
  date_creation TIMESTAMP DEFAULT SYSDATE
);

COMMENT ON TABLE CAPTEUR IS 'Capteurs IoT installés sur les parcelles pour la collecte de données';

-- ============================================
-- 7. MESURE (Données temps réel)
-- ============================================
CREATE TABLE MESURE (
  mesure_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  capteur_id NUMBER NOT NULL REFERENCES CAPTEUR(capteur_id) ,
  date_mesure TIMESTAMP DEFAULT SYSDATE NOT NULL,
  type_mesure VARCHAR2(50), -- 'DEBIT', 'PRESSION', 'HUMIDITE', 'TEMPERATURE'
  valeur_mesure NUMBER(10,2),
  unite_mesure VARCHAR2(10), -- °C, L/h, Bar, %
  qualite_signal NUMBER(3) CHECK (qualite_signal BETWEEN 0 AND 100),
  anomalie_detectee VARCHAR2(3) DEFAULT 'NON' CHECK (anomalie_detectee IN ('OUI', 'NON')),
  date_creation TIMESTAMP DEFAULT SYSDATE
);

COMMENT ON TABLE MESURE IS 'Données collectées en temps réel par les capteurs';

-- ============================================
-- 8. ALERTE (Alertes générées automatiquement)
-- ============================================
CREATE TABLE ALERTE (
  alerte_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  mesure_id NUMBER REFERENCES MESURE(mesure_id) ,
  parcelle_id NUMBER NOT NULL REFERENCES PARCELLE(parcelle_id) ,
  type_alerte VARCHAR2(50) NOT NULL CHECK (type_alerte IN (
    'DEPASSEMENT_DEBIT', 
    'DEPASSEMENT_PRESSION', 
    'HUMIDITE_BASSE', 
    'HUMIDITE_HAUTE',
    'FUITE', 
    'CAPTEUR_DEFAILLANT',
    'BATTERIE_FAIBLE',
    'SURCONSOMMATION'
  )),
  severite VARCHAR2(20) NOT NULL CHECK (severite IN ('INFO', 'ATTENTION', 'HAUTE', 'CRITIQUE')),
  description VARCHAR2(500),
  valeur_mesuree NUMBER(10,2),
  valeur_seuil NUMBER(10,2),
  pourcentage_depassement NUMBER(5,2),
  date_detection TIMESTAMP DEFAULT SYSDATE NOT NULL,
  date_resolution TIMESTAMP,
  duree_minutes NUMBER, -- Durée de l'alerte
  statut VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (statut IN ('ACTIVE', 'EN_COURS', 'RESOLUE', 'IGNOREE')),
  resolu_par NUMBER REFERENCES UTILISATEUR(user_id),
  notifie_agriculteur VARCHAR2(3) DEFAULT 'NON' CHECK (notifie_agriculteur IN ('OUI', 'NON')),
  notifie_technicien VARCHAR2(3) DEFAULT 'NON' CHECK (notifie_technicien IN ('OUI', 'NON')),
  date_notification_tech TIMESTAMP
);

COMMENT ON TABLE ALERTE IS 'Alertes générées automatiquement lors de dépassement de seuils';

-- ============================================
-- 9. INTERVENTION (Travaux techniques)
-- ============================================
CREATE TABLE INTERVENTION (
  intervention_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  alerte_id NUMBER REFERENCES ALERTE(alerte_id) ,
  parcelle_id NUMBER NOT NULL REFERENCES PARCELLE(parcelle_id) ,
  capteur_id NUMBER REFERENCES CAPTEUR(capteur_id),
  technicien_id NUMBER REFERENCES UTILISATEUR(user_id),
  type_intervention VARCHAR2(50) NOT NULL CHECK (type_intervention IN (
    'REPARATION_FUITE', 
    'MAINTENANCE_CAPTEUR', 
    'REMPLACEMENT_PIECE', 
    'REMPLACEMENT_CAPTEUR',
    'CALIBRATION', 
    'INSPECTION',
    'REMPLACEMENT_BATTERIE',
    'AUTRE'
  )),
  priorite VARCHAR2(20) NOT NULL CHECK (priorite IN ('BASSE', 'MOYENNE', 'HAUTE', 'URGENTE')),
  statut VARCHAR2(20) DEFAULT 'EN_ATTENTE' CHECK (statut IN ('EN_ATTENTE', 'ASSIGNEE', 'EN_COURS', 'TERMINE', 'ANNULEE')),
  description VARCHAR2(500),
  date_creation TIMESTAMP DEFAULT SYSDATE,
  date_assignation TIMESTAMP,
  date_debut TIMESTAMP,
  date_fin TIMESTAMP,
  duree_minutes NUMBER,
  cout_intervention NUMBER(10,2),
  notes CLOB,
  signature_technicien BLOB
);

COMMENT ON TABLE INTERVENTION IS 'Interventions techniques planifiées ou en réponse aux alertes';

-- ============================================
-- 10. RAPPORT (Rapports générés)
-- ============================================
CREATE TABLE RAPPORT (
  rapport_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id NUMBER NOT NULL REFERENCES UTILISATEUR(user_id) ,
  champ_id NUMBER REFERENCES CHAMP(champ_id) ,
  type_rapport VARCHAR2(50),
  date_debut DATE,
  date_fin DATE,
  contenu CLOB,
  date_generation TIMESTAMP DEFAULT SYSDATE
);

COMMENT ON TABLE RAPPORT IS 'Rapports générés pour analyse des données';

-- ============================================
-- 11. NOTIFICATION (Système de notifications)
-- ============================================
CREATE TABLE NOTIFICATION (
  notification_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id NUMBER NOT NULL REFERENCES UTILISATEUR(user_id) ,
  alerte_id NUMBER REFERENCES ALERTE(alerte_id) ,
  intervention_id NUMBER REFERENCES INTERVENTION(intervention_id) ,
  type_notification VARCHAR2(50) NOT NULL CHECK (type_notification IN (
    'ALERTE_DEPASSEMENT',
    'ALERTE_FUITE',
    'INTERVENTION_ASSIGNEE',
    'INTERVENTION_TERMINEE',
    'RAPPORT_DISPONIBLE',
    'BATTERIE_FAIBLE',
    'CAPTEUR_DEFAILLANT',
    'SYSTEME'
  )),
  message VARCHAR2(1000) NOT NULL,
  lue VARCHAR2(3) DEFAULT 'NON' CHECK (lue IN ('OUI', 'NON')),
  date_envoi TIMESTAMP DEFAULT SYSDATE,
  date_lecture TIMESTAMP
);



ALTER TABLE PARCELLE
ADD statut VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (statut IN ('ACTIVE', 'INACTIVE', 'EN_REPOS'));


ALTER TABLE UTILISATEUR
DROP COLUMN login;




