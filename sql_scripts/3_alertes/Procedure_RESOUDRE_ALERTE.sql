-- PRC_RESOUDRE_ALERTE
-- Utilisée pour marquer une alerte comme résolue (UPDATE).
CREATE OR REPLACE PROCEDURE PRC_RESOUDRE_ALERTE (
    p_alerte_id             IN NUMBER,
    p_resolu_par_user_id    IN NUMBER
)
IS
BEGIN
    UPDATE ALERTE
    SET statut = 'RESOLUE',
        date_resolution = SYSTIMESTAMP,
        resolu_par = p_resolu_par_user_id,
        duree_minutes = ROUND((SYSTIMESTAMP - date_detection) * 24 * 60) -- Calcul crucial
    WHERE id_alerte = p_alerte_id
      AND statut != 'RESOLUE'; 

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20041, 'Erreur lors de la résolution de l''alerte: ' || SQLERRM);
END PRC_RESOUDRE_ALERTE;

