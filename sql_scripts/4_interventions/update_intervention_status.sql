CREATE OR REPLACE TRIGGER trg_update_intervention_on_notif_read
AFTER UPDATE OF lu ON NOTIFICATION
FOR EACH ROW 
WHEN (NEW.LU='OUI')
BEGIN
   IF :NEW.intervention_id IS NOT NULL THEN
      UPDATE INTERVENTION 
      SET statut='EN_COURS',
          date_debut =SYSDATE
      WHERE intervention_id=:NEW.intervention_id;
  END IF;
END;

