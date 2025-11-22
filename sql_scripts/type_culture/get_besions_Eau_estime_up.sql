CREATE OR REPLACE FUNCTION GET_BESOINS_EAU_ESTIMES(
    p_type_culture_id IN NUMBER,
    p_stade_croissance IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER
IS
    v_coefficient_kc NUMBER(10,4);
    v_besoins_ea NUMBER(10,2);
BEGIN
    -- Récupérer le coefficient KC
    SELECT coefficient_cultural_kc
    INTO v_coefficient_kc
    FROM TYPE_CULTURE
    WHERE type_culture_id = p_type_culture_id;
    
    -- Calcul selon le stade
    IF UPPER(p_stade_croissance) = 'SEMIS' THEN
        v_besoins_ea := v_coefficient_kc * 4 * 0.8;
    ELSIF UPPER(p_stade_croissance) = 'FLORAISON' THEN
        v_besoins_ea := v_coefficient_kc * 5 * 1.2;
    ELSIF UPPER(p_stade_croissance) = 'MATURATION' THEN
        v_besoins_ea := v_coefficient_kc * 5 * 0.9;
    ELSE
        v_besoins_ea := v_coefficient_kc * 5;
    END IF;
    
    RETURN ROUND(v_besoins_ea, 2);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20050,
            'Type de culture introuvable : ' || p_type_culture_id);

    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20051,
            'Erreur interne dans GET_BESOINS_EAU_ESTIMES : ' || SQLERRM);
END GET_BESOINS_EAU_ESTIMES;
/
