CREATE OR REPLACE FUNCTION DELETE_TYPE_CULTURE(
    p_type_culture_id IN NUMBER
) RETURN BOOLEAN
IS
    v_parcelles_utilisantes NUMBER;
BEGIN
    -- Vérifier si le type de culture est utilisé dans des parcelles
    SELECT COUNT(*)
    INTO v_parcelles_utilisantes
    FROM PARCELLE
    WHERE type_culture_id = p_type_culture_id;
    
    IF v_parcelles_utilisantes > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Impossible de supprimer: type de culture utilisé dans des parcelles');
    END IF;
    
    DELETE FROM TYPE_CULTURE
    WHERE type_culture_id = p_type_culture_id;
    
    COMMIT;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END DELETE_TYPE_CULTURE;
