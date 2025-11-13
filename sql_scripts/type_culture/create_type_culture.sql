CREATE OR REPLACE FUNCTION CREATE_TYPE_CULTURE(
    p_nom IN VARCHAR2,
    p_categorie IN VARCHAR2 DEFAULT NULL,
    p_cycle_croissance_jours IN NUMBER DEFAULT NULL,
    p_coefficient_cultural_kc IN NUMBER DEFAULT NULL,
    p_description IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER
IS
    v_type_culture_id NUMBER;
BEGIN
    -- Vérifier si le nom existe déjà
    DECLARE
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists
        FROM TYPE_CULTURE
        WHERE UPPER(nom) = UPPER(p_nom);
        
        IF v_exists > 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Type de culture déjà existant');
        END IF;
    END;
    
    -- Insérer le nouveau type de culture
    INSERT INTO TYPE_CULTURE (
        nom, categorie, cycle_croissance_jours, coefficient_cultural_kc, description
    ) VALUES (
        p_nom, p_categorie, p_cycle_croissance_jours, p_coefficient_cultural_kc, p_description
    )
    RETURNING type_culture_id INTO v_type_culture_id;
    
    COMMIT;
    RETURN v_type_culture_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CREATE_TYPE_CULTURE;
/
