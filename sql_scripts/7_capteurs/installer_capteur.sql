CREATE OR REPLACE FUNCTION installer_capteur(
    p_parcelle_id NUMBER,
    p_numero_serie VARCHAR2,
    p_modele VARCHAR2,
    p_type_capteur VARCHAR2,
    p_frequence_mesure NUMBER DEFAULT 15
) RETURN NUMBER IS
    v_capteur_id NUMBER;
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM PARCELLE
    WHERE parcelle_id = p_parcelle_id AND statut = 'ACTIVE';
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Parcelle invalide ou inactive');
    END IF;
    INSERT INTO CAPTEUR (
        parcelle_id, numero_serie, modele, type_capteur, 
        statut, frequence_mesure, date_installation, niveau_batterie
    ) VALUES (
        p_parcelle_id, p_numero_serie, p_modele, p_type_capteur,
        'ACTIF', p_frequence_mesure, SYSDATE, 100
    ) RETURNING capteur_id INTO v_capteur_id;
    
    COMMIT;
    RETURN v_capteur_id;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20002, 'Numéro de série déjà existant');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END installer_capteur;

