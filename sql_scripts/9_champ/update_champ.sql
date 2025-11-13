CREATE OR REPLACE FUNCTION UPDATE_CHAMP(
    p_champ_id IN NUMBER,
    p_nom IN VARCHAR2 DEFAULT NULL,
    p_superficie IN NUMBER DEFAULT NULL,
    p_type_champs IN VARCHAR2 DEFAULT NULL,
    p_type_sol IN VARCHAR2 DEFAULT NULL,
    p_systeme_irrigation IN VARCHAR2 DEFAULT NULL,
    p_adresse IN VARCHAR2 DEFAULT NULL,
    p_region IN VARCHAR2 DEFAULT NULL,
    p_ville IN VARCHAR2 DEFAULT NULL,
    p_code_postal IN VARCHAR2 DEFAULT NULL,
    p_latitude IN NUMBER DEFAULT NULL,
    p_longitude IN NUMBER DEFAULT NULL,
    p_date_plantation IN DATE DEFAULT NULL,
    p_statut IN VARCHAR2 DEFAULT NULL
) RETURN BOOLEAN
IS
    v_updated NUMBER;
BEGIN
    UPDATE CHAMP
    SET nom = NVL(p_nom, nom),
        superficie = NVL(p_superficie, superficie),
        type_champs = NVL(p_type_champs, type_champs),
        type_sol = NVL(p_type_sol, type_sol),
        systeme_irrigation = NVL(p_systeme_irrigation, systeme_irrigation),
        adresse = NVL(p_adresse, adresse),
        region = NVL(p_region, region),
        ville = NVL(p_ville, ville),
        code_postal = NVL(p_code_postal, code_postal),
        latitude = NVL(p_latitude, latitude),
        longitude = NVL(p_longitude, longitude),
        date_plantation = NVL(p_date_plantation, date_plantation),
        statut = NVL(p_statut, statut),
        date_modification = SYSDATE
    WHERE champ_id = p_champ_id
    RETURNING 1 INTO v_updated;
    
    COMMIT;
    RETURN TRUE;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    WHEN OTHERS THEN
        ROLLBACK;
        RETURN FALSE;
END UPDATE_CHAMP;