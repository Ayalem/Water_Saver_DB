CREATE OR REPLACE FUNCTION update_mesure(
    p_mesure_id NUMBER,
    p_valeur_mesure NUMBER DEFAULT NULL,
    p_unite_mesure VARCHAR2 DEFAULT NULL,
    p_qualite_signal NUMBER DEFAULT NULL,
    p_anomalie_detectee VARCHAR2 DEFAULT NULL
) RETURN NUMBER IS
BEGIN
    UPDATE MESURE
    SET valeur_mesure = NVL(p_valeur_mesure, valeur_mesure),
        unite_mesure = NVL(p_unite_mesure, unite_mesure),
        qualite_signal = NVL(p_qualite_signal, qualite_signal),
        anomalie_detectee = NVL(p_anomalie_detectee, anomalie_detectee)
    WHERE mesure_id = p_mesure_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Mesure introuvable');
    END IF;
    
    COMMIT;
    RETURN 1;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END update_mesure;

