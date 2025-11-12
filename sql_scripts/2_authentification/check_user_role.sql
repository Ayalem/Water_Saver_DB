CREATE OR REPLACE PROCEDURE check_user_role(
p_user_id IN VARCHAR2,
p_expected_role IN VARCHAR2)
IS
 v_role UTILISATEUR.role%TYPE;
BEGIN
 check_user_exists(p_user_id=>p_user_id);
 SELECT role INTO v_role
 FROM UTILISATEUR
 WHERE user_id=p_user_id;
 IF v_role!=p_expected_role THEN
 RAISE_APPLICATION_ERROR(-20030,'Votre rôle ne vous permet pas d’effectuer cette tâche.');
 END IF;
EXCEPTION 
      WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20031, 'Utilisateur introuvable.');
     WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20034, 'Erreur inattendue : ' || SQLERRM);

END;
