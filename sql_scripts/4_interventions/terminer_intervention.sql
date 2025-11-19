CREATE OR REPLACE PROCEDURE terminer_intervention(
    p_intervention_id NUMBER,
    p_cout NUMBER,
    p_notes CLOB)
IS 
BEGIN
    UPDATE INTERVENTION 
    SET statut ='TERMINE',
        date_fin =SYSDATE,
        duree_minutes=ROUND((SYSDATE-date_debut)*24*60),
        cout_intervention=p_cout,
        notes            p_notes
    WHERE intervention_id=p_intervention_id;
END;

