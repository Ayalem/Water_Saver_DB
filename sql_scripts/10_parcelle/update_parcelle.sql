CREATE OR REPLACE FUNCTION UPDATE_PARCELLE(
    p_parcelle_id IN NUMBER,
    p_type_culture_id IN NUMBER DEFAULT NULL,
    p_nom IN VARCHAR2 DEFAULT NULL,
    p_superficie IN NUMBER DEFAULT NULL,
    p_latitude IN NUMBER DEFAULT NULL,
    p_longitude IN NUMBER DEFAULT NULL,
    p_date_plantation IN DATE DEFAULT NULL,
    p_date_recolte_prevue IN DATE DEFAULT NULL,
    p_statut IN VARCHAR2 DEFAULT NULL
) RETURN BOOLEAN
IS
    v_updated NUMBER;
BEGIN
    UPDATE PARCELLE
    SET type_culture_id = NVL(p_type_culture_id, type_culture_id),
        nom = NVL(p_nom, nom),
        superficie = NVL(p_superficie, superficie),
        latitude = NVL(p_latitude, latitude),
        longitude = NVL(p_longitude, longitude),
        date_plantation = NVL(p_date_plantation, date_plantation),
        date_recolte_prevue = NVL(p_date_recolte_prevue, date_recolte_prevue),
        statut = NVL(p_statut, statut),
        date_modification = SYSDATE
    WHERE parcelle_id = p_parcelle_id
    RETURNING 1 INTO v_updated;
    
    COMMIT;
    RETURN TRUE;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    WHEN OTHERS THEN
        ROLLBACK;
        RETURN FALSE;
END UPDATE_PARCELLE;