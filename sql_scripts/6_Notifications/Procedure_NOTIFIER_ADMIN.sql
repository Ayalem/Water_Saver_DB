-- PRC_NOTIFIER_ADMIN (MODIFIÉ pour un seul administrateur)
-- Rôle : Envoie une notification à l'unique utilisateur ayant le rôle 'ADMINISTRATEUR'.
CREATE OR REPLACE PROCEDURE PRC_NOTIFIER_ADMIN (
    p_type_notification IN VARCHAR2,
    p_message           IN VARCHAR2,
    p_alerte_id         IN NUMBER DEFAULT NULL,
    p_intervention_id   IN NUMBER DEFAULT NULL
)
IS
    v_admin_user_id NUMBER;
BEGIN
    -- 1. Chercher l'ID de l'administrateur unique (le premier trouvé)
    SELECT id_user
    INTO v_admin_user_id
    FROM UTILISATEUR
    WHERE profession = 'ADMINISTRATEUR' AND statut = 'ACTIF'
    FETCH FIRST 1 ROWS ONLY; -- On prend la première ligne, assumant qu'il n'y en a qu'une.

    -- 2. Notifier l'administrateur unique
    PRC_AJOUTER_NOTIFICATION (
        p_user_id           => v_admin_user_id,
        p_alerte_id         => p_alerte_id,
        p_intervention_id   => p_intervention_id,
        p_type_notification => p_type_notification,
        p_message           => p_message
    );
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Erreur système si l'administrateur n'existe pas ou n'est pas actif
        RAISE_APPLICATION_ERROR(-20007, 'ERREUR SYSTÈME : Aucun administrateur actif trouvé pour recevoir la notification.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Erreur lors de la notification de l''administrateur: ' || SQLERRM);
END PRC_NOTIFIER_ADMIN;

