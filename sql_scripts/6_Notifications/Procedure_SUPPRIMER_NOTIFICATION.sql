-- PRC_SUPPRIMER_NOTIFICATION
-- Rôle : Supprime définitivement une notification de la table.
-- Paramètre : ID de la notification à supprimer.
CREATE OR REPLACE PROCEDURE PRC_SUPPRIMER_NOTIFICATION (
    p_notification_id IN NUMBER
)
IS
BEGIN
    DELETE FROM NOTIFICATION
    WHERE id_notification = p_notification_id;

    -- Vérification si la suppression a réussi (optionnel)
    IF SQL%ROWCOUNT = 0 THEN
        -- Si l'ID n'existe pas, on peut générer une erreur ou un avertissement.
        DBMS_OUTPUT.PUT_LINE('Avertissement : Aucune notification trouvée pour l''ID ' || p_notification_id || ' à supprimer.');
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Erreur lors de la suppression de la notification: ' || SQLERRM);
END PRC_SUPPRIMER_NOTIFICATION;
/
