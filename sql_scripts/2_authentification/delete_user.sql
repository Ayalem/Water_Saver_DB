CREATE OR REPLACE PROCEDURE delete_user(
    p_user_id IN NUMBER
)
IS
BEGIN 
    -- Check if user exists
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM UTILISATEUR
        WHERE user_id = p_user_id;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 'Utilisateur introuvable.');
        END IF;
    END;
    
    -- Delete user
    DELETE FROM UTILISATEUR
    WHERE user_id = p_user_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Utilisateur supprimé avec succès : ' || p_user_id);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;
        END IF;
        RAISE_APPLICATION_ERROR(-20029, 'Erreur lors de la suppression : ' || SQLERRM);
END;
/
