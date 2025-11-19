CREATE OR REPLACE FUNCTION update_statut_capteur(
    p_capteur_id NUMBER,
    p_nouveau_statut VARCHAR2,
    p_user_id NUMBER
) RETURN NUMBER IS
    v_ancien_statut VARCHAR2(20);
    v_parcelle_id NUMBER;
    v_champ_id NUMBER;
    v_agriculteur_id NUMBER;
BEGIN
    SELECT c.statut, c.parcelle_id, p.champ_id, ch.user_id
    INTO v_ancien_statut, v_parcelle_id, v_champ_id, v_agriculteur_id
    FROM CAPTEUR c
    JOIN PARCELLE p ON c.parcelle_id = p.parcelle_id
    JOIN CHAMP ch ON p.champ_id = ch.champ_id
    WHERE c.capteur_id = p_capteur_id;
    UPDATE CAPTEUR
    SET statut = p_nouveau_statut
    WHERE capteur_id = p_capteur_id;
    IF v_ancien_statut != p_nouveau_statut THEN
        INSERT INTO NOTIFICATION (user_id, type_notification, message)
        VALUES (v_agriculteur_id, 'SYSTEME', 
                'Capteur ' || p_capteur_id || ' : ' || v_ancien_statut || ' → ' || p_nouveau_statut);
    END IF;
    
    COMMIT;
    RETURN 1;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Capteur introuvable');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END update_statut_capteur;
