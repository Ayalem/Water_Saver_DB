CREATE OR REPLACE PROCEDURE update_statut_user(
    p_user_id  IN UTILISATEUR.user_id%TYPE,
    p_statut   IN UTILISATEUR.statut%TYPE
)
IS
BEGIN
    check_user_exists(p_user_id => p_user_id);

    -- Mise à jour du statut + date modification
    UPDATE UTILISATEUR
    SET statut              = p_statut,
        date_modification   = SYSTIMESTAMP
    WHERE user_id = p_user_id;

    COMMIT;

   
    DBMS_OUTPUT.PUT_LINE('Statut mis à jour pour user_id=' || p_user_id ||
                         ' → nouveau statut : ' || p_statut);

EXCEPTION


    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20022, 'Conflit de données (clé dupliquée).');

    WHEN VALUE_ERROR THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20023, 'Type ou valeur incorrect(e) pour le statut.');

    WHEN OTHERS THEN
        ROLLBACK;

        -- Si une erreur personnalisée a déjà été levée (entre -20999 et -20000)
        IF SQLCODE BETWEEN -20999 AND -20000 THEN
            RAISE;
        END IF;

        RAISE_APPLICATION_ERROR(-20029,
            'Erreur lors de la mise à jour du statut : ' || SQLERRM);
END;
/
