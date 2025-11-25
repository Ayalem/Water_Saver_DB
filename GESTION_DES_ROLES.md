# 🔐 Gestion des Rôles - Water Saver DB

## Vue d'ensemble

Ce document explique comment le contrôle d'accès basé sur les rôles (RBAC) est implémenté dans l'application Water Saver DB, à la fois au niveau de la base de données et de l'application.

---

## 📊 Hiérarchie des Rôles

| Rôle | Niveau | Permissions Principales |
|------|--------|------------------------|
| **ADMIN** | 4 | Accès complet, gestion des utilisateurs, types de culture |
| **INSPECTEUR** | 3 | Lecture seule sur toutes les données |
| **TECHNICIEN** | 2 | Gestion des interventions, maintenance des capteurs |
| **AGRICULTEUR** | 1 | Gestion de ses propres champs et parcelles |

---

## 🗄️ Sécurité au Niveau Base de Données

### 1. Rôles Oracle Créés

Fichier: [`sql_scripts/1_creation_bd/roles.sql`](file:///Users/ayalemzouri/start/Water_Saver_DB/sql_scripts/1_creation_bd/roles.sql)

```sql
CREATE ROLE AGRICULTEUR_ROLE;
CREATE ROLE TECHNICIEN_ROLE;
CREATE ROLE INSPECTEUR_ROLE;
CREATE ROLE ADMINISTRATEUR_ROLE;
```

### 2. Vues Utilisées pour la Sécurité

Fichier: [`sql_scripts/create_views.sql`](file:///Users/ayalemzouri/start/Water_Saver_DB/sql_scripts/create_views.sql)

**Vues créées:**
- ✅ `V_CHAMP_DETAILS` - Détails des champs avec propriétaire
- ✅ `V_PARCELLE_DETAILS` - Détails des parcelles avec champ
- ✅ `V_ALERTE_DETAILS` - Alertes avec contexte complet
- ✅ `V_INTERVENTION_DETAILS` - Interventions avec technicien assigné
- ✅ `V_RAPPORT_SUMMARY` - Résumés des rapports
- ✅ `V_NOTIFICATION_DETAILS` - Notifications avec contexte
- ✅ `V_CAPTEUR_STATUS` - État des capteurs
- ✅ `V_USER_DASHBOARD` - Tableau de bord utilisateur

**Problème identifié:** ❌ Les vues sont créées mais **PAS utilisées dans les routes backend**

### 3. Procédures Stockées pour RBAC

Fichier: [`sql_scripts/create_role_procedures.sql`](file:///Users/ayalemzouri/start/Water_Saver_DB/sql_scripts/create_role_procedures.sql)

**Procédures créées:**
- ✅ `voir_notification(p_user_id, p_notification_id)` - Vérifie propriété
- ✅ `voir_notifications(p_user_id)` - Liste notifications utilisateur
- ✅ `voir_alertes_agriculteur(p_user_id)` - Alertes de l'agriculteur
- ✅ `voir_interventions(p_user_id, p_role)` - Interventions filtrées par rôle
- ✅ `ajouter_parcelle(...)` - Vérifie propriété du champ
- ✅ `modifier_parcelle(...)` - Vérifie propriété
- ✅ `desactiver_parcelle(...)` - Vérifie propriété
- ✅ `ajouter_type_culture(...)` - **ADMIN uniquement**
- ✅ `update_intervention_technicien(...)` - Vérifie assignation

**Problème identifié:** ❌ Ces procédures sont créées mais **PAS toutes utilisées dans les routes**

### 4. Grants de Permissions

Dans [`roles.sql`](file:///Users/ayalemzouri/start/Water_Saver_DB/sql_scripts/1_creation_bd/roles.sql):

```sql
-- AGRICULTEUR - Accès limité via vues et procédures
GRANT SELECT ON V_CHAMP_DETAILS TO AGRICULTEUR_ROLE;
GRANT SELECT ON V_PARCELLE_DETAILS TO AGRICULTEUR_ROLE;
GRANT EXECUTE ON ajouter_parcelle TO AGRICULTEUR_ROLE;
GRANT EXECUTE ON modifier_parcelle TO AGRICULTEUR_ROLE;

-- TECHNICIEN - Gestion interventions et capteurs
GRANT EXECUTE ON assigner_intervention TO TECHNICIEN_ROLE;
GRANT EXECUTE ON terminer_intervention TO TECHNICIEN_ROLE;
GRANT EXECUTE ON installer_capteur TO TECHNICIEN_ROLE;
GRANT EXECUTE ON maintenance_capteur TO TECHNICIEN_ROLE;

-- INSPECTEUR - Lecture seule
GRANT SELECT ON V_CHAMP_DETAILS TO INSPECTEUR_ROLE;
GRANT SELECT ON V_INTERVENTION_DETAILS TO INSPECTEUR_ROLE;
GRANT SELECT ON V_RAPPORT_SUMMARY TO INSPECTEUR_ROLE;

-- ADMIN - Accès complet
GRANT ALL PRIVILEGES ON UTILISATEUR TO ADMINISTRATEUR_ROLE;
GRANT EXECUTE ON ajouter_type_culture TO ADMINISTRATEUR_ROLE;
GRANT EXECUTE ON update_statut_user TO ADMINISTRATEUR_ROLE;
```

---

## 🔧 Sécurité au Niveau Application

### 1. Décorateurs Python

Fichier: [`backend/auth.py`](file:///Users/ayalemzouri/start/Water_Saver_DB/backend/auth.py)

```python
@login_required  # Vérifie que l'utilisateur est connecté
@role_required('ADMIN', 'TECHNICIEN')  # Vérifie le rôle
```

### 2. Implémentation Actuelle par Route

#### ✅ Routes Correctement Sécurisées

**Auth Routes** ([`auth_routes.py`](file:///Users/ayalemzouri/start/Water_Saver_DB/backend/routes/auth_routes.py)):
```python
@auth_bp.route('/users/<int:user_id>/status', methods=['PUT'])
@login_required
@role_required('ADMIN')  # ✅ ADMIN uniquement
def update_user_status(user_id):
    # Utilise la procédure update_statut_user
```

**Capteur Routes** ([`capteur_routes.py`](file:///Users/ayalemzouri/start/Water_Saver_DB/backend/routes/capteur_routes.py)):
```python
@capteur_bp.route('/<int:capteur_id>/maintenance', methods=['POST'])
@login_required
@role_required('TECHNICIEN', 'ADMIN')  # ✅ TECHNICIEN/ADMIN
def maintenance_capteur_route(capteur_id):
    # Utilise la procédure maintenance_capteur
```

#### ❌ Routes avec Problèmes

**Type Culture Routes** ([`type_culture_routes.py`](file:///Users/ayalemzouri/start/Water_Saver_DB/backend/routes/type_culture_routes.py)):

**PROBLÈME 1:** AGRICULTEUR peut créer des types de culture
```python
@type_culture_bp.route('', methods=['POST'])
@login_required
@role_required('ADMIN', 'AGRICULTEUR')  # ❌ AGRICULTEUR ne devrait PAS pouvoir
```

**PROBLÈME 2:** Utilise des requêtes SQL directes au lieu de procédures
```python
# ❌ Requête directe au lieu de procédure
cursor.execute("""
    UPDATE TYPE_CULTURE 
    SET nom = :nom, description = :description
    WHERE type_culture_id = :id
""", {...})
```

**Champ Routes** ([`champ_routes.py`](file:///Users/ayalemzouri/start/Water_Saver_DB/backend/routes/champ_routes.py)):

**PROBLÈME:** N'utilise PAS les vues
```python
# ❌ Requête directe au lieu de V_CHAMP_DETAILS
cursor.execute("""
    SELECT champ_id, nom, superficie, type_champs, region, statut
    FROM CHAMP
    WHERE user_id = :user_id
""", {'user_id': user_id})
```

**DEVRAIT ÊTRE:**
```python
# ✅ Utiliser la vue
cursor.execute("""
    SELECT * FROM V_CHAMP_DETAILS
    WHERE user_id = :user_id
""", {'user_id': user_id})
```

---

## 🐛 Problèmes Identifiés

### 1. Vues Non Utilisées

| Vue | Utilisée? | Devrait Remplacer |
|-----|-----------|-------------------|
| V_CHAMP_DETAILS | ❌ Non | Requêtes directes sur CHAMP |
| V_PARCELLE_DETAILS | ❌ Non | Requêtes directes sur PARCELLE |
| V_INTERVENTION_DETAILS | ❌ Non | Requêtes directes sur INTERVENTION |
| V_ALERTE_DETAILS | ❌ Non | Requêtes directes sur ALERTE |

### 2. Procédures Non Utilisées

| Procédure | Utilisée? | Route Concernée |
|-----------|-----------|-----------------|
| voir_alertes_agriculteur | ❌ Non | alerte_routes.py |
| voir_interventions | ❌ Non | intervention_routes.py |
| modifier_parcelle | ❌ Non | parcelle_routes.py |
| desactiver_parcelle | ❌ Non | parcelle_routes.py |

### 3. Permissions Incorrectes

| Route | Problème | Correction Nécessaire |
|-------|----------|----------------------|
| POST /api/type-cultures | AGRICULTEUR peut créer | Retirer AGRICULTEUR |
| PUT /api/type-cultures/:id | AGRICULTEUR peut modifier | ADMIN uniquement |
| DELETE /api/type-cultures/:id | Pas de vérification | ADMIN uniquement |

---

## ✅ Corrections Nécessaires

### 1. Corriger Type Culture Routes

```python
# Création - ADMIN uniquement
@type_culture_bp.route('', methods=['POST'])
@login_required
@role_required('ADMIN')  # ✅ Correction

# Modification - ADMIN uniquement  
@type_culture_bp.route('/<int:type_culture_id>', methods=['PUT'])
@login_required
@role_required('ADMIN')  # ✅ Correction

# Suppression - ADMIN uniquement
@type_culture_bp.route('/<int:type_culture_id>', methods=['DELETE'])
@login_required
@role_required('ADMIN')  # ✅ Correction
```

### 2. Utiliser les Vues

```python
# Dans champ_routes.py
def get_champs():
    # ✅ Utiliser la vue au lieu de requête directe
    result = execute_query("""
        SELECT * FROM V_CHAMP_DETAILS
        WHERE user_id = :user_id
    """, {'user_id': user_id})
```

### 3. Utiliser les Procédures

```python
# Dans alerte_routes.py
@alerte_bp.route('', methods=['GET'])
@login_required
def get_alertes():
    user = get_current_user()
    if user['role'] == 'AGRICULTEUR':
        # ✅ Utiliser la procédure
        cursor.callproc('voir_alertes_agriculteur', [user['user_id']])
```

---

## 📋 Résumé de l'Implémentation Actuelle

### ✅ Ce qui Fonctionne

1. **Authentification** - JWT tokens, sessions
2. **Décorateurs de rôle** - `@role_required` appliqué
3. **Procédures SQL** - Créées et certaines utilisées
4. **Vues SQL** - Créées avec permissions correctes
5. **Grants** - Permissions Oracle configurées

### ❌ Ce qui Manque

1. **Utilisation des vues** - Routes utilisent des requêtes directes
2. **Utilisation des procédures** - Beaucoup de procédures ignorées
3. **Permissions Type Culture** - AGRICULTEUR a trop de droits
4. **Cohérence** - Mix de procédures et requêtes directes

---

## 🎯 Recommandations

### Priorité 1: Sécurité Critique
- [ ] Retirer AGRICULTEUR des permissions Type Culture
- [ ] Utiliser `ajouter_type_culture` procédure (ADMIN only)

### Priorité 2: Utiliser les Vues
- [ ] Remplacer toutes les requêtes `SELECT * FROM CHAMP` par `V_CHAMP_DETAILS`
- [ ] Remplacer toutes les requêtes `SELECT * FROM PARCELLE` par `V_PARCELLE_DETAILS`
- [ ] Remplacer toutes les requêtes `SELECT * FROM INTERVENTION` par `V_INTERVENTION_DETAILS`

### Priorité 3: Utiliser les Procédures
- [ ] `voir_alertes_agriculteur` dans alerte_routes.py
- [ ] `voir_interventions` dans intervention_routes.py
- [ ] `modifier_parcelle` dans parcelle_routes.py
- [ ] `desactiver_parcelle` dans parcelle_routes.py

---

## 📝 Notes

- **Sécurité en profondeur**: L'application utilise 2 couches (DB + App) mais pas de manière cohérente
- **Vues vs Procédures**: Les vues sont pour la lecture, les procédures pour les modifications
- **Performance**: Les vues peuvent améliorer les performances avec des données pré-jointes
- **Maintenance**: Utiliser les vues/procédures centralise la logique métier

---

*Document créé le: 2025-11-25*  
*Dernière mise à jour: 2025-11-25*
