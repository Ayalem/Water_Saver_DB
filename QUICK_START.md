# WaterSaver - Quick Start Guide

## 5-Minute Setup

### Step 1: Configure Environment (1 min)
```bash
cp .env.example .env
# Edit .env with your Oracle credentials
```

### Step 2: Install Dependencies (2 min)
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r ../requirements.txt
```

### Step 3: Start Application (30 sec)
```bash
# Terminal 1: Backend
cd backend
python main.py

# Terminal 2: Frontend
cd frontend
python -m http.server 3000
```

### Step 4: Test It (1 min)
1. Open http://localhost:3000
2. Click "S'inscrire"
3. Create an account as AGRICULTEUR
4. Login and explore the dashboard

## Common Tasks

### Creating Users Programmatically

```python
import requests

# Register an AGRICULTEUR
response = requests.post('http://localhost:5000/api/auth/register', json={
    'email': 'farmer@test.com',
    'password': 'test123',
    'nom': 'Martin',
    'prenom': 'Pierre',
    'telephone': '0612345678',
    'role': 'AGRICULTEUR',
    'region_affectation': 'Casablanca'
})
print(response.json())
```

### Testing API with cURL

```bash
# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "nom": "Test",
    "prenom": "User",
    "telephone": "0612345678",
    "role": "AGRICULTEUR"
  }'

# Login and save cookie
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }' \
  -c cookies.txt

# Get user info
curl http://localhost:5000/api/auth/me -b cookies.txt

# Get champs
curl http://localhost:5000/api/champs -b cookies.txt

# Create champ
curl -X POST http://localhost:5000/api/champs \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "nom": "Champ Test",
    "superficie": 15.5,
    "type_champs": "Maraîchage",
    "region": "Casablanca"
  }'
```

### Database Queries for Testing

```sql
-- Check if user was created
SELECT user_id, email, nom, prenom, role, statut
FROM UTILISATEUR
WHERE email = 'test@example.com';

-- View all users
SELECT user_id, email, nom, prenom, role, date_creation
FROM UTILISATEUR
ORDER BY date_creation DESC;

-- Check champs for a user
SELECT c.*, u.email
FROM CHAMP c
JOIN UTILISATEUR u ON c.user_id = u.user_id;

-- View active alertes
SELECT a.*, p.nom as parcelle_nom
FROM ALERTE a
JOIN PARCELLE p ON a.parcelle_id = p.parcelle_id
WHERE a.statut = 'ACTIVE';
```

## Role Testing Scenarios

### Test AGRICULTEUR Access
1. Register as AGRICULTEUR
2. Login
3. Create a champ
4. Create a parcelle
5. View your alertes
6. Check you can't see other users' data

### Test TECHNICIEN Access
1. Register as TECHNICIEN
2. Login
3. View all alertes (system-wide)
4. Resolve an alerte
5. View notifications
6. Check you can't create champs

### Test INSPECTEUR Access
1. Register as INSPECTEUR
2. Login
3. View all alertes (read-only)
4. View all rapports
5. Check you can't modify anything

## Troubleshooting

### Problem: Can't connect to database
```bash
# Check Oracle listener
lsnrctl status

# Test connection
sqlplus app_user/app_pass@localhost:1521/ORCL
```

### Problem: Backend won't start
```bash
# Check dependencies
pip list | grep -E "Flask|cx_Oracle|passlib"

# Check Python version
python --version  # Should be 3.8+

# Check Oracle client
python -c "import cx_Oracle; print(cx_Oracle.version)"
```

### Problem: Login fails
```bash
# Check user exists
sqlplus app_user/app_pass@localhost:1521/ORCL <<EOF
SELECT * FROM UTILISATEUR WHERE email = 'test@example.com';
EOF

# Check password hash
# Password 'test123' should hash to specific value
python -c "import hashlib; print(hashlib.sha256('test123'.encode()).hexdigest())"
```

### Problem: Session not working
```bash
# Check .env file exists
cat .env

# Check SECRET_KEY is set
grep SECRET_KEY .env

# Check session directory (if using filesystem sessions)
ls -la flask_session/
```

## API Testing with Postman

### Import Collection

Create collection with these requests:

1. **Register**
   - Method: POST
   - URL: http://localhost:5000/api/auth/register
   - Body (JSON):
   ```json
   {
     "email": "test@example.com",
     "password": "test123",
     "nom": "Test",
     "prenom": "User",
     "telephone": "0612345678",
     "role": "AGRICULTEUR"
   }
   ```

2. **Login**
   - Method: POST
   - URL: http://localhost:5000/api/auth/login
   - Body (JSON):
   ```json
   {
     "email": "test@example.com",
     "password": "test123"
   }
   ```
   - Note: Enable "Save cookies" in Postman settings

3. **Get Champs**
   - Method: GET
   - URL: http://localhost:5000/api/champs
   - Uses cookies from login

## Development Workflow

### Making Changes to Backend
```bash
# Edit files in backend/
cd backend

# Restart Flask
# Press Ctrl+C and run again
python main.py
```

### Making Changes to Frontend
```bash
# Edit files in frontend/
# Just refresh browser - no restart needed
```

### Adding New Oracle Procedures
```bash
# 1. Create SQL file in sql_scripts/
# 2. Execute it
sqlplus app_user/app_pass@localhost:1521/ORCL @sql_scripts/my_new_procedure.sql

# 3. Add route in backend/routes/
# 4. Test with curl or Postman
```

## Quick Database Reset

```sql
-- Delete all test data (BE CAREFUL!)
DELETE FROM NOTIFICATION;
DELETE FROM INTERVENTION;
DELETE FROM ALERTE;
DELETE FROM MESURE;
DELETE FROM CAPTEUR;
DELETE FROM PARCELLE;
DELETE FROM CHAMP;
DELETE FROM RAPPORT;
DELETE FROM SEUIL_CULTURE;
DELETE FROM TYPE_CULTURE;
DELETE FROM UTILISATEUR;
COMMIT;
```

## Environment Variables Explained

```env
# Flask secret key for session encryption
# Generate with: python -c "import secrets; print(secrets.token_hex(32))"
SECRET_KEY=your-secret-key-here

# Oracle connection details
ORACLE_HOST=localhost        # Database server address
ORACLE_PORT=1521            # Default Oracle port
ORACLE_SERVICE=ORCL         # Service name or SID
ORACLE_USER=app_user        # Application database user
ORACLE_PASSWORD=app_pass    # Application database password
```

## Performance Tips

### Backend Optimization
```python
# Add connection pooling
import cx_Oracle
pool = cx_Oracle.SessionPool(
    user, password, dsn,
    min=2, max=10, increment=1
)

# Use in database.py
def get_db_connection():
    return pool.acquire()
```

### Frontend Optimization
```javascript
// Cache API responses
const cache = {};
async function cachedApiCall(endpoint) {
    if (cache[endpoint]) return cache[endpoint];
    const result = await api.call(endpoint);
    cache[endpoint] = result;
    return result;
}
```

### Database Optimization
```sql
-- Add indexes for frequent queries
CREATE INDEX idx_champ_user ON CHAMP(user_id);
CREATE INDEX idx_alerte_statut ON ALERTE(statut);
CREATE INDEX idx_notif_user_lue ON NOTIFICATION(user_id, lue);
```

## Next Steps

1. **Extend Functionality**
   - Add capteur management routes
   - Implement mesure visualization
   - Create rapport generation endpoints

2. **Improve Security**
   - Add JWT authentication
   - Implement password reset
   - Add rate limiting

3. **Deploy to Production**
   - Use Gunicorn instead of Flask dev server
   - Setup Nginx as reverse proxy
   - Configure SSL/TLS certificates
   - Setup monitoring and logging

## Getting Help

- Check logs in terminal where backend is running
- Use browser Developer Tools (F12) for frontend errors
- Check Oracle alert log for database errors
- Review SQL scripts in sql_scripts/ folder
