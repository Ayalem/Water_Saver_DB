 TRIGGER 1 : TRG_MESURE_ALERTE (Détection et Création d'Alerte)
CREATE OR REPLACE TRIGGER TRG_MESURE_ALERTE
AFTER INSERT ON MESURE
FOR EACH ROW
DECLARE
    v_parcelle_id NUMBER;
    v_seuil_min NUMBER;
    v_seuil_max NUMBER;
    v_type_alerte VARCHAR2(200);
    v_seuil_depasse_valeur NUMBER;
    v_pourcentage_depassement NUMBER;
    v_severite VARCHAR2(20);
    v_alert_needed BOOLEAN := FALSE;
BEGIN
    -- [LOGIQUE] 1. Récupération parcelle
    SELECT id_parcelle INTO v_parcelle_id FROM CAPTEUR WHERE id_capteur = :NEW.id_capteur;

    -- [LOGIQUE] 2. Appelle PRC_GET_SEUILS
    PRC_GET_SEUILS(
        p_parcelle_id => v_parcelle_id,
        p_type_mesure => :NEW.type_mesure,
        p_seuil_min   => v_seuil_min,
        p_seuil_max   => v_seuil_max
    );

    -- [LOGIQUE] 3. Vérification MIN/MAX
    IF v_seuil_min IS NOT NULL AND :NEW.valeur_mesure < v_seuil_min THEN
        v_alert_needed := TRUE;
        v_type_alerte := :NEW.type_mesure || '_TROP_FAIBLE';
        v_seuil_depasse_valeur := v_seuil_min;
        v_pourcentage_depassement := ROUND(((v_seuil_min - :NEW.valeur_mesure) / v_seuil_min) * 100, 2);
    ELSIF v_seuil_max IS NOT NULL AND :NEW.valeur_mesure > v_seuil_max THEN
        v_alert_needed := TRUE;
        v_type_alerte := :NEW.type_mesure || '_TROP_ÉLEVÉE';
        v_seuil_depasse_valeur := v_seuil_max;
        v_pourcentage_depassement := ROUND(((:NEW.valeur_mesure - v_seuil_max) / v_seuil_max) * 100, 2);
    END IF;

    -- [LOGIQUE] 4. Créer l'alerte
    IF v_alert_needed THEN
        IF v_pourcentage_depassement > 50 THEN v_severite := 'CRITIQUE';
        ELSIF v_pourcentage_depassement > 10 THEN v_severite := 'HAUTE';
        ELSE v_severite := 'ATTENTION';
        END IF;

        -- 5. Appelle PRC_CREER_ALERTE
        PRC_CREER_ALERTE (
            p_mesure_id             => :NEW.id_mesure,
            p_parcelle_id           => v_parcelle_id,
            p_type_alerte           => v_type_alerte,
            p_severite              => v_severite,
            p_valeur_mesuree        => :NEW.valeur_mesure,
            p_valeur_seuil          => v_seuil_depasse_valeur,
            p_pourcentage_depassement => v_pourcentage_depassement
        );
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur Trigger TRG_MESURE_ALERTE: ' || SQLERRM);
END TRG_MESURE_ALERTE;

