CREATE OR REPLACE FUNCTION LISTER_CHAMPS_UTILISATEUR(
    p_user_id IN NUMBER,
    p_statut IN VARCHAR2 DEFAULT NULL
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
        c.region,
        c.ville,
        c.statut,
        c.date_creation,
        -- Statistiques
        (SELECT COUNT(*) FROM PARCELLE p WHERE p.champ_id = c.champ_id AND p.statut = 'ACTIVE') as nb_parcelles_actives,
        (SELECT COUNT(*) FROM CAPTEUR cap 
         JOIN PARCELLE p ON cap.parcelle_id = p.parcelle_id 
         WHERE p.champ_id = c.champ_id AND cap.statut = 'ACTIF') as nb_capteurs_actifs,
        (SELECT COUNT(*) FROM ALERTE a 
         JOIN PARCELLE p ON a.parcelle_id = p.parcelle_id 
         WHERE p.champ_id = c.champ_id 
         AND a.statut = 'ACTIVE') as alertes_actives,
        -- Dernière modification
        c.date_modification
    FROM CHAMP c
    WHERE c.user_id = p_user_id
    AND (p_statut IS NULL OR c.statut = p_statut)
    ORDER BY c.date_creation DESC, c.nom;
    
    RETURN v_cursor;
END LISTER_CHAMPS_UTILISATEUR;
