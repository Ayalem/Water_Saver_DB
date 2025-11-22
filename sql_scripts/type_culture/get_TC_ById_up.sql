CREATE OR REPLACE FUNCTION GET_TYPE_CULTURE_BY_ID(
    p_type_culture_id IN NUMBER
) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    SELECT tc.*, 
           GET_BESOINS_EAU_ESTIMES(tc.type_culture_id) AS besoins_eau_estimes,
           EST_COMPATIBLE_SAISON(tc.type_culture_id, EXTRACT(MONTH FROM SYSDATE)) AS compatible_saison_actuelle
    FROM TYPE_CULTURE tc
    WHERE tc.type_culture_id = p_type_culture_id;
    
    RETURN v_cursor;
END GET_TYPE_CULTURE_BY_ID;
/
