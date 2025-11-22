CREATE OR REPLACE FUNCTION CREATE_PARCELLE(
    p_champ_id IN NUMBER,
    p_type_culture_id IN NUMBER DEFAULT NULL,
    p_nom IN VARCHAR2,
    p_superficie IN NUMBER,
    p_latitude IN NUMBER DEFAULT NULL,
    p_longitude IN NUMBER DEFAULT NULL,
    p_date_plantation IN DATE DEFAULT NULL,
    p_date_recolte_prevue IN DATE DEFAULT NULL
) RETURN NUMBER
IS
    v_parcelle_id NUMBER;
    v_superficie_champ NUMBER;
    v_superficie_occupee NUMBER;
BEGIN
    -- Vérifier si le champ existe et est actif
    SELECT superficie
    INTO v_superficie_champ
    FROM CHAMP
    WHERE champ_id = p_champ_id
      AND statut = 'ACTIF';
      
    -- Vérifier la superficie réelle déjà occupée
    v_superficie_occupee := SUPERFICIE_REELLE_CHAMP(p_champ_id);
    
    IF (v_superficie_occupee + p_superficie) > v_superficie_champ THEN
        RAISE_APPLICATION_ERROR(-20004, 'Superficie totale des parcelles dépasse celle du champ');
    END IF;
    
    -- Insérer la nouvelle parcelle
    INSERT INTO PARCELLE (
        champ_id, type_culture_id, nom, superficie, latitude, longitude,
        date_plantation, date_recolte_prevue
    ) VALUES (
        p_champ_id, p_type_culture_id, p_nom, p_superficie, p_latitude, p_longitude,
        p_date_plantation, p_date_recolte_prevue
    )
    RETURNING parcelle_id INTO v_parcelle_id;
    
    COMMIT;
    RETURN v_parcelle_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Champ non trouvé ou inactif');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CREATE_PARCELLE;
/
