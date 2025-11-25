CREATE OR REPLACE PROCEDURE update_user_role(
    p_user_id IN NUMBER,
    p_new_role IN VARCHAR2
)
IS
    v_count NUMBER;
BEGIN
    -- Check if user exists
    SELECT COUNT(*) INTO v_count
    FROM UTILISATEUR
    WHERE user_id = p_user_id;
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Utilisateur introuvable.');
    END IF;
    
    -- Validate role
    IF p_new_role NOT IN ('AGRICULTEUR', 'TECHNICIEN', 'INSPECTEUR', 'ADMIN') THEN
        RAISE_APPLICATION_ERROR(-20021, 'Rôle invalide. Doit être: AGRICULTEUR, TECHNICIEN, INSPECTEUR, ou ADMIN');
    END IF;
    
    -- Update role
    UPDATE UTILISATEUR
    SET role = p_new_role,
        date_modification = SYSTIMESTAMP
    WHERE user_id = p_user_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Rôle mis à jour pour user_id=' || p_user_id || ' → nouveau rôle : ' || p_new_role);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;
        END IF;
        RAISE_APPLICATION_ERROR(-20029, 'Erreur lors de la mise à jour du rôle : ' || SQLERRM);
END;
/
