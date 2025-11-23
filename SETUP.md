# WaterSaver - Setup Guide

## Architecture Overview

```
User → Frontend (HTML/CSS/JS) → Flask Backend → Oracle Database
                                      ↓
                            Session-based Auth
                            Password Hashing
                            Role-based Access
```

## How It Works

1. **User Registration/Login** (Application Level)
   - User registers with email + password
   - Password is hashed using SHA-256 before storage
   - User credentials stored in UTILISATEUR table
   - Session created with user_id, email, role

2. **Role-Based Access Control**
   - Flask middleware checks user role from session
   - Oracle procedures called with user context
   - RLS (Row Level Security) enforced at database level
   - Users only see data they're authorized to access

3. **Data Flow Example**
   ```
   User Login → Flask hashes password → Calls login_utilisateur() procedure
              → Session created with role → Dashboard loads with role-filtered data
   ```

## Prerequisites

- Python 3.8+
- Oracle Database 11g+ (with your SQL scripts executed)
- Oracle Instant Client (for cx_Oracle)

## Installation Steps

### 1. Install Oracle Instant Client

**Linux:**
```bash
# Download from Oracle website
wget https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linux.x64-21.1.0.0.0.zip
unzip instantclient-basic-linux.x64-21.1.0.0.0.zip
sudo mv instantclient_21_1 /opt/oracle/
echo /opt/oracle/instantclient_21_1 | sudo tee -a /etc/ld.so.conf.d/oracle-instantclient.conf
sudo ldconfig
```

**macOS:**
```bash
brew install instantclient-basic
```

**Windows:**
- Download and extract Oracle Instant Client
- Add to PATH environment variable

### 2. Setup Database

Execute all SQL scripts in order:

```bash
cd sql_scripts

# 1. Create tables
sqlplus app_user/app_pass@localhost:1521/ORCL @1_creation_bd/tables.sql
sqlplus app_user/app_pass@localhost:1521/ORCL @1_creation_bd/roles.sql

# 2. Create authentication procedures
sqlplus app_user/app_pass@localhost:1521/ORCL @2_authentification/create_user.sql
sqlplus app_user/app_pass@localhost:1521/ORCL @2_authentification/login_user.sql
sqlplus app_user/app_pass@localhost:1521/ORCL @2_authentification/check_user_exists.sql
sqlplus app_user/app_pass@localhost:1521/ORCL @2_authentification/update_statut_user.sql

# 3. Create all other procedures (alertes, notifications, etc.)
# Continue with remaining scripts...
```

### 3. Setup Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r ../requirements.txt

# Configure environment
cp ../.env.example .env
# Edit .env with your Oracle credentials
```

### 4. Configure Environment

Edit `.env` file:

```env
SECRET_KEY=your-random-secret-key-here
ORACLE_HOST=localhost
ORACLE_PORT=1521
ORACLE_SERVICE=ORCL
ORACLE_USER=app_user
ORACLE_PASSWORD=app_pass
```

### 5. Start Backend

```bash
cd backend
python main.py
```

Backend will run on `http://localhost:5000`

### 6. Start Frontend

Open a new terminal:

```bash
cd frontend

# Option 1: Using Python's built-in server
python -m http.server 3000

# Option 2: Using Node.js http-server
npx http-server -p 3000

# Option 3: Using any local web server
```

Frontend will be available at `http://localhost:3000`

## Usage

### 1. Register a New User

1. Open `http://localhost:3000`
2. Click "S'inscrire"
3. Fill in the form:
   - Nom, Prénom, Email, Password, Téléphone
   - **Role**: Choose AGRICULTEUR, TECHNICIEN, or INSPECTEUR
4. Click "S'inscrire"

### 2. Login

1. Enter email and password
2. Click "Se connecter"
3. Redirected to dashboard

### 3. Dashboard Features by Role

#### AGRICULTEUR
- View their own champs (fields)
- Create/update champs
- View parcelles (plots)
- Create/update parcelles
- View alertes for their champs
- Receive notifications

#### TECHNICIEN
- View all alertes
- Resolve alertes
- Create interventions
- View notifications about assigned tasks

#### INSPECTEUR
- View all alertes (read-only)
- View all rapports (reports)
- View seuils (thresholds)

#### ADMIN
- Full access to all features
- Manage users
- View all data

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Get current user

### Champs
- `GET /api/champs` - List champs (filtered by user role)
- `GET /api/champs/:id` - Get champ details
- `POST /api/champs` - Create champ (AGRICULTEUR, ADMIN)
- `PUT /api/champs/:id` - Update champ (AGRICULTEUR, ADMIN)

### Parcelles
- `GET /api/parcelles` - List parcelles
- `GET /api/parcelles/:id` - Get parcelle details
- `POST /api/parcelles` - Create parcelle (AGRICULTEUR, ADMIN)
- `PUT /api/parcelles/:id` - Update parcelle (AGRICULTEUR, ADMIN)

### Alertes
- `GET /api/alertes` - List alertes (filtered by role)
- `POST /api/alertes/:id/resolve` - Resolve alerte (TECHNICIEN, ADMIN)

### Notifications
- `GET /api/notifications` - List user notifications
- `POST /api/notifications/:id/mark-read` - Mark as read
- `GET /api/notifications/count-unread` - Count unread

## Security Features

### 1. Password Security
- SHA-256 hashing before storage
- No plain-text passwords stored
- Secure comparison in procedures

### 2. Session Management
- Server-side sessions (Flask-Session)
- Session contains: user_id, email, role
- Automatic expiration after inactivity

### 3. Role-Based Access
```python
@role_required('AGRICULTEUR', 'ADMIN')
def create_champ():
    # Only AGRICULTEUR and ADMIN can access
```

### 4. Database Security
- Users never access DB directly
- Application user (app_user) has limited permissions
- Oracle RLS enforces row-level security
- Prepared statements prevent SQL injection

## Troubleshooting

### Database Connection Error

```
Error: ORA-12154: TNS:could not resolve the connect identifier
```

**Solution:**
- Check ORACLE_HOST, ORACLE_PORT, ORACLE_SERVICE in .env
- Verify Oracle listener is running: `lsnrctl status`

### cx_Oracle Import Error

```
ImportError: DPI-1047: Cannot locate a 64-bit Oracle Client library
```

**Solution:**
- Install Oracle Instant Client
- Set LD_LIBRARY_PATH (Linux) or PATH (Windows)

### CORS Error in Browser

```
Access to fetch has been blocked by CORS policy
```

**Solution:**
- Ensure backend is running on port 5000
- Check Flask-CORS configuration in main.py
- Clear browser cache

### Session Not Persisting

**Solution:**
- Check SECRET_KEY is set in .env
- Ensure cookies are enabled in browser
- Verify Flask-Session is installed

## Testing

### Test User Creation

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "agriculteur@test.com",
    "password": "test123",
    "nom": "Dupont",
    "prenom": "Jean",
    "telephone": "0612345678",
    "role": "AGRICULTEUR"
  }'
```

### Test Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "agriculteur@test.com",
    "password": "test123"
  }' \
  -c cookies.txt
```

### Test Authenticated Request

```bash
curl -X GET http://localhost:5000/api/champs \
  -b cookies.txt
```

## Project Structure

```
WaterSaver/
├── backend/
│   ├── main.py              # Flask application entry point
│   ├── config.py            # Configuration
│   ├── database.py          # Database utilities
│   ├── auth.py              # Authentication logic
│   └── routes/
│       ├── auth_routes.py   # Auth endpoints
│       ├── champ_routes.py  # Champ endpoints
│       ├── parcelle_routes.py
│       ├── alerte_routes.py
│       └── notification_routes.py
├── frontend/
│   ├── index.html           # Login/Register page
│   ├── dashboard.html       # Main dashboard
│   ├── css/
│   │   └── style.css        # Styles
│   └── js/
│       ├── api.js           # API client
│       ├── auth.js          # Auth logic
│       └── dashboard.js     # Dashboard logic
├── sql_scripts/             # Oracle SQL scripts
├── requirements.txt         # Python dependencies
└── .env                     # Configuration (create from .env.example)
```

## Next Steps

1. **Add More Features:**
   - Capteur management
   - Mesure visualization
   - Rapport generation
   - Intervention tracking

2. **Improve Security:**
   - Add JWT tokens for stateless auth
   - Implement password reset
   - Add 2FA authentication
   - Rate limiting

3. **Enhance UI:**
   - Add charts/graphs
   - Real-time updates (WebSocket)
   - Mobile responsive design
   - Dark mode

4. **Production Deployment:**
   - Use production WSGI server (Gunicorn)
   - Setup HTTPS (SSL/TLS)
   - Configure reverse proxy (Nginx)
   - Setup logging and monitoring
