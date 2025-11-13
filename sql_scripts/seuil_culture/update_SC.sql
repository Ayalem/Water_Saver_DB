CREATE OR REPLACE FUNCTION UPDATE_SEUIL_CULTURE(
    p_seuil_id IN NUMBER,
    p_seuil_min IN NUMBER DEFAULT NULL,
    p_seuil_max IN NUMBER DEFAULT NULL,
    p_unite_mesure IN VARCHAR2 DEFAULT NULL,
    p_tolerance_pourcentage IN NUMBER DEFAULT NULL,
    p_stade_croissance IN VARCHAR2 DEFAULT NULL
) RETURN BOOLEAN
IS
    v_updated NUMBER;
BEGIN
    UPDATE SEUIL_CULTURE
    SET seuil_min = NVL(p_seuil_min, seuil_min),
        seuil_max = NVL(p_seuil_max, seuil_max),
        unite_mesure = NVL(p_unite_mesure, unite_mesure),
        tolerance_pourcentage = NVL(p_tolerance_pourcentage, tolerance_pourcentage),
        stade_croissance = NVL(p_stade_croissance, stade_croissance),
        date_modification = SYSDATE
    WHERE seuil_id = p_seuil_id
    RETURNING 1 INTO v_updated;
    
    COMMIT;
    RETURN TRUE;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    WHEN OTHERS THEN
        ROLLBACK;
        RETURN FALSE;
END UPDATE_SEUIL_CULTURE;
