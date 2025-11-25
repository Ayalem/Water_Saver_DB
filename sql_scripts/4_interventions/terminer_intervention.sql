CREATE OR REPLACE PROCEDURE terminer_intervention(
    p_intervention_id NUMBER,
    p_technicien_id NUMBER,
    p_cout NUMBER,
    p_notes CLOB
)
IS 
    v_count NUMBER;
    v_date_debut TIMESTAMP;
    v_duree_minutes NUMBER;
BEGIN
    -- Verify intervention exists and belongs to technician
    SELECT COUNT(*), MAX(date_debut) 
    INTO v_count, v_date_debut
    FROM INTERVENTION
    WHERE intervention_id = p_intervention_id
    AND technicien_id = p_technicien_id;
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Intervention non trouvée ou non assignée à ce technicien');
    END IF;
    
    -- Calculate duration in minutes
    IF v_date_debut IS NOT NULL THEN
        v_duree_minutes := ROUND(EXTRACT(DAY FROM (SYSTIMESTAMP - v_date_debut)) * 24 * 60 +
                                 EXTRACT(HOUR FROM (SYSTIMESTAMP - v_date_debut)) * 60 +
                                 EXTRACT(MINUTE FROM (SYSTIMESTAMP - v_date_debut)));
    ELSE
        v_duree_minutes := 0;
    END IF;
    
    -- Update intervention
    UPDATE INTERVENTION 
    SET statut = 'TERMINE',
        date_fin = SYSTIMESTAMP,
        duree_minutes = v_duree_minutes,
        cout_intervention = p_cout,
        notes = p_notes
    WHERE intervention_id = p_intervention_id;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;
        END IF;
        RAISE_APPLICATION_ERROR(-20029, 'Erreur lors de la finalisation : ' || SQLERRM);
END;
/
