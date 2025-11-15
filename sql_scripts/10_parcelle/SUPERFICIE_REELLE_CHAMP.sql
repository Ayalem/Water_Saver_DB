CREATE OR REPLACE FUNCTION SUPERFICIE_REELLE_CHAMP(
    p_champ_id IN NUMBER
) RETURN NUMBER
IS
    v_superficie_totale NUMBER;
BEGIN
    -- Somme des superficies de toutes les parcelles actives du champ
    SELECT NVL(SUM(superficie), 0)
    INTO v_superficie_totale
    FROM PARCELLE
    WHERE champ_id = p_champ_id
      AND statut = 'ACTIVE';

    RETURN v_superficie_totale;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END SUPERFICIE_REELLE_CHAMP;
/
