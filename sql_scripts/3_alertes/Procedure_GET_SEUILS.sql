--  PRC_GET_SEUILS 
CREATE OR REPLACE PROCEDURE PRC_GET_SEUILS (
    p_parcelle_id IN NUMBER,
    p_type_mesure IN VARCHAR2,
    p_seuil_min   OUT NUMBER, 
    p_seuil_max   OUT NUMBER  
)
IS
    v_type_culture VARCHAR2(50);
BEGIN
    SELECT culture INTO v_type_culture
    FROM PARCELLE
    WHERE id_parcelle = p_parcelle_id;

    SELECT sc.seuil_min, sc.seuil_max
    INTO p_seuil_min, p_seuil_max
    FROM SEUIL_CULTURE sc
    WHERE sc.type_seuil = p_type_mesure
    -- Le lien exact avec la culture doit être vérifié dans votre schéma (assumé par le nom ou id de culture)
    AND sc.culture = v_type_culture; 
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_seuil_min := NULL; 
        p_seuil_max := NULL; 
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20050, 'Erreur de récupération des seuils: ' || SQLERRM);
END PRC_GET_SEUILS;

