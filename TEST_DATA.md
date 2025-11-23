# Test Data for WaterSaver

## Sample Users for Testing

### 1. Agriculteur Test User
```json
{
  "email": "agriculteur@test.com",
  "password": "test123",
  "nom": "Dupont",
  "prenom": "Jean",
  "telephone": "0612345678",
  "role": "AGRICULTEUR",
  "region_affectation": "Casablanca"
}
```

### 2. Technicien Test User
```json
{
  "email": "technicien@test.com",
  "password": "test123",
  "nom": "Martin",
  "prenom": "Sophie",
  "telephone": "0623456789",
  "role": "TECHNICIEN",
  "region_affectation": "Rabat"
}
```

### 3. Inspecteur Test User
```json
{
  "email": "inspecteur@test.com",
  "password": "test123",
  "nom": "Bernard",
  "prenom": "Pierre",
  "telephone": "0634567890",
  "role": "INSPECTEUR",
  "region_affectation": "Marrakech"
}
```

### 4. Admin Test User
```json
{
  "email": "admin@test.com",
  "password": "admin123",
  "nom": "Admin",
  "prenom": "System",
  "telephone": "0645678901",
  "role": "ADMIN",
  "region_affectation": "Casablanca"
}
```

## cURL Commands to Create Test Users

```bash
# Create Agriculteur
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "agriculteur@test.com",
    "password": "test123",
    "nom": "Dupont",
    "prenom": "Jean",
    "telephone": "0612345678",
    "role": "AGRICULTEUR",
    "region_affectation": "Casablanca"
  }'

# Create Technicien
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "technicien@test.com",
    "password": "test123",
    "nom": "Martin",
    "prenom": "Sophie",
    "telephone": "0623456789",
    "role": "TECHNICIEN",
    "region_affectation": "Rabat"
  }'

# Create Inspecteur
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "inspecteur@test.com",
    "password": "test123",
    "nom": "Bernard",
    "prenom": "Pierre",
    "telephone": "0634567890",
    "role": "INSPECTEUR",
    "region_affectation": "Marrakech"
  }'

# Create Admin
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "password": "admin123",
    "nom": "Admin",
    "prenom": "System",
    "telephone": "0645678901",
    "role": "ADMIN",
    "region_affectation": "Casablanca"
  }'
```

## Sample Champs (Fields)

### Login as Agriculteur first
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "agriculteur@test.com",
    "password": "test123"
  }' \
  -c cookies.txt
```

### Create Test Champs
```bash
# Champ 1: Maraîchage
curl -X POST http://localhost:5000/api/champs \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "nom": "Champ Nord - Légumes",
    "superficie": 15.5,
    "type_champs": "Maraîchage",
    "type_sol": "Limoneux",
    "systeme_irrigation": "Goutte-à-goutte",
    "region": "Casablanca",
    "ville": "Bouskoura",
    "adresse": "Route de l'aéroport"
  }'

# Champ 2: Céréales
curl -X POST http://localhost:5000/api/champs \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "nom": "Champ Sud - Blé",
    "superficie": 25.0,
    "type_champs": "Céréales",
    "type_sol": "Argileux",
    "systeme_irrigation": "Aspersion",
    "region": "Casablanca",
    "ville": "Médiouna"
  }'

# Champ 3: Arboriculture
curl -X POST http://localhost:5000/api/champs \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "nom": "Verger d'Orangers",
    "superficie": 10.0,
    "type_champs": "Arboriculture",
    "type_sol": "Sableux",
    "systeme_irrigation": "Goutte-à-goutte",
    "region": "Casablanca",
    "ville": "Dar Bouazza"
  }'
```

## Sample Type Culture (SQL Insert)

```sql
-- Insert common crop types
INSERT INTO TYPE_CULTURE (nom, categorie, cycle_croissance_jours, coefficient_cultural_kc, description)
VALUES ('Tomate', 'Légumes', 120, 1.15, 'Culture de tomates en plein champ');

INSERT INTO TYPE_CULTURE (nom, categorie, cycle_croissance_jours, coefficient_cultural_kc, description)
VALUES ('Blé', 'Céréales', 180, 0.95, 'Blé tendre pour la farine');

INSERT INTO TYPE_CULTURE (nom, categorie, cycle_croissance_jours, coefficient_cultural_kc, description)
VALUES ('Orange', 'Fruits', 365, 0.75, 'Oranger production d'oranges');

INSERT INTO TYPE_CULTURE (nom, categorie, cycle_croissance_jours, coefficient_cultural_kc, description)
VALUES ('Carotte', 'Légumes', 90, 1.05, 'Culture de carottes');

INSERT INTO TYPE_CULTURE (nom, categorie, cycle_croissance_jours, coefficient_cultural_kc, description)
VALUES ('Maïs', 'Céréales', 140, 1.20, 'Maïs grain');

COMMIT;
```

## Sample Parcelles (SQL - After Creating Champs)

```sql
-- Assuming champ_id 1 exists (Champ Nord - Légumes)
-- And type_culture_id 1 exists (Tomate)

INSERT INTO PARCELLE (champ_id, type_culture_id, nom, superficie, date_plantation, date_recolte_prevue)
VALUES (1, 1, 'Parcelle A - Tomates', 5.0, SYSDATE, SYSDATE + 120);

INSERT INTO PARCELLE (champ_id, type_culture_id, nom, superficie, date_plantation, date_recolte_prevue)
VALUES (1, 4, 'Parcelle B - Carottes', 4.5, SYSDATE, SYSDATE + 90);

INSERT INTO PARCELLE (champ_id, type_culture_id, nom, superficie, date_plantation, date_recolte_prevue)
VALUES (1, NULL, 'Parcelle C - En préparation', 6.0, NULL, NULL);

COMMIT;
```

## Sample Seuils (Thresholds)

```sql
-- Thresholds for Tomates
INSERT INTO SEUIL_CULTURE (type_culture_id, type_seuil, seuil_min, seuil_max, unite_mesure, stade_croissance)
VALUES (1, 'HUMIDITE', 60, 80, '%', 'CROISSANCE');

INSERT INTO SEUIL_CULTURE (type_culture_id, type_seuil, seuil_min, seuil_max, unite_mesure, stade_croissance)
VALUES (1, 'HUMIDITE', 70, 85, '%', 'FLORAISON');

INSERT INTO SEUIL_CULTURE (type_culture_id, type_seuil, seuil_min, seuil_max, unite_mesure, stade_croissance)
VALUES (1, 'TEMPERATURE', 18, 28, '°C', 'CROISSANCE');

-- Thresholds for Blé
INSERT INTO SEUIL_CULTURE (type_culture_id, type_seuil, seuil_min, seuil_max, unite_mesure, stade_croissance)
VALUES (2, 'HUMIDITE', 50, 70, '%', 'CROISSANCE');

INSERT INTO SEUIL_CULTURE (type_culture_id, type_seuil, seuil_min, seuil_max, unite_mesure, stade_croissance)
VALUES (2, 'TEMPERATURE', 15, 25, '°C', 'CROISSANCE');

COMMIT;
```

## Python Script to Create All Test Data

```python
import requests
import time

API_URL = 'http://localhost:5000/api'

def create_users():
    users = [
        {
            'email': 'agriculteur@test.com',
            'password': 'test123',
            'nom': 'Dupont',
            'prenom': 'Jean',
            'telephone': '0612345678',
            'role': 'AGRICULTEUR',
            'region_affectation': 'Casablanca'
        },
        {
            'email': 'technicien@test.com',
            'password': 'test123',
            'nom': 'Martin',
            'prenom': 'Sophie',
            'telephone': '0623456789',
            'role': 'TECHNICIEN',
            'region_affectation': 'Rabat'
        },
        {
            'email': 'inspecteur@test.com',
            'password': 'test123',
            'nom': 'Bernard',
            'prenom': 'Pierre',
            'telephone': '0634567890',
            'role': 'INSPECTEUR',
            'region_affectation': 'Marrakech'
        }
    ]

    for user in users:
        try:
            response = requests.post(f'{API_URL}/auth/register', json=user)
            print(f"✓ Created {user['role']}: {user['email']}")
        except Exception as e:
            print(f"✗ Error creating {user['email']}: {e}")
        time.sleep(0.5)

def create_champs():
    # Login as agriculteur
    session = requests.Session()
    login_response = session.post(f'{API_URL}/auth/login', json={
        'email': 'agriculteur@test.com',
        'password': 'test123'
    })

    if login_response.status_code != 200:
        print("Login failed!")
        return

    champs = [
        {
            'nom': 'Champ Nord - Légumes',
            'superficie': 15.5,
            'type_champs': 'Maraîchage',
            'type_sol': 'Limoneux',
            'systeme_irrigation': 'Goutte-à-goutte',
            'region': 'Casablanca',
            'ville': 'Bouskoura'
        },
        {
            'nom': 'Champ Sud - Blé',
            'superficie': 25.0,
            'type_champs': 'Céréales',
            'type_sol': 'Argileux',
            'systeme_irrigation': 'Aspersion',
            'region': 'Casablanca',
            'ville': 'Médiouna'
        },
        {
            'nom': 'Verger d\'Orangers',
            'superficie': 10.0,
            'type_champs': 'Arboriculture',
            'type_sol': 'Sableux',
            'systeme_irrigation': 'Goutte-à-goutte',
            'region': 'Casablanca',
            'ville': 'Dar Bouazza'
        }
    ]

    for champ in champs:
        try:
            response = session.post(f'{API_URL}/champs', json=champ)
            print(f"✓ Created champ: {champ['nom']}")
        except Exception as e:
            print(f"✗ Error creating champ {champ['nom']}: {e}")
        time.sleep(0.5)

if __name__ == '__main__':
    print("Creating test users...")
    create_users()

    print("\nCreating test champs...")
    create_champs()

    print("\nTest data created successfully!")
    print("\nYou can now login with:")
    print("  - agriculteur@test.com / test123")
    print("  - technicien@test.com / test123")
    print("  - inspecteur@test.com / test123")
```

Save this as `create_test_data.py` and run:
```bash
python create_test_data.py
```

## Verification Queries

```sql
-- Check all users
SELECT user_id, email, nom, prenom, role, statut
FROM UTILISATEUR
ORDER BY date_creation DESC;

-- Check all champs
SELECT c.champ_id, c.nom, c.superficie, c.type_champs, u.email as proprietaire
FROM CHAMP c
JOIN UTILISATEUR u ON c.user_id = u.user_id;

-- Check all parcelles
SELECT p.parcelle_id, p.nom, c.nom as champ_nom, tc.nom as culture
FROM PARCELLE p
JOIN CHAMP c ON p.champ_id = c.champ_id
LEFT JOIN TYPE_CULTURE tc ON p.type_culture_id = tc.type_culture_id;

-- Check all type cultures
SELECT type_culture_id, nom, categorie, cycle_croissance_jours, coefficient_cultural_kc
FROM TYPE_CULTURE;

-- Check all seuils
SELECT sc.*, tc.nom as type_culture_nom
FROM SEUIL_CULTURE sc
JOIN TYPE_CULTURE tc ON sc.type_culture_id = tc.type_culture_id;
```

## Testing Workflows

### 1. Test Agriculteur Workflow
```bash
# 1. Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"farmer@test.com","password":"test123","nom":"Test","prenom":"Farmer","telephone":"0612345678","role":"AGRICULTEUR"}'

# 2. Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"farmer@test.com","password":"test123"}' \
  -c cookies.txt

# 3. View profile
curl http://localhost:5000/api/auth/me -b cookies.txt

# 4. Create champ
curl -X POST http://localhost:5000/api/champs \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{"nom":"Test Champ","superficie":10.5,"region":"Test Region"}'

# 5. List champs (should see only own)
curl http://localhost:5000/api/champs -b cookies.txt

# 6. Logout
curl -X POST http://localhost:5000/api/auth/logout -b cookies.txt
```

### 2. Test Technicien Workflow
```bash
# Login as technicien
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"technicien@test.com","password":"test123"}' \
  -c tech_cookies.txt

# View all alertes
curl http://localhost:5000/api/alertes -b tech_cookies.txt

# Resolve an alerte (replace :id with actual ID)
curl -X POST http://localhost:5000/api/alertes/1/resolve -b tech_cookies.txt

# Check notifications
curl http://localhost:5000/api/notifications -b tech_cookies.txt
```

## Expected Password Hashes

For reference, these passwords hash to:

```python
import hashlib

passwords = {
    'test123': hashlib.sha256('test123'.encode()).hexdigest(),
    'admin123': hashlib.sha256('admin123'.encode()).hexdigest()
}

# test123 -> ecd71870d1963316a97e3ac3408c9835ad8cf0f3c1bc703527c30265534f75ae
# admin123 -> 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9
```
