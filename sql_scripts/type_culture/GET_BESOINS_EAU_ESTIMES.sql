CREATE OR REPLACE FUNCTION GET_BESOINS_EAU_ESTIMES(
    p_type_culture_id IN NUMBER,
    p_stade_croissance IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER
IS
    v_coefficient_kc NUMBER(3,2);
    v_besoins_ea NUMBER(10,2);
BEGIN
    -- Récupérer le coefficient cultural
    SELECT coefficient_cultural_kc
    INTO v_coefficient_kc
    FROM TYPE_CULTURE
    WHERE type_culture_id = p_type_culture_id;
    
    -- Calcul des besoins en eau basé sur le coefficient Kc
    -- Formule simplifiée: Besoins = Kc * Évapotranspiration de référence
    -- Ici, on utilise une valeur d'ET0 fixe pour l'exemple (5mm/jour)
    IF p_stade_croissance = 'SEMIS' THEN
        v_besoins_ea := v_coefficient_kc * 4 * 0.8; -- Réduction pour semis
    ELSIF p_stade_croissance = 'FLORAISON' THEN
        v_besoins_ea := v_coefficient_kc * 5 * 1.2; -- Augmentation pour floraison
    ELSIF p_stade_croissance = 'MATURATION' THEN
        v_besoins_ea := v_coefficient_kc * 5 * 0.9; -- Réduction pour maturation
    ELSE
        v_besoins_ea := v_coefficient_kc * 5; -- Valeur standard
    END IF;
    
    RETURN ROUND(v_besoins_ea, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
END GET_BESOINS_EAU_ESTIMES;
/
