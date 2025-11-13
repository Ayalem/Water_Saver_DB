CREATE OR REPLACE FUNCTION CREATE_CHAMP(
    p_user_id IN NUMBER,
    p_nom IN VARCHAR2,
    p_superficie IN NUMBER,
    p_type_champs IN VARCHAR2 DEFAULT NULL,
    p_type_sol IN VARCHAR2 DEFAULT NULL,
    p_systeme_irrigation IN VARCHAR2 DEFAULT NULL,
    p_adresse IN VARCHAR2 DEFAULT NULL,
    p_region IN VARCHAR2 DEFAULT NULL,
    p_ville IN VARCHAR2 DEFAULT NULL,
    p_code_postal IN VARCHAR2 DEFAULT NULL,
    p_latitude IN NUMBER DEFAULT NULL,
    p_longitude IN NUMBER DEFAULT NULL,
    p_date_plantation IN DATE DEFAULT NULL
) RETURN NUMBER
IS
    v_champ_id NUMBER;
    v_user_exists NUMBER;
BEGIN
    -- Vérifier si l'utilisateur existe
    SELECT COUNT(*) INTO v_user_exists
    FROM UTILISATEUR
    WHERE user_id = p_user_id AND statut = 'ACTIF';
    
    IF v_user_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Utilisateur non trouvé ou inactif');
    END IF;
    
    -- Insérer le nouveau champ
    INSERT INTO CHAMP (
        user_id, nom, superficie, type_champs, type_sol, systeme_irrigation,
        adresse, region, ville, code_postal, latitude, longitude, date_plantation
    ) VALUES (
        p_user_id, p_nom, p_superficie, p_type_champs, p_type_sol, p_systeme_irrigation,
        p_adresse, p_region, p_ville, p_code_postal, p_latitude, p_longitude, p_date_plantation
    )
    RETURNING champ_id INTO v_champ_id;
    
    COMMIT;
    RETURN v_champ_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CREATE_CHAMP;
