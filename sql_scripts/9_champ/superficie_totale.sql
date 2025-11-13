CREATE OR REPLACE FUNCTION GET_SUPERFICIE_TOTALE_AGRICULTEUR(
    p_user_id IN NUMBER
) RETURN NUMBER
IS
    v_superficie_totale NUMBER(10,2);
BEGIN
    SELECT SUM(superficie)
    INTO v_superficie_totale
    FROM CHAMP
    WHERE user_id = p_user_id
    AND statut = 'ACTIF';
    
    RETURN NVL(v_superficie_totale, 0);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END GET_SUPERFICIE_TOTALE_AGRICULTEUR;