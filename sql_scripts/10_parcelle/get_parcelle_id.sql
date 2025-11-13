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
