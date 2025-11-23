# WaterSaver System Diagram

## Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           USER INTERFACE                                 │
│                        (Browser - Port 3000)                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌────────────────┐              ┌────────────────────────────────┐    │
│  │  index.html    │              │      dashboard.html            │    │
│  │  (Login/Reg)   │─────────────▶│   - Champs view               │    │
│  │                │              │   - Parcelles view             │    │
│  │  - Email/Pass  │              │   - Alertes view               │    │
│  │  - Role select │              │   - Notifications view         │    │
│  └────────────────┘              │                                │    │
│                                   │  Role-specific UI rendering    │    │
│                                   └────────────────────────────────┘    │
│                                                                           │
│  JavaScript Modules:                                                     │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐                        │
│  │ auth.js  │  │ api.js    │  │ dashboard.js │                        │
│  │ - Login  │  │ - API     │  │ - Data load  │                        │
│  │ - Logout │  │ - Fetch   │  │ - UI update  │                        │
│  └──────────┘  └───────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                            HTTP Requests (JSON)
                            with Session Cookie
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          FLASK BACKEND                                   │
│                        (Python - Port 5000)                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      main.py (App Entry)                         │   │
│  │  - Flask app initialization                                      │   │
│  │  - CORS configuration                                            │   │
│  │  - Session setup                                                 │   │
│  │  - Route registration                                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────┐  ┌──────────────┐  ┌────────────────────────┐    │
│  │   config.py     │  │  database.py │  │      auth.py           │    │
│  │  - DB config    │  │  - Connect   │  │  - Password hashing    │    │
│  │  - Secret key   │  │  - Query     │  │  - Session management  │    │
│  └─────────────────┘  │  - Cursor    │  │  - Decorators          │    │
│                        └──────────────┘  └────────────────────────┘    │
│                                                                           │
│  API Routes:                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  /api/auth/*         - Login, Register, Logout, Me              │  │
│  │  /api/champs/*       - List, Get, Create, Update Champs         │  │
│  │  /api/parcelles/*    - List, Get, Create, Update Parcelles      │  │
│  │  /api/alertes/*      - List, Resolve Alertes                    │  │
│  │  /api/notifications/* - List, Mark Read, Count Unread           │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  Middleware:                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  @login_required     - Check session exists                      │  │
│  │  @role_required      - Check user has correct role               │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                          cx_Oracle Connection
                            (SQL Procedures)
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        ORACLE DATABASE                                   │
│                         (Port 1521/ORCL)                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                         TABLES                                   │   │
│  │  ┌──────────────┐  ┌───────────┐  ┌────────────┐               │   │
│  │  │ UTILISATEUR  │  │   CHAMP   │  │  PARCELLE  │               │   │
│  │  │  - user_id   │  │ - champ_id│  │- parcelle  │               │   │
│  │  │  - email     │  │ - user_id │  │- champ_id  │               │   │
│  │  │  - pass_hash │  │ - nom     │  │- culture   │               │   │
│  │  │  - role      │  │ - super   │  │            │               │   │
│  │  └──────────────┘  └───────────┘  └────────────┘               │   │
│  │                                                                  │   │
│  │  ┌────────────┐  ┌──────────┐  ┌──────────────┐  ┌─────────┐  │   │
│  │  │  CAPTEUR   │  │  MESURE  │  │    ALERTE    │  │ NOTIF   │  │   │
│  │  │  RAPPORT   │  │  SEUIL   │  │ INTERVENTION │  │ CULTURE │  │   │
│  │  └────────────┘  └──────────┘  └──────────────┘  └─────────┘  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    STORED PROCEDURES                             │   │
│  │                                                                   │   │
│  │  Authentication:                                                 │   │
│  │  • create_user()            - Register new user                 │   │
│  │  • login_utilisateur()      - Validate credentials              │   │
│  │  • check_user_exists()      - Verify user                       │   │
│  │  • update_statut_user()     - Update user status                │   │
│  │                                                                   │   │
│  │  Champ Management:                                               │   │
│  │  • CREATE_CHAMP()           - Create field                      │   │
│  │  • UPDATE_CHAMP()           - Update field                      │   │
│  │  • LISTER_CHAMPS_USER()     - List user's fields                │   │
│  │  • AFFICHER_DETAILS_CHAMP() - Get field details                 │   │
│  │                                                                   │   │
│  │  Parcelle Management:                                            │   │
│  │  • CREATE_PARCELLE()        - Create plot                       │   │
│  │  • UPDATE_PARCELLE()        - Update plot                       │   │
│  │  • GET_PARCELLE_BY_ID()     - Get plot details                  │   │
│  │                                                                   │   │
│  │  Alerte Management:                                              │   │
│  │  • PRC_CREER_ALERTE()       - Create alert                      │   │
│  │  • PRC_RESOUDRE_ALERTE()    - Resolve alert                     │   │
│  │  • PRC_GET_SEUILS()         - Get thresholds                    │   │
│  │                                                                   │   │
│  │  Notification Management:                                        │   │
│  │  • PRC_AJOUTER_NOTIFICATION() - Add notification                │   │
│  │  • PRC_MARQUER_LUE()          - Mark as read                    │   │
│  │  • PRC_NOTIFIER_AGRICULTEUR() - Notify farmer                   │   │
│  │  • PRC_NOTIFIER_TECHNICIEN()  - Notify technician               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      TRIGGERS                                    │   │
│  │  • TRG_MESURE_ALERTE         - Auto-create alerts on threshold  │   │
│  │  • TRG_ALERTE_NOTIF          - Auto-notify on alert             │   │
│  │  • TRG_ALERTE_DUREE          - Calculate alert duration         │   │
│  │  • TRG_CREATE_INTERVENTION   - Auto-create intervention         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                  ROW LEVEL SECURITY (RLS)                        │   │
│  │                                                                   │   │
│  │  Policies:                                                       │   │
│  │  • AGRICULTEUR sees only their own CHAMP                        │   │
│  │  • AGRICULTEUR sees only their own PARCELLE                     │   │
│  │  • TECHNICIEN sees all ALERTE                                   │   │
│  │  • INSPECTEUR sees all (read-only)                              │   │
│  │  • ADMIN sees and modifies all                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Authentication Flow Detail

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ 1. POST /api/auth/login
       │    {email, password}
       ▼
┌─────────────────┐
│  Flask Backend  │
└──────┬──────────┘
       │ 2. hash_password(password)
       │    → SHA-256 hash
       ▼
┌─────────────────────────────┐
│  Call login_utilisateur()   │
│  - Verify hash matches DB   │
│  - Check account status     │
│  - Update last login time   │
└──────┬──────────────────────┘
       │ 3. Success
       ▼
┌─────────────────────────┐
│  Create Session         │
│  {                      │
│    user_id: 123,        │
│    role: 'AGRICULTEUR', │
│    email: '...'         │
│  }                      │
└──────┬──────────────────┘
       │ 4. Set-Cookie: session_id
       ▼
┌─────────────┐
│   Browser   │
│ Redirects to│
│  dashboard  │
└─────────────┘
```

## Role-Based Data Access

```
┌──────────────────────────────────────────────────────────────┐
│                     USER ROLES                               │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  AGRICULTEUR                                                 │
│  ├── Can CREATE/UPDATE their own CHAMP                       │
│  ├── Can CREATE/UPDATE PARCELLE on their CHAMP              │
│  ├── Can VIEW ALERTE for their PARCELLE                     │
│  ├── Can VIEW their NOTIFICATION                            │
│  └── Cannot access other users' data                        │
│                                                               │
│  TECHNICIEN                                                  │
│  ├── Can VIEW all ALERTE                                    │
│  ├── Can RESOLVE ALERTE (PRC_RESOUDRE_ALERTE)              │
│  ├── Can CREATE/UPDATE INTERVENTION                         │
│  ├── Can VIEW assigned NOTIFICATION                         │
│  └── Cannot CREATE CHAMP or PARCELLE                        │
│                                                               │
│  INSPECTEUR                                                  │
│  ├── Can VIEW all ALERTE (read-only)                        │
│  ├── Can VIEW all RAPPORT                                   │
│  ├── Can VIEW SEUIL_CULTURE                                 │
│  └── Cannot modify anything                                 │
│                                                               │
│  ADMIN                                                       │
│  ├── Full READ access to all tables                         │
│  ├── Full WRITE access to all tables                        │
│  ├── Can manage all UTILISATEUR                             │
│  └── Bypasses all RLS policies                              │
└──────────────────────────────────────────────────────────────┘
```

## Request/Response Lifecycle

```
1. User Action in Browser
   └─▶ Click "Create Champ" button

2. Frontend JavaScript
   └─▶ api.champs.create(data)
       └─▶ fetch('http://localhost:5000/api/champs', {
             method: 'POST',
             credentials: 'include',  // Send session cookie
             body: JSON.stringify(data)
           })

3. Flask Receives Request
   └─▶ @role_required('AGRICULTEUR', 'ADMIN')
       └─▶ Check session exists
       └─▶ Check role matches
       └─▶ If OK, proceed to handler

4. Handler Executes
   └─▶ conn = get_db_connection()
       └─▶ cursor.callfunc('CREATE_CHAMP', ...)
           └─▶ Oracle validates user_id
           └─▶ Oracle inserts into CHAMP table
           └─▶ Returns champ_id

5. Response Sent
   └─▶ Flask: jsonify({'champ_id': 42})
       └─▶ HTTP 201 Created

6. Frontend Updates
   └─▶ JavaScript receives response
       └─▶ Shows success message
       └─▶ Reloads champs list
       └─▶ Updates UI
```

## Session Storage

```
Server-Side Session (Flask-Session)
┌────────────────────────────────────┐
│  File: flask_session/abc123def    │
│  ┌──────────────────────────────┐ │
│  │ user_id: 42                  │ │
│  │ email: "farmer@example.com"  │ │
│  │ role: "AGRICULTEUR"          │ │
│  │ nom: "Dupont"                │ │
│  │ prenom: "Jean"               │ │
│  │ _permanent: False            │ │
│  │ created: 1700000000          │ │
│  └──────────────────────────────┘ │
└────────────────────────────────────┘
          ▲
          │ Session ID stored in cookie
          │
    ┌──────────────┐
    │   Browser    │
    │ Cookie:      │
    │ session=abc  │
    └──────────────┘
```

## Error Handling Flow

```
Database Error (e.g., ORA-20001: User already exists)
    │
    ├─▶ Caught by cx_Oracle
    │
    ├─▶ Converted to Python DatabaseError
    │
    ├─▶ Caught in try/except in route
    │
    ├─▶ Formatted as JSON:
    │   {"error": "Email déjà utilisé"}
    │
    ├─▶ Returned with HTTP status code
    │   (400 Bad Request, 401 Unauthorized, 403 Forbidden, 500 Server Error)
    │
    └─▶ Frontend displays alert:
        showAlert(error.message, 'error')
        └─▶ Red banner shown to user
```
