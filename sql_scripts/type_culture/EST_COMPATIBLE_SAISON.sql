CREATE OR REPLACE FUNCTION EST_COMPATIBLE_SAISON(
    p_type_culture_id IN NUMBER,
    p_mois IN NUMBER
) RETURN VARCHAR2
IS
    v_categorie VARCHAR2(100);
BEGIN
    -- On récupère la catégorie du type de culture
    SELECT categorie
    INTO v_categorie
    FROM TYPE_CULTURE
    WHERE type_culture_id = p_type_culture_id;

    -- Exemple : cultures d'été compatibles avec avril → septembre
    IF v_categorie = 'ETE' AND p_mois BETWEEN 4 AND 9 THEN
        RETURN 'OUI';

    -- Cultures d'hiver compatibles avec octobre → mars
    ELSIF v_categorie = 'HIVER' AND (p_mois IN (10,11,12,1,2,3)) THEN
        RETURN 'OUI';

    ELSE
        RETURN 'NON';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'INCONNU';
END EST_COMPATIBLE_SAISON;
/
