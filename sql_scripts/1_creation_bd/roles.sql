-- ============================================================================
-- Database Roles and Permissions - SECURE VERSION
-- ============================================================================
-- This script creates roles with NO direct table access
-- Users can ONLY access data through:
--   1. VIEWS (which show filtered data)
--   2. PROCEDURES (which enforce row-level security)
-- This ensures each role only sees their own data
-- ============================================================================

CREATE ROLE AGRICULTEUR;
CREATE ROLE TECHNICIEN;
CREATE ROLE INSPECTEUR;
CREATE ROLE ADMINISTRATEUR;

-- ============================================================================
-- AGRICULTEUR Role
-- Can manage own champs/parcelles through procedures
-- Can view own data through filtered views
-- NO direct table access
-- ============================================================================

-- View permissions (views show only user's own data when used with procedures)
GRANT SELECT ON V_CHAMP_DETAILS TO AGRICULTEUR;
GRANT SELECT ON V_PARCELLE_DETAILS TO AGRICULTEUR;
GRANT SELECT ON V_ALERTE_DETAILS TO AGRICULTEUR;
GRANT SELECT ON V_NOTIFICATION_DETAILS TO AGRICULTEUR;
GRANT SELECT ON V_RAPPORT_SUMMARY TO AGRICULTEUR;
GRANT SELECT ON V_USER_DASHBOARD TO AGRICULTEUR;
GRANT SELECT ON V_INTERVENTION_DETAILS TO AGRICULTEUR;

-- Procedure permissions (procedures enforce ownership checks)
GRANT EXECUTE ON voir_interventions TO AGRICULTEUR;
GRANT EXECUTE ON voir_alertes_agriculteur TO AGRICULTEUR;
GRANT EXECUTE ON ajouter_parcelle TO AGRICULTEUR;
GRANT EXECUTE ON modifier_parcelle TO AGRICULTEUR;
GRANT EXECUTE ON desactiver_parcelle TO AGRICULTEUR;
GRANT EXECUTE ON ajouter_type_culture TO AGRICULTEUR;
GRANT EXECUTE ON voir_notification TO AGRICULTEUR;
GRANT EXECUTE ON voir_notifications TO AGRICULTEUR;

-- Minimal table access (only for TYPE_CULTURE lookup - no user data)
GRANT SELECT ON TYPE_CULTURE TO AGRICULTEUR;

-- ============================================================================
-- TECHNICIEN Role
-- Can view/update ONLY assigned interventions through procedures
-- Can view related data through filtered views
-- NO direct table access to user data
-- ============================================================================

-- View permissions (filtered to show only assigned work)
GRANT SELECT ON V_INTERVENTION_DETAILS TO TECHNICIEN;
GRANT SELECT ON V_ALERTE_DETAILS TO TECHNICIEN;
GRANT SELECT ON V_NOTIFICATION_DETAILS TO TECHNICIEN;
GRANT SELECT ON V_PARCELLE_DETAILS TO TECHNICIEN;
GRANT SELECT ON V_CHAMP_DETAILS TO TECHNICIEN;

-- Procedure permissions (procedures filter by technicien_id)
GRANT EXECUTE ON voir_interventions TO TECHNICIEN;
GRANT EXECUTE ON voir_notifications TO TECHNICIEN;
GRANT EXECUTE ON update_intervention_technicien TO TECHNICIEN;
GRANT EXECUTE ON terminer_intervention TO TECHNICIEN;

-- Minimal table access (only for lookups - no user data)
GRANT SELECT ON TYPE_CULTURE TO TECHNICIEN;

-- NO direct UPDATE on INTERVENTION - must use procedures only!
-- This enforces that TECHNICIEN can only update through procedures
-- which verify they own the intervention

-- ============================================================================
-- INSPECTEUR Role
-- Read-only access to all data through views
-- NO direct table access
-- NO procedures (read-only role)
-- ============================================================================

-- View permissions (read-only access to all views)
GRANT SELECT ON V_CHAMP_DETAILS TO INSPECTEUR;
GRANT SELECT ON V_PARCELLE_DETAILS TO INSPECTEUR;
GRANT SELECT ON V_ALERTE_DETAILS TO INSPECTEUR;
GRANT SELECT ON V_INTERVENTION_DETAILS TO INSPECTEUR;
GRANT SELECT ON V_RAPPORT_SUMMARY TO INSPECTEUR;
GRANT SELECT ON V_CAPTEUR_STATUS TO INSPECTEUR;
GRANT SELECT ON V_NOTIFICATION_DETAILS TO INSPECTEUR;

-- Table access (read-only for reference data)
GRANT SELECT ON TYPE_CULTURE TO INSPECTEUR;
GRANT SELECT ON SEUIL_CULTURE TO INSPECTEUR;

-- ============================================================================
-- ADMINISTRATEUR Role
-- Full access to everything
-- Can use both direct table access AND procedures
-- ============================================================================

-- Full table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON UTILISATEUR TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON CHAMP TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON TYPE_CULTURE TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON PARCELLE TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON SEUIL_CULTURE TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON INTERVENTION TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON RAPPORT TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON NOTIFICATION TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALERTE TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON CAPTEUR TO ADMINISTRATEUR;
GRANT SELECT, INSERT, UPDATE, DELETE ON MESURE TO ADMINISTRATEUR;

-- All view permissions
GRANT SELECT ON V_CHAMP_DETAILS TO ADMINISTRATEUR;
GRANT SELECT ON V_PARCELLE_DETAILS TO ADMINISTRATEUR;
GRANT SELECT ON V_ALERTE_DETAILS TO ADMINISTRATEUR;
GRANT SELECT ON V_INTERVENTION_DETAILS TO ADMINISTRATEUR;
GRANT SELECT ON V_RAPPORT_SUMMARY TO ADMINISTRATEUR;
GRANT SELECT ON V_NOTIFICATION_DETAILS TO ADMINISTRATEUR;
GRANT SELECT ON V_CAPTEUR_STATUS TO ADMINISTRATEUR;
GRANT SELECT ON V_USER_DASHBOARD TO ADMINISTRATEUR;

-- All procedure permissions
GRANT EXECUTE ON voir_notification TO ADMINISTRATEUR;
GRANT EXECUTE ON voir_notifications TO ADMINISTRATEUR;
GRANT EXECUTE ON voir_alertes_agriculteur TO ADMINISTRATEUR;
GRANT EXECUTE ON voir_interventions TO ADMINISTRATEUR;
GRANT EXECUTE ON ajouter_parcelle TO ADMINISTRATEUR;
GRANT EXECUTE ON modifier_parcelle TO ADMINISTRATEUR;
GRANT EXECUTE ON desactiver_parcelle TO ADMINISTRATEUR;
GRANT EXECUTE ON ajouter_type_culture TO ADMINISTRATEUR;
GRANT EXECUTE ON update_intervention_technicien TO ADMINISTRATEUR;
GRANT EXECUTE ON assigner_intervention TO ADMINISTRATEUR;
GRANT EXECUTE ON terminer_intervention TO ADMINISTRATEUR;

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 1. AGRICULTEUR: NO direct SELECT on INTERVENTION/NOTIFICATION tables
--    - Must use voir_interventions() procedure to see interventions on their parcelles
--    - Must use voir_notification() procedure to see their notifications
--
-- 2. TECHNICIEN: NO direct SELECT on INTERVENTION/NOTIFICATION tables
--    - Must use voir_interventions() procedure to see ONLY assigned interventions
--    - Must use voir_notifications() procedure to see their notifications
--    - Can UPDATE interventions but only through update_intervention_technicien()
--
-- 3. INSPECTEUR: Read-only through VIEWS only
--    - NO procedures (cannot modify data)
--    - Can see all data but cannot change anything
--
-- 4. ADMIN: Full access to everything
--    - Can use both direct table access and procedures
--    - No restrictions
-- ============================================================================

PROMPT
PROMPT ============================================================================
PROMPT Secure Roles and Permissions Created Successfully!
PROMPT - AGRICULTEUR: Views + Procedures only (own data)
PROMPT - TECHNICIEN: Views + Procedures only (assigned work)
PROMPT - INSPECTEUR: Views only (read-only)
PROMPT - ADMINISTRATEUR: Full access
PROMPT ============================================================================
