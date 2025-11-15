CREATE OR REPLACE PROCEDURE PRC_NOTIFIER_TECHNICIEN_MANUEL (
    p_alerte_id         IN NUMBER, -- L'ID de l'alerte à notifier (ALERTE.alerte_id)
    p_technicien_id     IN NUMBER, -- L'ID de l'utilisateur à notifier (UTILISATEUR.user_id)
    p_admin_id          IN NUMBER  -- L'ID de l'administrateur (pour l'audit/traçabilité)
)
IS
    -- Les variables sont typées sur les colonnes pour garantir la compatibilité
    v_role_technicien      UTILISATEUR.role%TYPE;
    v_message_notification NOTIFICATION.message%TYPE;
    v_nom_champ            CHAMP.nom%TYPE;
BEGIN
    -- 1. VÉRIFICATION DU RÔLE DE L'UTILISATEUR (Doit être 'TECHNICIEN')
    SELECT role 
    INTO v_role_technicien
    FROM UTILISATEUR
    WHERE user_id = p_technicien_id;
    
    -- Récupération du nom du champ pour inclure dans la notification
    SELECT C.nom 
    INTO v_nom_champ
    FROM ALERTE A
    JOIN PARCELLE P ON P.parcelle_id = A.parcelle_id -- Utilise ALERTE.parcelle_id et PARCELLE.parcelle_id
    JOIN CHAMP C ON C.champ_id = P.champ_id         -- Utilise PARCELLE.champ_id et CHAMP.champ_id
    WHERE A.alerte_id = p_alerte_id; 

    -- Si le rôle n'est pas Technicien, on lève une erreur
    IF v_role_technicien != 'TECHNICIEN' THEN
        RAISE_APPLICATION_ERROR(-20020, 'Erreur : L''ID ' || p_technicien_id || ' n''a pas le rôle de TECHNICIEN. Assignation refusée.');
    END IF;

    -- 2. ENVOI DE L'ORDRE DE TRAVAIL (Insertion dans NOTIFICATION)
    v_message_notification := 'Alerte urgente #' || p_alerte_id || ' assignée manuellement pour le Champ : ' || v_nom_champ || '. Veuillez créer une intervention.';

    INSERT INTO NOTIFICATION (
        user_id, 
        alerte_id, 
        type_notification, 
        message, 
        date_envoi -- Colomnes de NOTIFICATION respectées
    )
    VALUES (
        p_technicien_id,
        p_alerte_id,
        'INTERVENTION_ASSIGNEE',
        v_message_notification,
        SYSTIMESTAMP
    );

    -- 3. MISE À JOUR DE L'ALERTE (Traçabilité)
    -- L'alerte passe de 'ACTIVE' à 'EN_COURS' et on trace la notification
    UPDATE ALERTE
    SET statut = 'EN_COURS',
        notifie_technicien = 'OUI', -- Colonne ALERTE.notifie_technicien
        date_notification_tech = SYSTIMESTAMP -- Colonne ALERTE.date_notification_tech
    WHERE alerte_id = p_alerte_id
      AND statut = 'ACTIVE'; -- Condition de mise à jour pour l'alerte
      
    COMMIT; -- Valide toutes les modifications

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Si l'alerte ou le technicien n'existe pas
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20021, 'Erreur : L''alerte ou le technicien spécifié n''existe pas.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20022, 'Erreur inattendue lors de la notification manuelle: ' || SQLERRM);
END PRC_NOTIFIER_TECHNICIEN_MANUEL;
/
