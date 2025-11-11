-- PRC_MARQUER_LUE
-- Rôle : Met à jour le statut 'lue' à 'OUI' et enregistre la date de lecture.
-- Paramètres : ID de la notification à mettre à jour et ID de l'utilisateur pour la vérification.
CREATE OR REPLACE PROCEDURE PRC_MARQUER_LUE (
    p_notification_id IN NUMBER,
    p_user_id IN NUMBER 
)
IS
BEGIN
    UPDATE NOTIFICATION
    SET lue = 'OUI',
        date_lecture = SYSTIMESTAMP
    WHERE id_notification = p_notification_id -- ID de la notification
      AND id_user = p_user_id             -- Sécurité: L'utilisateur est bien le destinataire
      AND lue = 'NON';                     -- Ne modifie que si elle n'est pas déjà lue

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Erreur lors de la mise à jour du statut de lecture: ' || SQLERRM);
END PRC_MARQUER_LUE;
/
