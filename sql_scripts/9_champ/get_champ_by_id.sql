CREATE OR REPLACE FUNCTION GET_CHAMP_BY_ID(
    p_champ_id IN NUMBER
) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    SELECT c.*, u.nom as proprietaire_nom, u.prenom as proprietaire_prenom
    FROM CHAMP c
    JOIN UTILISATEUR u ON c.user_id = u.user_id
    WHERE c.champ_id = p_champ_id;
    
    RETURN v_cursor;
END GET_CHAMP_BY_ID;
/