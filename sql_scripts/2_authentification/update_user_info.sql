CREATE OR REPLACE PROCEDURE update_user_info(
    p_email        IN VARCHAR2,
    p_nom          IN VARCHAR2 DEFAULT NULL,
    p_prenom       IN VARCHAR2 DEFAULT NULL,
    p_telephone    IN VARCHAR2 DEFAULT NULL,
    p_region       IN VARCHAR2 DEFAULT NULL
)
IS
    v_count NUMBER;
BEGIN

    check_user_exists(p_email => p_email);
    UPDATE UTILISATEUR
    SET nom       = NVL(p_nom, nom),
        prenom    = NVL(p_prenom, prenom),
        telephone = NVL(p_telephone, telephone),
        region_affectation = NVL(p_region, region_affectation)
    WHERE email = p_email;

    DBMS_OUTPUT.PUT_LINE(' Informations utilisateur mises à jour pour : ' || p_email);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20070, 'Erreur lors de la mise à jour : ' || SQLERRM);
END;

