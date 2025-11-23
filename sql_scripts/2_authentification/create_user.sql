CREATE OR REPLACE PROCEDURE create_user(
    p_email               IN VARCHAR2,
    p_nom                 IN VARCHAR2,
    p_prenom              IN VARCHAR2,
    p_password_hash       IN VARCHAR2,
    p_telephone           IN VARCHAR2,
    p_role                IN VARCHAR2,
    p_region_affectation  IN VARCHAR2
)
IS
    v_count NUMBER;
BEGIN
    --------------------------------------------------------------------
    -- 1) Validation email
    --------------------------------------------------------------------
    IF NOT REGEXP_LIKE(p_email,
            '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
        RAISE_APPLICATION_ERROR(-20100, 'Email invalide.');
    END IF;

    --------------------------------------------------------------------
    -- 2) Validation rôle (liste contrôlée)
    --------------------------------------------------------------------
    IF p_role NOT IN ('AGRICULTEUR', 'TECHNICIEN', 'INSPECTEUR', 'ADMIN') THEN
        RAISE_APPLICATION_ERROR(-20101, 'Rôle utilisateur invalide.');
    END IF;

    --------------------------------------------------------------------
    -- 3) Validation téléphone (optionnel)
    --------------------------------------------------------------------
    IF NOT REGEXP_LIKE(p_telephone, '^[0-9]{9,15}$') THEN
        RAISE_APPLICATION_ERROR(-20102, 'Numéro de téléphone invalide.');
    END IF;

    --------------------------------------------------------------------
    -- 4) Vérification email unique
    --------------------------------------------------------------------
    SELECT COUNT(*)
    INTO v_count
    FROM UTILISATEUR
    WHERE email = p_email;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20103, 'Email déjà utilisé.');
    END IF;

    --------------------------------------------------------------------
    -- 5) Insertion utilisateur
    --------------------------------------------------------------------
    INSERT INTO UTILISATEUR(
        email, password_hash, nom, prenom, telephone,
        role, region_affectation, date_creation, statut
    )
    VALUES (
        p_email, p_password_hash, p_nom, p_prenom, p_telephone,
        p_role, p_region_affectation, SYSTIMESTAMP, 'ACTIF'
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Utilisateur créé avec succès : ' || p_email);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20104, 'Conflit : email déjà existant.');

    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20105, 'Erreur de type sur un paramètre.');

    WHEN OTHERS THEN
        ROLLBACK;

        -- Ne modifie pas les erreurs personnalisées (-20xxx)
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;
        END IF;

        RAISE_APPLICATION_ERROR(
            -20199,
            'Erreur lors de la création de l''utilisateur : ' || SQLERRM
        );
END;
/
