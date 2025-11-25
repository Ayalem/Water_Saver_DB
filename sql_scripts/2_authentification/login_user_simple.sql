CREATE OR REPLACE PROCEDURE login_utilisateur(
    p_email          IN VARCHAR2,
    p_password_hash  IN VARCHAR2
)
IS
    v_user_rec UTILISATEUR%ROWTYPE;
    v_count NUMBER;
BEGIN
    -- Check if user exists
    SELECT COUNT(*) INTO v_count
    FROM UTILISATEUR
    WHERE email = p_email;
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Utilisateur introuvable.');
    END IF;
    
    -- Fetch user
    SELECT *
    INTO v_user_rec
    FROM UTILISATEUR
    WHERE email = p_email;
    
    -- Check status
    IF v_user_rec.statut = 'BLOQUE' THEN
        RAISE_APPLICATION_ERROR(-20010, 'Votre compte est bloqué. Contactez un administrateur.');
    ELSIF v_user_rec.statut = 'DESACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20011, 'Votre compte est désactivé.');
    END IF;
    
    -- Check password
    IF v_user_rec.password_hash != p_password_hash THEN
        -- Increment attempts
        UPDATE UTILISATEUR
        SET tentatives_echec = NVL(tentatives_echec, 0) + 1
        WHERE email = p_email;
        
        -- Block after 5 failures
        IF NVL(v_user_rec.tentatives_echec, 0) + 1 >= 5 THEN
            UPDATE UTILISATEUR
            SET statut = 'BLOQUE'
            WHERE user_id = v_user_rec.user_id;
            COMMIT;
            RAISE_APPLICATION_ERROR(-20002, 'Votre compte est bloqué après trop de tentatives.');
        ELSE
            COMMIT;
            RAISE_APPLICATION_ERROR(-20003, 'Email ou mot de passe incorrect.');
        END IF;
    ELSE
        -- Login success
        UPDATE UTILISATEUR
        SET tentatives_echec = 0,
            statut = 'ACTIF',
            date_derniere_connexion = SYSTIMESTAMP
        WHERE user_id = v_user_rec.user_id;
        COMMIT;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;
        END IF;
        RAISE_APPLICATION_ERROR(-20090, 'Erreur lors du login : ' || SQLERRM);
END;
/
