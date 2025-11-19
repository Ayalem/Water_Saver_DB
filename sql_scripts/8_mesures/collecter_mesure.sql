CREATE OR REPLACE FUNCTION collecter_mesure(
    p_capteur_id       NUMBER,
    p_type_mesure      VARCHAR2,
    p_valeur_mesure    NUMBER,
    p_unite_mesure     VARCHAR2,
    p_qualite_signal   NUMBER DEFAULT 100
) RETURN NUMBER IS
    v_mesure_id        NUMBER;
    v_statut           VARCHAR2(20);
BEGIN
    -- Vérifier si le capteur est actif
    SELECT statut
    INTO v_statut
    FROM CAPTEUR
    WHERE capteur_id = p_capteur_id;

    IF v_statut != 'ACTIF' THEN
        RAISE_APPLICATION_ERROR(-20007, 'Capteur non actif - statut: ' || v_statut);
    END IF;

    -- Insertion direct dans la table MESURE (sans anomalie)
    INSERT INTO MESURE (
        capteur_id,
        type_mesure,
        valeur_mesure,
        unite_mesure,
        qualite_signal,
        anomalie_detectee
    ) VALUES (
        p_capteur_id,
        p_type_mesure,
        p_valeur_mesure,
        p_unite_mesure,
        p_qualite_signal,
        'NON'       -- toujours NON, car on ignore les anomalies
    )
    RETURNING mesure_id INTO v_mesure_id;

    -- Mise à jour de la dernière mesure du capteur
    UPDATE CAPTEUR
    SET date_derniere_mesure = SYSDATE
    WHERE capteur_id = p_capteur_id;

    RETURN v_mesure_id;
END collecter_mesure;
/
CREATE OR REPLACE PROCEDURE collecter_mesures_all IS
BEGIN
    FOR cap IN (
        SELECT capteur_id, type_mesure_default, unite_default
        FROM CAPTEUR
        WHERE statut = 'ACTIF'
    )
    LOOP
        DECLARE
            v_val NUMBER;
        BEGIN
            -- Exemple : valeur simulée (à remplacer par lecture réelle)
            v_val := DBMS_RANDOM.VALUE(10, 50);

            collecter_mesure(
                cap.capteur_id,
                cap.type_mesure_default,
                v_val,
                cap.unite_default
            );
        END;
    END LOOP;
END collecter_mesures_all;

BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_COLLECTE_MESURES_15MIN',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'collecter_mesures_all',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=15',
        enabled         => TRUE
    );
END;

