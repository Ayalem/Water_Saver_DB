CREATE OR REPLACE FUNCTION AFFICHER_DETAILS_CHAMP(
    p_champ_id IN NUMBER
) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    SELECT 
        c.champ_id,
        c.nom as nom_champ,
        c.superficie,
        c.type_champs,
        c.type_sol,
        c.systeme_irrigation,
        c.adresse,
        c.region,
        c.ville,
        c.code_postal,
        c.latitude,
        c.longitude,
        c.date_plantation,
        c.statut,
        c.date_creation,
        c.date_modification,
        -- Informations propriétaire
        u.user_id,
        u.nom as proprietaire_nom,
        u.prenom as proprietaire_prenom,
        u.email,
        u.telephone,
        -- Statistiques parcelles
        (SELECT COUNT(*) FROM PARCELLE p WHERE p.champ_id = c.champ_id AND p.statut = 'ACTIVE') as nb_parcelles_actives,
        (SELECT COUNT(*) FROM PARCELLE p WHERE p.champ_id = c.champ_id) as nb_parcelles_total,
        (SELECT SUM(superficie) FROM PARCELLE p WHERE p.champ_id = c.champ_id AND p.statut = 'ACTIVE') as superficie_parcelles_actives,
        -- Alertes récentes
        (SELECT COUNT(*) FROM ALERTE a 
         JOIN PARCELLE p ON a.parcelle_id = p.parcelle_id 
         WHERE p.champ_id = c.champ_id 
         AND a.date_detection >= SYSDATE - 7) as alertes_7_derniers_jours
    FROM CHAMP c
    JOIN UTILISATEUR u ON c.user_id = u.user_id
    WHERE c.champ_id = p_champ_id;
    
    RETURN v_cursor;
END AFFICHER_DETAILS_CHAMP;
