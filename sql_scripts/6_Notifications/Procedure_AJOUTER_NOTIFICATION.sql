-- 1. PRC_AJOUTER_NOTIFICATION (La Brique de Base)
CREATE OR REPLACE PROCEDURE PRC_AJOUTER_NOTIFICATION (
    p_user_id             IN NUMBER,
    p_alerte_id           IN NUMBER DEFAULT NULL,
    p_intervention_id     IN NUMBER DEFAULT NULL,
    p_type_notification   IN VARCHAR2,
    p_message             IN VARCHAR2
)
IS
BEGIN
    INSERT INTO NOTIFICATION (
        id_user, id_alerte, id_intervention, type_notification, message, lue, date_envoi
    )
    VALUES (
        p_user_id, p_alerte_id, p_intervention_id, p_type_notification, p_message, 'NON', SYSTIMESTAMP
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Erreur lors de l''ajout de la notification: ' || SQLERRM);
END PRC_AJOUTER_NOTIFICATION;

