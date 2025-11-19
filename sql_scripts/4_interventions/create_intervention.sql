CREATE OR REPLACE TRIGGER trg_create_intervention_on_alerte
AFTER INSERT ON ALERTE
FOR EACH ROW 
BEGIN
    INSERT INTO INTERVENTION (
         alerte_id,
         parcelle_id,
         capteur_id,
         type_intervention,
         priorité,
         statut,
         description)
         VALUES (
            :NEW.alerte_id,
            :NEW.parcelle_id,
            :NEW.capteur_id,
            'INSPECTEUR',
            'HAUTE',
            'EN_ATTENTE',
            'Intervention générée automatiquement suite à une alerte.');
notifier_admin('Nouvelle alerte #'|| :NEW.alerte_id || 'intervention doit être assignée.');
END;


