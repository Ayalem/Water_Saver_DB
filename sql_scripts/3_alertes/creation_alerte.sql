-- 5. PRC_CREER_ALERTE
CREATE OR REPLACE PROCEDURE PRC_CREER_ALERTE (
    p_mesure_id             IN NUMBER,
    p_parcelle_id           IN NUMBER,
    p_type_alerte           IN VARCHAR2,
    p_severite              IN VARCHAR2,
    p_valeur_mesuree        IN NUMBER,
    p_valeur_seuil          IN NUMBER,
    p_pourcentage_depassement IN NUMBER
)
IS
BEGIN
    INSERT INTO ALERTE (
        id_mesure, id_parcelle, type_alerte, severite, description,
        valeur_mesuree, valeur_seuil, pourcentage_depassement, statut
    )
    VALUES (
        p_mesure_id, p_parcelle_id, p_type_alerte, p_severite,
        'Dépassement du seuil par ' || p_pourcentage_depassement || '%',
        p_valeur_mesuree, p_valeur_seuil, p_pourcentage_depassement, 'OUVERT'
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20040, 'Erreur lors de la création de l''alerte: ' || SQLERRM);
END PRC_CREER_ALERTE;

