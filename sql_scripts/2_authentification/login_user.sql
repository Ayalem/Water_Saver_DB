
CREATE OR REPLACE PROCEDURE login_utilisateur(
p_email IN VARCHAR2 ,
p_password_hash  IN VARCHAR2)
IS
v_user_rec UTILISATEUR%ROWTYPE;

BEGIN 



   SELECT user_id, email, password_hash, tentative_echec, statut, date_derniere_connexion
   INTO v_user_rec.user_id, v_user_rec.email, v_user_rec.password_hash, v_user_rec.tentative_echec, v_user_rec.statut, v_user_rec.date_derniere_connexion
   FROM UTILISATEUR
   WHERE email=p_email;
   
   

   IF v_user_rec.password_hash!=p_password_hash THEN
      v_user_rec.tentatives_echec:= v_user_rec.tentatives_echec+1;
      
      UPDATE UTILSATEUR
      SET tentatives_echec=v_user_rec.tentatives_echec
      WHERE email=p_email;
      
      
      IF v_user_rec.tentatves_echec>=5 THEN 
           update_status(v_user_rec.user_id ,'BLOQUE');
           RAISE_APPLICATION_ERROR(-20002, 'Votre compte est bloqué après trop de tentatives');
      ELSE
         RAISE_APPLICATION_ERROR(-20003,'le mot de passe ou le mail saisie est incorrect.Veuillez réesayer');
      END IF;
      
   ELSE
    UPDATE UTILISATEUR
    SET tentatives_echec=0,STATUS='ACTIF',date_derniere_connection=SYSTIMESTAMP
    WHERE user_id=v_user_rec.user_id;
    DBMS_OUTPUT.PUT_LINE('Connexion réussie pour : ' || p_email);
    END IF;
    
EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   RAISE_APPLICATION_ERROR(-20005,'email non trouvé.');
      
END;
