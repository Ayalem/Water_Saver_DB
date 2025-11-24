-- ============================================================================
-- Database Views for Water Saver Application
-- ============================================================================
-- This script creates comprehensive views for better data access and security
-- Views provide pre-joined data and calculated fields for the application
-- ============================================================================

PROMPT ============================================================================
PROMPT Creating Database Views
PROMPT ============================================================================

-- ============================================================================
-- View 1: V_CHAMP_DETAILS
-- Complete champ information with aggregated parcelle and alerte data
-- ============================================================================
PROMPT Creating V_CHAMP_DETAILS view...

CREATE OR REPLACE VIEW V_CHAMP_DETAILS AS
SELECT 
    c.champ_id,
    c.user_id,
    c.nom AS champ_nom,
    c.superficie,
    c.type_champs,
    c.type_sol,
    c.systeme_irrigation,
    c.region,
    c.ville,
    c.adresse,
    c.code_postal,
    c.latitude,
    c.longitude,
    c.statut,
    c.date_creation,
    c.date_modification,
    u.nom AS proprietaire_nom,
    u.prenom AS proprietaire_prenom,
    u.email,
    u.telephone,
    -- Aggregated parcelle data
    COUNT(DISTINCT p.parcelle_id) AS nb_parcelles_total,
    COUNT(DISTINCT CASE WHEN p.statut = 'ACTIVE' THEN p.parcelle_id END) AS nb_parcelles_actives,
    NVL(SUM(CASE WHEN p.statut = 'ACTIVE' THEN p.superficie ELSE 0 END), 0) AS superficie_parcelles_actives,
    -- Aggregated alerte data (last 7 days)
    COUNT(DISTINCT CASE 
        WHEN a.date_detection >= SYSDATE - 7 AND a.statut = 'ACTIVE' 
        THEN a.alerte_id 
    END) AS alertes_7_derniers_jours
FROM CHAMP c
JOIN UTILISATEUR u ON c.user_id = u.user_id
LEFT JOIN PARCELLE p ON c.champ_id = p.champ_id
LEFT JOIN ALERTE a ON p.parcelle_id = a.parcelle_id
GROUP BY 
    c.champ_id, c.user_id, c.nom, c.superficie, c.type_champs, c.type_sol,
    c.systeme_irrigation, c.region, c.ville, c.adresse, c.code_postal,
    c.latitude, c.longitude, c.statut, c.date_creation, c.date_modification,
    u.nom, u.prenom, u.email, u.telephone;

-- ============================================================================
-- View 2: V_PARCELLE_DETAILS
-- Complete parcelle information with calculated fields
-- ============================================================================
PROMPT Creating V_PARCELLE_DETAILS view...

CREATE OR REPLACE VIEW V_PARCELLE_DETAILS AS
SELECT 
    p.parcelle_id,
    p.champ_id,
    p.type_culture_id,
    p.nom AS parcelle_nom,
    p.superficie,
    p.latitude,
    p.longitude,
    p.date_plantation,
    p.date_recolte_prevue,
    p.statut,
    p.date_creation,
    p.date_modification,
    -- Related data
    c.nom AS champ_nom,
    c.user_id,
    tc.nom AS type_culture_nom,
    tc.categorie AS culture_categorie,
    tc.cycle_croissance_jours,
    -- Calculated fields
    CALCULER_RENDEMENT_PREVU(p.parcelle_id) AS rendement_prevu,
    EST_RECOLTE_IMMINENTE(p.parcelle_id) AS recolte_imminente,
    -- Aggregated sensor data
    COUNT(DISTINCT cap.capteur_id) AS nb_capteurs,
    -- Aggregated alerte data
    COUNT(DISTINCT CASE WHEN a.statut = 'ACTIVE' THEN a.alerte_id END) AS nb_alertes_actives
FROM PARCELLE p
JOIN CHAMP c ON p.champ_id = c.champ_id
LEFT JOIN TYPE_CULTURE tc ON p.type_culture_id = tc.type_culture_id
LEFT JOIN CAPTEUR cap ON p.parcelle_id = cap.parcelle_id
LEFT JOIN ALERTE a ON p.parcelle_id = a.parcelle_id
GROUP BY 
    p.parcelle_id, p.champ_id, p.type_culture_id, p.nom, p.superficie,
    p.latitude, p.longitude, p.date_plantation, p.date_recolte_prevue,
    p.statut, p.date_creation, p.date_modification,
    c.nom, c.user_id, tc.nom, tc.categorie, tc.cycle_croissance_jours;

-- ============================================================================
-- View 3: V_ALERTE_DETAILS
-- Complete alerte information with related context
-- ============================================================================
PROMPT Creating V_ALERTE_DETAILS view...

CREATE OR REPLACE VIEW V_ALERTE_DETAILS AS
SELECT 
    a.alerte_id,
    a.parcelle_id,
    a.capteur_id,
    a.mesure_id,
    a.type_alerte,
    a.severite,
    a.statut,
    a.description,
    a.valeur_mesuree,
    a.valeur_seuil,
    a.pourcentage_depassement,
    a.date_detection,
    a.date_resolution,
    a.duree_minutes,
    a.resolu_par,
    a.notifie_agriculteur,
    a.notifie_technicien,
    a.date_notification_tech,
    -- Related data
    p.nom AS parcelle_nom,
    c.nom AS champ_nom,
    c.user_id AS agriculteur_id,
    u.nom || ' ' || u.prenom AS agriculteur_nom,
    cap.type_capteur,
    -- Resolution info
    tech.nom || ' ' || tech.prenom AS resolu_par_nom
FROM ALERTE a
JOIN PARCELLE p ON a.parcelle_id = p.parcelle_id
JOIN CHAMP c ON p.champ_id = c.champ_id
JOIN UTILISATEUR u ON c.user_id = u.user_id
LEFT JOIN CAPTEUR cap ON a.capteur_id = cap.capteur_id
LEFT JOIN UTILISATEUR tech ON a.resolu_par = tech.user_id;

-- ============================================================================
-- View 4: V_INTERVENTION_DETAILS
-- Complete intervention information with all related data
-- ============================================================================
PROMPT Creating V_INTERVENTION_DETAILS view...

CREATE OR REPLACE VIEW V_INTERVENTION_DETAILS AS
SELECT 
    i.intervention_id,
    i.alerte_id,
    i.parcelle_id,
    i.capteur_id,
    i.technicien_id,
    i.type_intervention,
    i.priorite,
    i.statut,
    i.description,
    i.notes,
    i.date_creation,
    i.date_assignation,
    i.date_debut,
    i.date_fin,
    i.duree_minutes,
    i.cout_intervention,
    -- Related data
    p.nom AS parcelle_nom,
    c.nom AS champ_nom,
    c.user_id AS agriculteur_id,
    u.nom || ' ' || u.prenom AS agriculteur_nom,
    tech.nom || ' ' || tech.prenom AS technicien_nom,
    tech.email AS technicien_email,
    tech.telephone AS technicien_telephone,
    a.type_alerte,
    a.severite AS alerte_severite,
    -- Calculated fields
    CASE 
        WHEN i.statut = 'TERMINE' AND i.date_fin IS NOT NULL 
        THEN ROUND((CAST(i.date_fin AS DATE) - CAST(i.date_assignation AS DATE)) * 24 * 60, 0)
        WHEN i.statut = 'EN_COURS' AND i.date_debut IS NOT NULL
        THEN ROUND((SYSDATE - CAST(i.date_assignation AS DATE)) * 24 * 60, 0)
        ELSE NULL
    END AS duree_totale_minutes
FROM INTERVENTION i
LEFT JOIN PARCELLE p ON i.parcelle_id = p.parcelle_id
LEFT JOIN CHAMP c ON p.champ_id = c.champ_id
LEFT JOIN UTILISATEUR u ON c.user_id = u.user_id
LEFT JOIN UTILISATEUR tech ON i.technicien_id = tech.user_id
LEFT JOIN ALERTE a ON i.alerte_id = a.alerte_id;

-- ============================================================================
-- View 5: V_RAPPORT_SUMMARY
-- Rapport information with summary statistics
-- ============================================================================
PROMPT Creating V_RAPPORT_SUMMARY view...

CREATE OR REPLACE VIEW V_RAPPORT_SUMMARY AS
SELECT 
    r.rapport_id,
    r.user_id,
    r.champ_id,
    r.type_rapport,
    r.date_debut,
    r.date_fin,
    r.date_generation,
    -- Related data
    c.nom AS champ_nom,
    c.superficie AS champ_superficie,
    u.nom || ' ' || u.prenom AS agriculteur_nom,
    u.email AS agriculteur_email,
    -- Period info
    ROUND(r.date_fin - r.date_debut, 0) AS periode_jours,
    -- Extract JSON statistics if available
    JSON_VALUE(r.contenu, '$.statistiques_audit.nb_parcelles') AS nb_parcelles,
    JSON_VALUE(r.contenu, '$.statistiques_audit.nb_capteurs_installes') AS nb_capteurs,
    JSON_VALUE(r.contenu, '$.statistiques_audit.nb_alertes_total') AS nb_alertes_total,
    JSON_VALUE(r.contenu, '$.statistiques_audit.nb_alertes_critiques') AS nb_alertes_critiques,
    JSON_VALUE(r.contenu, '$.statistiques_audit.nb_interventions_terminees') AS nb_interventions_terminees,
    JSON_VALUE(r.contenu, '$.statistiques_audit.duree_moyenne_resolution_min') AS duree_moy_resolution_min
FROM RAPPORT r
JOIN CHAMP c ON r.champ_id = c.champ_id
JOIN UTILISATEUR u ON r.user_id = u.user_id;

-- ============================================================================
-- View 6: V_NOTIFICATION_DETAILS
-- Notification information with context
-- ============================================================================
PROMPT Creating V_NOTIFICATION_DETAILS view...

CREATE OR REPLACE VIEW V_NOTIFICATION_DETAILS AS
SELECT 
    n.notification_id,
    n.user_id,
    n.type_notification,
    n.message,
    n.lue,
    n.date_envoi,
    n.date_lecture,
    n.alerte_id,
    n.intervention_id,
    -- Related data
    u.nom || ' ' || u.prenom AS destinataire_nom,
    u.email AS destinataire_email,
    a.type_alerte,
    a.severite AS alerte_severite,
    i.type_intervention,
    i.statut AS intervention_statut
FROM NOTIFICATION n
JOIN UTILISATEUR u ON n.user_id = u.user_id
LEFT JOIN ALERTE a ON n.alerte_id = a.alerte_id
LEFT JOIN INTERVENTION i ON n.intervention_id = i.intervention_id;

-- ============================================================================
-- View 7: V_CAPTEUR_STATUS
-- Sensor status with latest measurements
-- ============================================================================
PROMPT Creating V_CAPTEUR_STATUS view...

CREATE OR REPLACE VIEW V_CAPTEUR_STATUS AS
SELECT 
    cap.capteur_id,
    cap.parcelle_id,
    cap.type_capteur,
    cap.reference_fabricant,
    cap.date_installation,
    cap.date_derniere_maintenance,
    cap.statut,
    cap.frequence_mesure_minutes,
    -- Related data
    p.nom AS parcelle_nom,
    c.nom AS champ_nom,
    c.user_id,
    -- Latest measurement
    (SELECT m.valeur 
     FROM MESURE m 
     WHERE m.capteur_id = cap.capteur_id 
     ORDER BY m.date_mesure DESC 
     FETCH FIRST 1 ROW ONLY) AS derniere_valeur,
    (SELECT m.date_mesure 
     FROM MESURE m 
     WHERE m.capteur_id = cap.capteur_id 
     ORDER BY m.date_mesure DESC 
     FETCH FIRST 1 ROW ONLY) AS date_derniere_mesure,
    -- Status check
    CASE 
        WHEN cap.statut = 'INACTIF' THEN 'INACTIF'
        WHEN (SELECT MAX(m.date_mesure) 
              FROM MESURE m 
              WHERE m.capteur_id = cap.capteur_id) < SYSDATE - (cap.frequence_mesure_minutes / 1440 * 2)
        THEN 'ALERTE_COMMUNICATION'
        ELSE 'ACTIF'
    END AS statut_effectif
FROM CAPTEUR cap
JOIN PARCELLE p ON cap.parcelle_id = p.parcelle_id
JOIN CHAMP c ON p.champ_id = c.champ_id;

-- ============================================================================
-- View 8: V_USER_DASHBOARD
-- Dashboard summary for each user
-- ============================================================================
PROMPT Creating V_USER_DASHBOARD view...

CREATE OR REPLACE VIEW V_USER_DASHBOARD AS
SELECT 
    u.user_id,
    u.email,
    u.nom || ' ' || u.prenom AS nom_complet,
    u.role,
    -- Champs statistics
    COUNT(DISTINCT c.champ_id) AS nb_champs,
    NVL(SUM(c.superficie), 0) AS superficie_totale,
    -- Parcelles statistics
    COUNT(DISTINCT p.parcelle_id) AS nb_parcelles,
    COUNT(DISTINCT CASE WHEN p.statut = 'ACTIVE' THEN p.parcelle_id END) AS nb_parcelles_actives,
    -- Alertes statistics
    COUNT(DISTINCT CASE WHEN a.statut = 'ACTIVE' THEN a.alerte_id END) AS nb_alertes_actives,
    COUNT(DISTINCT CASE WHEN a.severite = 'CRITIQUE' AND a.statut = 'ACTIVE' THEN a.alerte_id END) AS nb_alertes_critiques,
    -- Notifications statistics
    COUNT(DISTINCT CASE WHEN n.lue = 'NON' THEN n.notification_id END) AS nb_notifications_non_lues,
    -- Interventions (for techniciens)
    COUNT(DISTINCT CASE WHEN i.technicien_id = u.user_id AND i.statut = 'ASSIGNEE' THEN i.intervention_id END) AS nb_interventions_assignees,
    COUNT(DISTINCT CASE WHEN i.technicien_id = u.user_id AND i.statut = 'EN_COURS' THEN i.intervention_id END) AS nb_interventions_en_cours
FROM UTILISATEUR u
LEFT JOIN CHAMP c ON u.user_id = c.user_id
LEFT JOIN PARCELLE p ON c.champ_id = p.champ_id
LEFT JOIN ALERTE a ON p.parcelle_id = a.parcelle_id
LEFT JOIN NOTIFICATION n ON u.user_id = n.user_id
LEFT JOIN INTERVENTION i ON (i.technicien_id = u.user_id OR c.user_id = u.user_id)
GROUP BY u.user_id, u.email, u.nom, u.prenom, u.role;

-- ============================================================================
-- Grant permissions on views
-- ============================================================================
PROMPT Granting permissions on views...

-- All users can select from these views (VPD policies will restrict rows)
GRANT SELECT ON V_CHAMP_DETAILS TO PUBLIC;
GRANT SELECT ON V_PARCELLE_DETAILS TO PUBLIC;
GRANT SELECT ON V_ALERTE_DETAILS TO PUBLIC;
GRANT SELECT ON V_INTERVENTION_DETAILS TO PUBLIC;
GRANT SELECT ON V_RAPPORT_SUMMARY TO PUBLIC;
GRANT SELECT ON V_NOTIFICATION_DETAILS TO PUBLIC;
GRANT SELECT ON V_CAPTEUR_STATUS TO PUBLIC;
GRANT SELECT ON V_USER_DASHBOARD TO PUBLIC;

-- ============================================================================
-- Verify view creation
-- ============================================================================
PROMPT
PROMPT Verifying view creation...

SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_type = 'VIEW'
AND object_name LIKE 'V_%'
ORDER BY object_name;

PROMPT
PROMPT ============================================================================
PROMPT Views Created Successfully!
PROMPT ============================================================================
PROMPT
PROMPT Available views:
PROMPT - V_CHAMP_DETAILS: Complete champ information with aggregations
PROMPT - V_PARCELLE_DETAILS: Parcelle details with calculated fields
PROMPT - V_ALERTE_DETAILS: Alerte information with context
PROMPT - V_INTERVENTION_DETAILS: Complete intervention tracking
PROMPT - V_RAPPORT_SUMMARY: Rapport summaries with statistics
PROMPT - V_NOTIFICATION_DETAILS: Notification details
PROMPT - V_CAPTEUR_STATUS: Sensor status and latest measurements
PROMPT - V_USER_DASHBOARD: User dashboard summary
PROMPT ============================================================================
