CREATE OR REPLACE TRIGGER TRG_ALERTE_DUREE_RESOLUTION
BEFORE UPDATE OF statut ON ALERTE
FOR EACH ROW
WHEN (NEW.statut = 'RESOLUE' AND OLD.statut IN ('ACTIVE', 'EN_COURS') AND NEW.date_resolution IS NULL)
DECLARE
    v_duree_sec NUMBER;
BEGIN
    :NEW.date_resolution := SYSTIMESTAMP;
    
    -- Calcul de la durée en secondes
    v_duree_sec := (EXTRACT(DAY FROM (:NEW.date_resolution - :OLD.date_detection)) * 24 * 60 * 60) +
                   (EXTRACT(HOUR FROM (:NEW.date_resolution - :OLD.date_detection)) * 60 * 60) +
                   (EXTRACT(MINUTE FROM (:NEW.date_resolution - :OLD.date_detection)) * 60) +
                   (EXTRACT(SECOND FROM (:NEW.date_resolution - :OLD.date_detection)));
                   
    :NEW.duree_minutes := ROUND(v_duree_sec / 60);
    
END TRG_ALERTE_DUREE_RESOLUTION;

