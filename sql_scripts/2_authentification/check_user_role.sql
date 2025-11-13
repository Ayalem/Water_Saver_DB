CREATE OR REPLACE PROCEDURE check_user_role(
p_email IN VARCHAR2,
p_expected_role IN UTILISATEUR.role%TYPE)
IS
 v_role UTILISATEUR.role%TYPE;
BEGIN
 check_user_exists(p_email=>p_email);
 SELECT role INTO v_role
 FROM UTILISATEUR
 WHERE email=p_email;
 IF v_role!=p_expected_role THEN
 RAISE_APPLICATION_ERROR(-20001,'Votre rôle ne vous permet pas d’effectuer cette tâche.');
 END IF;
EXCEPTION 
      WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'Utilisateur introuvable.');
     WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-200099, 'Erreur inattendue : ' || SQLERRM);

END;

