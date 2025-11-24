-- ============================================================================
-- Stored Procedures for Role-Based Data Access
-- ============================================================================
-- These procedures provide role-based access to data
-- They are referenced in roles.sql and used by the application
-- ============================================================================

PROMPT ============================================================================
PROMPT Creating Role-Based Access Procedures
PROMPT ============================================================================

-- ============================================================================
-- Procedure: voir_notification
-- View notifications for a specific user
-- ============================================================================
PROMPT Creating voir_notification procedure...

CREATE OR REPLACE PROCEDURE voir_notification(
    p_user_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        n.notification_id,
        n.type_notification,
        n.message,
        n.lue,
        n.date_envoi,
        n.date_lecture,
        n.alerte_id,
        n.intervention_id
    FROM NOTIFICATION n
    WHERE n.user_id = p_user_id
    ORDER BY n.date_envoi DESC;
END voir_notification;
/

-- ============================================================================
-- Procedure: voir_notifications (plural - same as singular)
-- View notifications for a specific user
-- ============================================================================
PROMPT Creating voir_notifications procedure...

CREATE OR REPLACE PROCEDURE voir_notifications(
    p_user_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        n.notification_id,
        n.type_notification,
        n.message,
        n.lue,
        n.date_envoi,
        n.date_lecture,
        n.alerte_id,
        n.intervention_id
    FROM NOTIFICATION n
    WHERE n.user_id = p_user_id
    ORDER BY n.date_envoi DESC;
END voir_notifications;
/

-- ============================================================================
-- Procedure: voir_alertes_agriculteur
-- View alertes for an agriculteur's parcelles
-- ============================================================================
PROMPT Creating voir_alertes_agriculteur procedure...

CREATE OR REPLACE PROCEDURE voir_alertes_agriculteur(
    p_user_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        a.alerte_id,
        a.parcelle_id,
        a.type_alerte,
        a.severite,
        a.statut,
        a.description,
        a.valeur_mesuree,
        a.valeur_seuil,
        a.date_detection,
        a.date_resolution,
        p.nom AS parcelle_nom,
        c.nom AS champ_nom
    FROM ALERTE a
    JOIN PARCELLE p ON a.parcelle_id = p.parcelle_id
    JOIN CHAMP c ON p.champ_id = c.champ_id
    WHERE c.user_id = p_user_id
    ORDER BY a.date_detection DESC;
END voir_alertes_agriculteur;
/

-- ============================================================================
-- Procedure: voir_interventions
-- View interventions based on user role
-- For AGRICULTEUR: interventions on their parcelles
-- For TECHNICIEN: interventions assigned to them
-- ============================================================================
PROMPT Creating voir_interventions procedure...

CREATE OR REPLACE PROCEDURE voir_interventions(
    p_user_id IN NUMBER,
    p_user_role IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    IF p_user_role = 'AGRICULTEUR' THEN
        -- Interventions on agriculteur's parcelles
        OPEN p_cursor FOR
        SELECT 
            i.intervention_id,
            i.alerte_id,
            i.parcelle_id,
            i.type_intervention,
            i.priorite,
            i.statut,
            i.description,
            i.date_creation,
            i.date_assignation,
            i.date_debut,
            i.date_fin,
            p.nom AS parcelle_nom,
            c.nom AS champ_nom,
            u.nom || ' ' || u.prenom AS technicien_nom
        FROM INTERVENTION i
        JOIN PARCELLE p ON i.parcelle_id = p.parcelle_id
        JOIN CHAMP c ON p.champ_id = c.champ_id
        LEFT JOIN UTILISATEUR u ON i.technicien_id = u.user_id
        WHERE c.user_id = p_user_id
        ORDER BY i.date_creation DESC;
        
    ELSIF p_user_role = 'TECHNICIEN' THEN
        -- Interventions assigned to technicien
        OPEN p_cursor FOR
        SELECT 
            i.intervention_id,
            i.alerte_id,
            i.parcelle_id,
            i.type_intervention,
            i.priorite,
            i.statut,
            i.description,
            i.date_creation,
            i.date_assignation,
            i.date_debut,
            i.date_fin,
            p.nom AS parcelle_nom,
            c.nom AS champ_nom,
            ag.nom || ' ' || ag.prenom AS agriculteur_nom
        FROM INTERVENTION i
        LEFT JOIN PARCELLE p ON i.parcelle_id = p.parcelle_id
        LEFT JOIN CHAMP c ON p.champ_id = c.champ_id
        LEFT JOIN UTILISATEUR ag ON c.user_id = ag.user_id
        WHERE i.technicien_id = p_user_id
        ORDER BY i.date_creation DESC;
        
    ELSE
        -- ADMIN or INSPECTEUR: all interventions
        OPEN p_cursor FOR
        SELECT 
            i.intervention_id,
            i.alerte_id,
            i.parcelle_id,
            i.type_intervention,
            i.priorite,
            i.statut,
            i.description,
            i.date_creation,
            i.date_assignation,
            i.date_debut,
            i.date_fin,
            p.nom AS parcelle_nom,
            c.nom AS champ_nom,
            u.nom || ' ' || u.prenom AS technicien_nom,
            ag.nom || ' ' || ag.prenom AS agriculteur_nom
        FROM INTERVENTION i
        LEFT JOIN PARCELLE p ON i.parcelle_id = p.parcelle_id
        LEFT JOIN CHAMP c ON p.champ_id = c.champ_id
        LEFT JOIN UTILISATEUR u ON i.technicien_id = u.user_id
        LEFT JOIN UTILISATEUR ag ON c.user_id = ag.user_id
        ORDER BY i.date_creation DESC;
    END IF;
END voir_interventions;
/

-- ============================================================================
-- Procedure: ajouter_parcelle
-- Add a new parcelle (for AGRICULTEUR)
-- ============================================================================
PROMPT Creating ajouter_parcelle procedure...

CREATE OR REPLACE PROCEDURE ajouter_parcelle(
    p_champ_id IN NUMBER,
    p_nom IN VARCHAR2,
    p_superficie IN NUMBER,
    p_type_culture_id IN NUMBER DEFAULT NULL,
    p_user_id IN NUMBER,
    p_parcelle_id OUT NUMBER
) AS
    v_champ_owner NUMBER;
BEGIN
    -- Verify user owns the champ
    SELECT user_id INTO v_champ_owner
    FROM CHAMP
    WHERE champ_id = p_champ_id;
    
    IF v_champ_owner != p_user_id THEN
        RAISE_APPLICATION_ERROR(-20001, 'Vous ne pouvez pas ajouter une parcelle à ce champ');
    END IF;
    
    -- Insert parcelle
    INSERT INTO PARCELLE (
        champ_id, type_culture_id, nom, superficie, statut, date_creation
    ) VALUES (
        p_champ_id, p_type_culture_id, p_nom, p_superficie, 'ACTIVE', SYSDATE
    ) RETURNING parcelle_id INTO p_parcelle_id;
    
    COMMIT;
END ajouter_parcelle;
/

-- ============================================================================
-- Procedure: modifier_parcelle
-- Modify an existing parcelle (for AGRICULTEUR)
-- ============================================================================
PROMPT Creating modifier_parcelle procedure...

CREATE OR REPLACE PROCEDURE modifier_parcelle(
    p_parcelle_id IN NUMBER,
    p_nom IN VARCHAR2 DEFAULT NULL,
    p_superficie IN NUMBER DEFAULT NULL,
    p_type_culture_id IN NUMBER DEFAULT NULL,
    p_user_id IN NUMBER
) AS
    v_champ_owner NUMBER;
BEGIN
    -- Verify user owns the champ
    SELECT c.user_id INTO v_champ_owner
    FROM PARCELLE p
    JOIN CHAMP c ON p.champ_id = c.champ_id
    WHERE p.parcelle_id = p_parcelle_id;
    
    IF v_champ_owner != p_user_id THEN
        RAISE_APPLICATION_ERROR(-20002, 'Vous ne pouvez pas modifier cette parcelle');
    END IF;
    
    -- Update parcelle
    UPDATE PARCELLE
    SET nom = NVL(p_nom, nom),
        superficie = NVL(p_superficie, superficie),
        type_culture_id = NVL(p_type_culture_id, type_culture_id),
        date_modification = SYSDATE
    WHERE parcelle_id = p_parcelle_id;
    
    COMMIT;
END modifier_parcelle;
/

-- ============================================================================
-- Procedure: desactiver_parcelle
-- Deactivate a parcelle (for AGRICULTEUR)
-- ============================================================================
PROMPT Creating desactiver_parcelle procedure...

CREATE OR REPLACE PROCEDURE desactiver_parcelle(
    p_parcelle_id IN NUMBER,
    p_user_id IN NUMBER
) AS
    v_champ_owner NUMBER;
BEGIN
    -- Verify user owns the champ
    SELECT c.user_id INTO v_champ_owner
    FROM PARCELLE p
    JOIN CHAMP c ON p.champ_id = c.champ_id
    WHERE p.parcelle_id = p_parcelle_id;
    
    IF v_champ_owner != p_user_id THEN
        RAISE_APPLICATION_ERROR(-20003, 'Vous ne pouvez pas désactiver cette parcelle');
    END IF;
    
    -- Deactivate parcelle
    UPDATE PARCELLE
    SET statut = 'INACTIVE',
        date_modification = SYSDATE
    WHERE parcelle_id = p_parcelle_id;
    
    COMMIT;
END desactiver_parcelle;
/

-- ============================================================================
-- Procedure: ajouter_type_culture
-- Add a new type de culture (for AGRICULTEUR and ADMIN)
-- ============================================================================
PROMPT Creating ajouter_type_culture procedure...

CREATE OR REPLACE PROCEDURE ajouter_type_culture(
    p_nom IN VARCHAR2,
    p_categorie IN VARCHAR2,
    p_cycle_croissance_jours IN NUMBER,
    p_coefficient_kc IN NUMBER DEFAULT NULL,
    p_description IN VARCHAR2 DEFAULT NULL,
    p_type_culture_id OUT NUMBER
) AS
BEGIN
    INSERT INTO TYPE_CULTURE (
        nom, categorie, cycle_croissance_jours, 
        coefficient_cultural_kc, description, date_creation
    ) VALUES (
        p_nom, p_categorie, p_cycle_croissance_jours,
        p_coefficient_kc, p_description, SYSDATE
    ) RETURNING type_culture_id INTO p_type_culture_id;
    
    COMMIT;
END ajouter_type_culture;
/

-- ============================================================================
-- Procedure: update_intervention_technicien
-- Update intervention status (for TECHNICIEN)
-- ============================================================================
PROMPT Creating update_intervention_technicien procedure...

CREATE OR REPLACE PROCEDURE update_intervention_technicien(
    p_intervention_id IN NUMBER,
    p_technicien_id IN NUMBER,
    p_statut IN VARCHAR2,
    p_notes IN VARCHAR2 DEFAULT NULL
) AS
    v_assigned_tech NUMBER;
BEGIN
    -- Verify intervention is assigned to this technicien
    SELECT technicien_id INTO v_assigned_tech
    FROM INTERVENTION
    WHERE intervention_id = p_intervention_id;
    
    IF v_assigned_tech != p_technicien_id THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cette intervention ne vous est pas assignée');
    END IF;
    
    -- Update intervention
    UPDATE INTERVENTION
    SET statut = p_statut,
        notes = NVL(p_notes, notes),
        date_debut = CASE WHEN p_statut = 'EN_COURS' AND date_debut IS NULL THEN SYSTIMESTAMP ELSE date_debut END,
        date_fin = CASE WHEN p_statut = 'TERMINE' THEN SYSTIMESTAMP ELSE date_fin END
    WHERE intervention_id = p_intervention_id;
    
    COMMIT;
END update_intervention_technicien;
/

-- ============================================================================
-- Verify procedure creation
-- ============================================================================
PROMPT
PROMPT Verifying procedure creation...

SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_type = 'PROCEDURE'
AND object_name IN (
    'VOIR_NOTIFICATION',
    'VOIR_NOTIFICATIONS',
    'VOIR_ALERTES_AGRICULTEUR',
    'VOIR_INTERVENTIONS',
    'AJOUTER_PARCELLE',
    'MODIFIER_PARCELLE',
    'DESACTIVER_PARCELLE',
    'AJOUTER_TYPE_CULTURE',
    'UPDATE_INTERVENTION_TECHNICIEN'
)
ORDER BY object_name;

PROMPT
PROMPT Checking for errors...

SELECT name, type, line, position, text
FROM USER_ERRORS
WHERE name IN (
    'VOIR_NOTIFICATION',
    'VOIR_NOTIFICATIONS',
    'VOIR_ALERTES_AGRICULTEUR',
    'VOIR_INTERVENTIONS',
    'AJOUTER_PARCELLE',
    'MODIFIER_PARCELLE',
    'DESACTIVER_PARCELLE',
    'AJOUTER_TYPE_CULTURE',
    'UPDATE_INTERVENTION_TECHNICIEN'
)
ORDER BY name, sequence;

PROMPT
PROMPT ============================================================================
PROMPT Role-Based Access Procedures Created Successfully!
PROMPT ============================================================================
PROMPT
PROMPT Available procedures:
PROMPT - voir_notification: View notifications for a user
PROMPT - voir_notifications: View notifications (plural)
PROMPT - voir_alertes_agriculteur: View alertes for agriculteur
PROMPT - voir_interventions: View interventions based on role
PROMPT - ajouter_parcelle: Add a new parcelle
PROMPT - modifier_parcelle: Modify a parcelle
PROMPT - desactiver_parcelle: Deactivate a parcelle
PROMPT - ajouter_type_culture: Add a new type de culture
PROMPT - update_intervention_technicien: Update intervention status
PROMPT ============================================================================
