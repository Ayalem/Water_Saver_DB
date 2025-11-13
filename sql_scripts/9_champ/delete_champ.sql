CREATE OR REPLACE FUNCTION DELETE_CHAMP(
    p_champ_id IN NUMBER
) RETURN BOOLEAN
IS
    v_can_deactivate VARCHAR2(3);
BEGIN
    -- Vérifier si le champ peut être désactivé
    v_can_deactivate := PEUT_DESACTIVER_CHAMP(p_champ_id);
    
    IF v_can_deactivate = 'OUI' THEN
        UPDATE CHAMP
        SET statut = 'INACTIF',
            date_modification = SYSDATE
        WHERE champ_id = p_champ_id;
        
        COMMIT;
        RETURN TRUE;
    ELSE
        RAISE_APPLICATION_ERROR(-20002, 'Impossible de désactiver le champ: parcelles actives existantes');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END DELETE_CHAMP;