CREATE OR REPLACE PROCEDURE check_user_exists(
    p_user_id IN UTILISATEUR.user_id%TYPE DEFAULT NULL,
    p_email   IN UTILISATEUR.email%TYPE   DEFAULT NULL
)
IS
    v_count NUMBER;
BEGIN

    IF p_user_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
        FROM UTILISATEUR
        WHERE user_id = p_user_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20030, 'Utilisateur introuvable avec cet user_id.');
        END IF;

    ELSIF p_email IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
        FROM UTILISATEUR
        WHERE email = p_email;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20031, 'Utilisateur introuvable avec cet email.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20032, 'Veuillez fournir un email ou un user_id.');
    END IF;
END;

