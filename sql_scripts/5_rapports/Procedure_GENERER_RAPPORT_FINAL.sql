CREATE OR REPLACE PROCEDURE PRC_GENERER_RAPPORT_AUDIT_FINAL (
    p_user_id           IN NUMBER,    -- L'utilisateur qui demande le rapport
    p_champ_id          IN NUMBER,    -- Le champ à auditer
    p_type_rapport      IN VARCHAR2,  -- Ex: 'AUDIT_ADHOC'
    p_date_debut        IN DATE,
    p_date_fin          IN DATE
)
IS
    -- Déclaration des variables de synthèse
    v_nb_parcelles              NUMBER;
    v_nb_capteurs               NUMBER;
    v_nb_alertes_total          NUMBER;
    v_nb_alertes_critiques      NUMBER;
    v_nb_interventions_terminees NUMBER;
    v_duree_moyenne_resolution  NUMBER(10,2);
    
    -- Contenu au format JSON pour l'archivage
    v_json_report               CLOB;
BEGIN
    -- 1. Statistiques d'Inventaire (Basées sur le CHAMP)
    -- Compte les parcelles et les capteurs installés dans le champ
    SELECT COUNT(DISTINCT P.parcelle_id),
           COUNT(C.capteur_id)
    INTO v_nb_parcelles,
         v_nb_capteurs
    FROM PARCELLE P
    LEFT JOIN CAPTEUR C ON C.parcelle_id = P.parcelle_id
    WHERE P.champ_id = p_champ_id;

    -- 2. Statistiques d'Activité et Performance (Filtrées par DATE et CHAMP)
    
    -- a. Alertes (Total, Critiques, et Durée Moyenne de Résolution)
    SELECT COUNT(A.alerte_id),
           SUM(CASE WHEN A.severite = 'CRITIQUE' THEN 1 ELSE 0 END),
           AVG(A.duree_minutes)
    INTO v_nb_alertes_total,
         v_nb_alertes_critiques,
         v_duree_moyenne_resolution
    FROM ALERTE A
    JOIN PARCELLE P ON P.parcelle_id = A.parcelle_id
    WHERE P.champ_id = p_champ_id
      AND A.date_detection BETWEEN p_date_debut AND p_date_fin;
      
    -- b. Interventions Terminées
    SELECT COUNT(I.intervention_id)
    INTO v_nb_interventions_terminees
    FROM INTERVENTION I
    JOIN PARCELLE P ON P.parcelle_id = I.parcelle_id
    WHERE P.champ_id = p_champ_id
      AND I.statut = 'TERMINE'
      AND I.date_fin BETWEEN p_date_debut AND p_date_fin;

    -- Sécurité: s'assurer que la moyenne de durée n'est pas NULL si aucune alerte n'a été résolue.
    IF v_duree_moyenne_resolution IS NULL THEN v_duree_moyenne_resolution := 0; END IF;

    -- 3. Création du Contenu JSON (Archivage structuré)
    -- Utilise le format JSON pour stocker toutes les statistiques calculées
    v_json_report := JSON_OBJECT(
        'champ_id'              VALUE p_champ_id,
        'periode_debut'         VALUE TO_CHAR(p_date_debut, 'YYYY-MM-DD'),
        'periode_fin'           VALUE TO_CHAR(p_date_fin, 'YYYY-MM-DD'),
        'statistiques_audit'    VALUE JSON_OBJECT(
            'nb_parcelles'      VALUE v_nb_parcelles,
            'nb_capteurs_installes' VALUE v_nb_capteurs,
            'nb_alertes_total'  VALUE v_nb_alertes_total,
            'nb_alertes_critiques' VALUE v_nb_alertes_critiques,
            'nb_interventions_terminees' VALUE v_nb_interventions_terminees,
            'duree_moyenne_resolution_min' VALUE v_duree_moyenne_resolution
        )
    );

    -- 4. Insertion du Rapport Archivé dans la table RAPPORT
    INSERT INTO RAPPORT (
        user_id, champ_id, type_rapport, date_debut, date_fin, contenu, date_generation
    )
    VALUES (
        p_user_id, p_champ_id, p_type_rapport, p_date_debut, p_date_fin, v_json_report, SYSTIMESTAMP
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- Utilise le code d'erreur personnalisé
        RAISE_APPLICATION_ERROR(-20090, 'Erreur lors de la génération du rapport final: ' || SQLERRM);
END PRC_GENERER_RAPPORT_AUDIT_FINAL;

