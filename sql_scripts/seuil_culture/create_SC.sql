CREATE OR REPLACE FUNCTION CREATE_SEUIL_CULTURE(
    p_type_culture_id IN NUMBER,
    p_type_seuil IN VARCHAR2,
    p_seuil_min IN NUMBER,
    p_seuil_max IN NUMBER,
    p_unite_mesure IN VARCHAR2 DEFAULT NULL,
    p_tolerance_pourcentage IN NUMBER DEFAULT 5,
    p_stade_croissance IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER
IS
    v_seuil_id NUMBER;
    v_type_culture_exists NUMBER;
BEGIN
    -- Vérifier si le type de culture existe
    SELECT COUNT(*) INTO v_type_culture_exists
    FROM TYPE_CULTURE
    WHERE type_culture_id = p_type_culture_id;
    
    IF v_type_culture_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20009, 'Type de culture non trouvé');
    END IF;
    
    -- Vérifier l'unicité du seuil pour ce type de culture et stade
    DECLARE
        v_seuil_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_seuil_exists
        FROM SEUIL_CULTURE
        WHERE type_culture_id = p_type_culture_id
        AND type_seuil = p_type_seuil
        AND (stade_croissance = p_stade_croissance OR (stade_croissance IS NULL AND p_stade_croissance IS NULL));
        
        IF v_seuil_exists > 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Seuil déjà défini pour ce type de culture et stade');
        END IF;
    END;
    
    -- Insérer le nouveau seuil
    INSERT INTO SEUIL_CULTURE (
        type_culture_id, type_seuil, seuil_min, seuil_max, unite_mesure,
        tolerance_pourcentage, stade_croissance
    ) VALUES (
        p_type_culture_id, p_type_seuil, p_seuil_min, p_seuil_max, p_unite_mesure,
        p_tolerance_pourcentage, p_stade_croissance
    )
    RETURNING seuil_id INTO v_seuil_id;
    
    COMMIT;
    RETURN v_seuil_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CREATE_SEUIL_CULTURE;
