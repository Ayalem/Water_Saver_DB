CREATE OR REPLACE FUNCTION EST_RECOLTE_IMMINENTE(
    p_parcelle_id IN NUMBER
) RETURN VARCHAR2
IS
    v_date_recolte DATE;
BEGIN
    SELECT date_recolte_prevue
    INTO v_date_recolte
    FROM PARCELLE
    WHERE parcelle_id = p_parcelle_id;

    IF v_date_recolte IS NOT NULL AND v_date_recolte <= SYSDATE + 7 THEN
        RETURN 'OUI';
    ELSE
        RETURN 'NON';
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'NON';
END EST_RECOLTE_IMMINENTE;
/
