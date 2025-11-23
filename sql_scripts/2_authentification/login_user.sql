CREATE OR REPLACE PROCEDURE login_utilisateur(
    p_email          IN VARCHAR2,
    p_password_hash  IN VARCHAR2
)
IS
    v_user_rec UTILISATEUR%ROWTYPE;
BEGIN

check_user_exists(p_email=>p_email);
    -- 1. Fetch user
    SELECT *
    INTO v_user_rec
    FROM UTILISATEUR
    WHERE email = p_email;
    
      IF v_user_rec.statut = 'BLOQUE' THEN
        RAISE_APPLICATION_ERROR(-20010, 'Votre compte est bloqué. Contactez un administrateur.');
    ELSIF v_user_rec.statut = 'DESACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20011, 'Votre compte est désactivé.');
    END IF;
    -- 2. Wrong password?
    IF v_user_rec.password_hash != p_password_hash THEN

        -- Increment attempts
        v_user_rec.tentatives_echec := v_user_rec.tentatives_echec + 1;

        UPDATE UTILISATEUR
        SET tentatives_echec = v_user_rec.tentatives_echec
        WHERE email = p_email;
        COMMIT;

        -- 3. Block account after 5 failures
        IF v_user_rec.tentatives_echec >= 5 THEN
            update_statut_user(
                p_user_id       => v_user_rec.user_id,
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
        COMMIT;
    END IF;
EXCEPTION

    WHEN OTHERS THEN
        ROLLBACK;

        -- Si c'est déjà un RAISE_APPLICATION_ERROR → renvoyer tel quel
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;
        END IF;

        RAISE_APPLICATION_ERROR(
            -20090,
            'Erreur lors du login : ' || SQLERRM
        );

       
END;
/
