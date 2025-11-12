 CREATE OR REPLACE PROCEDURE check_user_exists(
    p_user_id IN UTILISATEUR.user_id%TYPE
)
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM UTILISATEUR
    WHERE user_id = p_user_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Utilisateur introuvable.');
    END IF;
END;
/
