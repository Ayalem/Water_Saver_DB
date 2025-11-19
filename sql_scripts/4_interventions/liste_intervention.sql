CREATE OR REPLACE VIEW intervention_en_attente AS
SELECT *
FROM INTERVENTION
WHERE statut ='EN_ATTENTE';
ORDER BY date_creation;
