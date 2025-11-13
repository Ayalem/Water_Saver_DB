PROCEDURE grant_user_role(
    p_admin_id IN VARCHAR2,
    p_user_id IN VARCHAR2,
    p_new_role IN VARCHAR2
)
IS 
BEGIN
   check_user_exists(p_user_id=>p_admin_id );
   check_role(p_admin_id ,'ADMIN');
   check_user_exists(p_user_id => p_user_id);
   
   UPDATE UTILISATEUR
   SET role=p_new_role
   WHERE user_id=p_user_id;
   
   IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Aucun utilisateur mis à jour (ID invalide).');
    END IF;
   
EXCEPTION
 WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20041,'utilisateur introuvable');
WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20042, 'Erreur inattendue : ' || SQLERRM);
END;
   

   
