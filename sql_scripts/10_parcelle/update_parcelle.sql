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
    v_champ_id NUMBER;
    v_superficie_champ NUMBER;
    v_superficie_occupee_autres NUMBER;
    v_superficie_actuelle_parcelle NUMBER;
BEGIN
    -- Récupérer le champ et la superficie actuelle de la parcelle
    SELECT champ_id, superficie
    INTO v_champ_id, v_superficie_actuelle_parcelle
    FROM PARCELLE
    WHERE parcelle_id = p_parcelle_id;

    -- Vérifier si la nouvelle superficie dépasse la superficie du champ
    IF p_superficie IS NOT NULL THEN
        v_superficie_occupee_autres := SUPERFICIE_REELLE_CHAMP(v_champ_id) - v_superficie_actuelle_parcelle;

        SELECT superficie
        INTO v_superficie_champ
        FROM CHAMP
        WHERE champ_id = v_champ_id;

        IF (v_superficie_occupee_autres + p_superficie) > v_superficie_champ THEN
            RAISE_APPLICATION_ERROR(-20004, 'Superficie totale des parcelles dépasse celle du champ');
        END IF;
    END IF;

    -- Mettre à jour la parcelle
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
        RAISE;
END UPDATE_PARCELLE;
/
-- 2.4 Fonction GET_PARCELLE_BY_ID
CREATE OR REPLACE FUNCTION GET_PARCELLE_BY_ID(
    p_parcelle_id IN NUMBER
) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    SELECT p.*, c.nom as champ_nom, tc.nom as type_culture_nom,
           CALCULER_RENDEMENT_PREVU(p.parcelle_id) as rendement_prevue,
           EST_RECOLTE_IMMINENTE(p.parcelle_id) as recolte_imminente
    FROM PARCELLE p
    JOIN CHAMP c ON p.champ_id = c.champ_id
    LEFT JOIN TYPE_CULTURE tc ON p.type_culture_id = tc.type_culture_id
    WHERE p.parcelle_id = p_parcelle_id;
    
    RETURN v_cursor;
END GET_PARCELLE_BY_ID;
/
