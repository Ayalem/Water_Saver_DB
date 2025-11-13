CREATE OR REPLACE FUNCTION CALCULER_RENDEMENT_PREVU(
    p_parcelle_id IN NUMBER
) RETURN NUMBER
IS
    v_superficie NUMBER(10,2);
    v_type_culture_id NUMBER;
    v_coefficient_kc NUMBER(3,2);
    v_rendement_estime NUMBER(10,2);
BEGIN
    -- Récupérer les informations de la parcelle
    SELECT p.superficie, p.type_culture_id, tc.coefficient_cultural_kc
    INTO v_superficie, v_type_culture_id, v_coefficient_kc
    FROM PARCELLE p
    LEFT JOIN TYPE_CULTURE tc ON p.type_culture_id = tc.type_culture_id
    WHERE p.parcelle_id = p_parcelle_id;
    
    -- Calcul basique du rendement estimé (à adapter selon la logique métier)
    IF v_coefficient_kc IS NOT NULL THEN
        v_rendement_estime := v_superficie * v_coefficient_kc * 100; -- Exemple de calcul
    ELSE
        v_rendement_estime := v_superficie * 50; -- Valeur par défaut
    END IF;
    
    RETURN ROUND(v_rendement_estime, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
END CALCULER_RENDEMENT_PREVU;
