-- 3. PRC_NOTIFIER_AGRICULTEUR 
CREATE OR REPLACE PROCEDURE PRC_NOTIFIER_AGRICULTEUR (
    p_parcelle_id       IN NUMBER,
    p_type_notification IN VARCHAR2,
    p_message           IN VARCHAR2,
    p_alerte_id         IN NUMBER DEFAULT NULL
)
IS
    v_agriculteur_id NUMBER;
BEGIN
    SELECT u.id_user
    INTO v_agriculteur_id
    FROM UTILISATEUR u
    JOIN CHAMP c ON u.id_user = c.id_user
    JOIN PARCELLE p ON c.id_champ = p.id_champ
    WHERE p.id_parcelle = p_parcelle_id
      AND u.profession = 'AGRICULTEUR';

    PRC_AJOUTER_NOTIFICATION (
        p_user_id           => v_agriculteur_id,
        p_alerte_id         => p_alerte_id,
        p_type_notification => p_type_notification,
        p_message           => p_message
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        PRC_NOTIFIER_ADMIN(p_type_notification => 'SYSTEME', p_message => 'Avertissement : Alerte sans agriculteur valide sur parcelle ' || p_parcelle_id, p_alerte_id => p_alerte_id);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20021, 'Erreur lors de la notification de l''agriculteur: ' || SQLERRM);
END PRC_NOTIFIER_AGRICULTEUR;

