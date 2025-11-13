CREATE OR REPLACE FUNCTION PEUT_DESACTIVER_CHAMP(
    p_champ_id IN NUMBER
) RETURN VARCHAR2
IS
    v_parcelles_actives NUMBER;
BEGIN
    -- Vérifier s'il y a des parcelles actives dans ce champ
    SELECT COUNT(*)
    INTO v_parcelles_actives
    FROM PARCELLE
    WHERE champ_id = p_champ_id
    AND statut = 'ACTIVE';
    
    IF v_parcelles_actives > 0 THEN
        RETURN 'NON';
    ELSE
        RETURN 'OUI';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'NON';
END PEUT_DESACTIVER_CHAMP;
