CREATE OR REPLACE FUNCTION DELETE_PARCELLE(
    p_parcelle_id IN NUMBER
) RETURN BOOLEAN
IS
    v_capteurs_actifs NUMBER;
BEGIN
    -- Vérifier s'il y a des capteurs actifs sur cette parcelle
    SELECT COUNT(*)
    INTO v_capteurs_actifs
    FROM CAPTEUR
    WHERE parcelle_id = p_parcelle_id AND statut = 'ACTIF';
    
    IF v_capteurs_actifs > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Impossible de supprimer: capteurs actifs sur la parcelle');
    END IF;
    
    -- Désactivation logique
    UPDATE PARCELLE
    SET statut = 'INACTIVE',
        date_modification = SYSDATE
    WHERE parcelle_id = p_parcelle_id;
    
    COMMIT;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END DELETE_PARCELLE;
