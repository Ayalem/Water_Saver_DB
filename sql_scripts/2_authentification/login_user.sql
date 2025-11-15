CREATE OR REPLACE PROCEDURE login_utilisateur(
    p_email          IN VARCHAR2,
    p_password_hash  IN VARCHAR2
)
IS
    v_user_rec UTILISATEUR%ROWTYPE;
BEGIN
    -- 1. Fetch user
    SELECT *
    INTO v_user_rec
    FROM UTILISATEUR
    WHERE email = p_email;

    -- 2. Wrong password?
    IF v_user_rec.password_hash != p_password_hash THEN

        -- Increment attempts
        v_user_rec.tentatives_echec := v_user_rec.tentatives_echec + 1;

        UPDATE UTILISATEUR
        SET tentatives_echec = v_user_rec.tentatives_echec
        WHERE email = p_email;

        -- 3. Block account after 5 failures
        IF v_user_rec.tentatives_echec >= 5 THEN
            update_statut_user(
                p_user_id       => v_user_rec.user_id,
                p_admin         => v_user_rec.user_id,    -- or admin_id if you want admin
                p_password_hash => v_user_rec.password_hash,
                p_statut        => 'BLOQUE'
            );

            RAISE_APPLICATION_ERROR(-20002, 'Votre compte est bloqué après trop de tentatives.');
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Email ou mot de passe incorrect. Veuillez réessayer.');
        END IF;

    ELSE
        -- 4. Login success
        UPDATE UTILISATEUR
        SET tentatives_echec = 0,
            statut = 'ACTIF',
            date_derniere_connexion = SYSTIMESTAMP
        WHERE user_id = v_user_rec.user_id;

        DBMS_OUTPUT.PUT_LINE('Connexion réussie pour : ' || p_email);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Email non trouvé.');
END;
/
