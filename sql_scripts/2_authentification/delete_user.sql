CREATE OR REPLACE PROCEDURE delete_user(p_email IN VARCHAR2,p_password_hash IN VARCHAR2)
IS
v_password_hash UTILISATEUR.password_hash%TYPE;
BEGIN 
   check_user_exists(p_email);
   SELECT password_hash INTO v_password_hash
   FROM UTILISATEUR
   WHERE email=p_email;
   
    IF v_password_hash!=p_password_hash THEN
     RAISE_APPLICATION_ERROR(-20010,'le mot de passe est incorrect');
   END IF;
   
   DELETE FROM UTILISATEUR
   WHERE email=p_email;
DBMS_OUTPUT.PUT_LINE('Utilisateur supprimé avec succès : ' || p_email);
   
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RAISE_APPLICATION_ERROR(-20020, 'Utilisateur introuvable.');
END;

