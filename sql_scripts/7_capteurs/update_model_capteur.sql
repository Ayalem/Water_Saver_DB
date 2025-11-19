CREATE OR REPLACE FUNCTION update_modele_capteur(
    p_capteur_id NUMBER,
    p_modele VARCHAR2,
    p_technicien_id NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_ancien_modele VARCHAR2(50);
    v_parcelle_id NUMBER;
BEGIN
    SELECT modele, parcelle_id 
    INTO v_ancien_modele, v_parcelle_id
    FROM CAPTEUR
    WHERE capteur_id = p_capteur_id;
    UPDATE CAPTEUR
    SET modele = p_modele
    WHERE capteur_id = p_capteur_id;
    IF p_technicien_id IS NOT NULL THEN
        INSERT INTO INTERVENTION (
            parcelle_id, capteur_id, technicien_id,
            type_intervention, priorite, statut, description, date_debut
        ) VALUES (
            v_parcelle_id, p_capteur_id, p_technicien_id,
            'MAINTENANCE_CAPTEUR', 'BASSE', 'TERMINE',
            'Changement modèle: ' || NVL(v_ancien_modele, 'N/A') || ' → ' || p_modele,
            SYSDATE
        );
    END IF;
    
    COMMIT;
    RETURN 1;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END update_modele_capteur;

