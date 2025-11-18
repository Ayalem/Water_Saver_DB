CREATE OR REPLACE VIEW stats_intervention_technicien AS
SELECT technicien_id 
        COUNT( * ) AS total_interventions,
        SUM(CASE WHEN statut ='TERMINE' THEN 1 END) AS terminees,
        SUM(CASE WHEN statut ='EN_COURS' THEN 1 END) AS en_cours,
FROM INTERVENTION
GROUP BY technicien_id;
        
