CREATE OR REPLACE PROCEDURE PRC_GENERER_RAPPORT_PERIODIQUE (
    p_frequence         IN VARCHAR2, -- 'SEMAINE', 'MOIS', 'ANNEE'
    p_user_id_systeme   IN NUMBER    -- L'ID de l'Admin ou du système qui génère le rapport
)
IS
    -- Variables pour définir la période passée
    v_date_debut DATE;
    v_date_fin DATE;
    v_type_rapport VARCHAR2(50);
    
    -- Variables de synthèse (Les mêmes KPI que précédemment)
    v_nb_parcelles              NUMBER;
    v_nb_capteurs               NUMBER;
    v_nb_alertes_total          NUMBER;
    v_nb_alertes_critiques      NUMBER;
    v_nb_interventions_terminees NUMBER;
    v_duree_moyenne_resolution  NUMBER(10,2);
    
    -- Contenu au format JSON
    v_json_report               CLOB;

    -- Curseur pour itérer sur chaque champ
    CURSOR c_champs IS
        SELECT champ_id FROM CHAMP WHERE statut = 'ACTIF';

BEGIN
    -- ÉTAPE 1 : Détermination des Dates de la Période PASSÉE
    CASE p_frequence
        WHEN 'SEMAINE' THEN
            -- Calcule la semaine dernière (Lundi au Dimanche)
            v_date_fin := TRUNC(SYSDATE, 'IW'); -- Début de cette semaine
            v_date_debut := v_date_fin - 7;    -- Début de la semaine dernière
            v_type_rapport := 'RAPPORT_HEBDO';
        WHEN 'MOIS' THEN
            -- Calcule le mois dernier (Du 1er au dernier jour du mois précédent)
            v_date_fin := TRUNC(SYSDATE, 'MM'); -- Début de ce mois
            v_date_debut := ADD_MONTHS(v_date_fin, -1); -- Début du mois précédent
            v_type_rapport := 'RAPPORT_MENSUEL';
        WHEN 'ANNEE' THEN
            -- Calcule l'année dernière (Du 1er Jan au 31 Déc)
            v_date_fin := TRUNC(SYSDATE, 'YYYY'); -- Début de cette année
            v_date_debut := ADD_MONTHS(v_date_fin, -12); -- Début de l'année précédente
            v_type_rapport := 'RAPPORT_ANNUEL';
        ELSE
            RAISE_APPLICATION_ERROR(-20091, 'Fréquence de rapport non valide.');
    END CASE;

    -- ÉTAPE 2 : Boucle sur TOUS les champs actifs pour générer un rapport pour CHACUN
    FOR r_champ IN c_champs LOOP
        
        -- Réinitialiser les variables pour chaque champ
        v_nb_parcelles := 0; v_nb_capteurs := 0;
        v_nb_alertes_total := 0; v_nb_alertes_critiques := 0;
        v_nb_interventions_terminees := 0; v_duree_moyenne_resolution := 0;

        -- 2.1. Statistiques d'Inventaire
        SELECT COUNT(DISTINCT P.parcelle_id), COUNT(C.capteur_id)
        INTO v_nb_parcelles, v_nb_capteurs
        FROM PARCELLE P
        LEFT JOIN CAPTEUR C ON C.parcelle_id = P.parcelle_id
        WHERE P.champ_id = r_champ.champ_id;

        -- 2.2. Statistiques de Performance
        -- Calcul des Alertes, Critiques, et Durée Moyenne
        SELECT COUNT(A.alerte_id),
               SUM(CASE WHEN A.severite = 'CRITIQUE' THEN 1 ELSE 0 END),
               AVG(A.duree_minutes)
        INTO v_nb_alertes_total, v_nb_alertes_critiques, v_duree_moyenne_resolution
        FROM ALERTE A
        JOIN PARCELLE P ON P.parcelle_id = A.parcelle_id
        WHERE P.champ_id = r_champ.champ_id
          AND A.date_detection BETWEEN v_date_debut AND v_date_fin;
          
        -- Calcul des Interventions Terminées
        SELECT COUNT(I.intervention_id)
        INTO v_nb_interventions_terminees
        FROM INTERVENTION I
        JOIN PARCELLE P ON P.parcelle_id = I.parcelle_id
        WHERE P.champ_id = r_champ.champ_id
          AND I.statut = 'TERMINE'
          AND I.date_fin BETWEEN v_date_debut AND v_date_fin;

        -- 2.3. Sécurité et Construction JSON
        IF v_duree_moyenne_resolution IS NULL THEN v_duree_moyenne_resolution := 0; END IF;

        v_json_report := JSON_OBJECT(
            'frequence_rapport'     VALUE p_frequence,
            'periode_debut'         VALUE TO_CHAR(v_date_debut, 'YYYY-MM-DD'),
            'periode_fin'           VALUE TO_CHAR(v_date_fin, 'YYYY-MM-DD'),
            'statistiques_audit'    VALUE JSON_OBJECT(
                'nb_parcelles'      VALUE v_nb_parcelles,
                'nb_capteurs_installes' VALUE v_nb_capteurs,
                'nb_alertes_total'  VALUE v_nb_alertes_total,
                'nb_alertes_critiques' VALUE v_nb_alertes_critiques,
                'nb_interventions_terminees' VALUE v_nb_interventions_terminees,
                'duree_moyenne_resolution_min' VALUE v_duree_moyenne_resolution
            )
        );

        -- 2.4. Insertion (Un rapport par champ)
        INSERT INTO RAPPORT (
            user_id, champ_id, type_rapport, date_debut, date_fin, contenu, date_generation
        )
        VALUES (
            p_user_id_systeme, r_champ.champ_id, v_type_rapport, v_date_debut, v_date_fin, v_json_report, SYSTIMESTAMP
        );
        
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20092, 'Erreur dans la génération des rapports périodiques: ' || SQLERRM);
END PRC_GENERER_RAPPORT_PERIODIQUE;
/
