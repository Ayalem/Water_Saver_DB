CREATE OR REPLACE PROCEDURE create_user(
  p_password_hash  IN VARCHAR2,
  p_nom IN VARCHAR2,
  p_prenom IN VARCHAR2,
  p_email IN VARCHAR2 ,
  p_telephone IN  VARCHAR2,
  p_role IN VARCHAR2,
  p_region_affectation IN  VARCHAR2)
  IS
  v_count NUMBER;
  BEGIN 
     IF NOT REGEXP_LIKE(p_email,'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 
         RAISE_APPLICATION_ERROR(-20000,'email invalide');
     END IF;
     SELECT COUNT(*) INTO v_count
     FROM UTILISATEUR
     WHERE email=p_email;
      
     IF v_count>0 THEN
        RAISE_APPLICATION_ERROR(-200001,'email déja utilisé');
     END IF;
   
     
     INSERT INTO UTILISATEUR(email,password_hash,nom,prenom,telephone,role,region_affectation)
     VALUES (p_email,p_password_hash,p_nom,p_prenom,p_telephone,p_role,p_region_affectation);
     DBMS_OUTPUT.PUT_LINE('Utilisateur créé avec succès : ' || p_email);
     
  END;
     



    
   

   
   
   

   
