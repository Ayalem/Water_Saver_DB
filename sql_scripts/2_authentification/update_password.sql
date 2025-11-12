CREATE OR REPLACE PROCEDURE update_password(p_ancien_password_hash IN VARCHAR2,
                                            p_nouveau_pass_hash IN VARCHAR2,
                                            p_email IN VARCHAR2)
IS
 v_password_hash UTILISATEUR.password_hash%TYPE;
BEGIN
   check_user_exists(p_email);
   SELECT password_hash INTO v_password_hash
   FROM UTILISATEUR
   WHERE email=p_email;
   
   IF v_password_hash!=p_ancien_password_hash THEN
     RAISE_APPLICATION_ERROR(-20010,'le mot de passe est incorrect');
   END IF;
   
   UPDATE UTILISATEUR 
   SET password_hash=p_nouveau_pass_hash
   WHERE email=p_email;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
   RAISE_APPLICATION_ERROR(-20020,'Utilisateur introuvable.');
   
 
END;


                                           
