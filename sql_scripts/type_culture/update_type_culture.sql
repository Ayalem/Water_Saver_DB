CREATE OR REPLACE FUNCTION UPDATE_TYPE_CULTURE(
    p_type_culture_id IN NUMBER,
    p_nom IN VARCHAR2 DEFAULT NULL,
    p_categorie IN VARCHAR2 DEFAULT NULL,
    p_cycle_croissance_jours IN NUMBER DEFAULT NULL,
    p_coefficient_cultural_kc IN NUMBER DEFAULT NULL,
    p_description IN VARCHAR2 DEFAULT NULL
) RETURN BOOLEAN
IS
    v_updated NUMBER;
BEGIN
    -- Vérifier l'unicité du nom si modification
    IF p_nom IS NOT NULL THEN
        DECLARE
            v_exists NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_exists
            FROM TYPE_CULTURE
            WHERE UPPER(nom) = UPPER(p_nom) AND type_culture_id != p_type_culture_id;
            
            IF v_exists > 0 THEN
                RAISE_APPLICATION_ERROR(-20007, 'Un autre type de culture avec ce nom existe déjà');
            END IF;
        END;
    END IF;
    
    UPDATE TYPE_CULTURE
    SET nom = NVL(p_nom, nom),
        categorie = NVL(p_categorie, categorie),
        cycle_croissance_jours = NVL(p_cycle_croissance_jours, cycle_croissance_jours),
        coefficient_cultural_kc = NVL(p_coefficient_cultural_kc, coefficient_cultural_kc),
        description = NVL(p_description, description),
        date_creation = SYSDATE
    WHERE type_culture_id = p_type_culture_id
    RETURNING 1 INTO v_updated;
    
    COMMIT;
    RETURN TRUE;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    WHEN OTHERS THEN
        ROLLBACK;
        RETURN FALSE;
END UPDATE_TYPE_CULTURE;
