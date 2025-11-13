CREATE OR REPLACE FUNCTION GET_SEUIL_BY_ID(
    p_seuil_id IN NUMBER
) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    SELECT sc.*, tc.nom as type_culture_nom
    FROM SEUIL_CULTURE sc
    JOIN TYPE_CULTURE tc ON sc.type_culture_id = tc.type_culture_id
    WHERE sc.seuil_id = p_seuil_id;
    
    RETURN v_cursor;
END GET_SEUIL_BY_ID;
