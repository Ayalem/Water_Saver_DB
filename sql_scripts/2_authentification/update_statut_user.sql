CREATE OR REPLACE PROCEDURE update_statut_user(
    p_user_id        IN UTILISATEUR.user_id%TYPE,
    p_admin          IN UTILISATEUR.user_id%TYPE,
    p_password_hash  IN UTILISATEUR.password_hash%TYPE,
    p_statut         IN UTILISATEUR.statut%TYPE
)
IS
BEGIN

    check_user_exists(p_user_id => p_admin);

   
    check_user_exists(p_user_id => p_user_id);

   
    UPDATE UTILISATEUR
    SET statut = p_statut
    WHERE user_id = p_user_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20043, 'User does not exist');
END;


