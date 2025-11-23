# WaterSaver Architecture

## System Overview

```
┌─────────────┐         ┌─────────────┐         ┌──────────────┐
│   Browser   │────────▶│    Flask    │────────▶│    Oracle    │
│  (Frontend) │◀────────│  (Backend)  │◀────────│  (Database)  │
└─────────────┘         └─────────────┘         └──────────────┘
     HTML/CSS/JS         Python + Session        PL/SQL + RLS
```

## Authentication Flow

### Registration
```
1. User fills registration form
   ↓
2. Frontend sends POST /api/auth/register
   ↓
3. Backend hashes password (SHA-256)
   ↓
4. Backend calls create_user() procedure
   ↓
5. Oracle inserts user with role
   ↓
6. Success response sent to frontend
```

### Login
```
1. User enters email + password
   ↓
2. Frontend sends POST /api/auth/login
   ↓
3. Backend hashes password
   ↓
4. Backend calls login_utilisateur() procedure
   ↓
5. Oracle validates credentials
   ↓
6. Backend creates session with user_id, role, email
   ↓
7. Session cookie sent to browser
   ↓
8. Frontend redirects to dashboard
```

## Role-Based Access Control (RBAC)

### Database Level (Oracle RLS)

```sql
-- Example: Only agriculteurs see their own champs
CREATE POLICY champ_access_policy ON CHAMP
  FOR SELECT
  USING (
    user_id = SYS_CONTEXT('USER_CONTEXT', 'user_id')
    OR SYS_CONTEXT('USER_CONTEXT', 'role') = 'ADMIN'
  );
```

### Application Level (Flask Decorators)

```python
@role_required('AGRICULTEUR', 'ADMIN')
def create_champ():
    # Only these roles can create champs
    pass
```

### Frontend Level (UI Rendering)

```javascript
if (currentUser.role === 'AGRICULTEUR') {
    // Show create champ button
}
```

## Data Access Patterns

### AGRICULTEUR
```
Login → Session (role=AGRICULTEUR) → GET /api/champs
                                        ↓
                          Backend calls LISTER_CHAMPS_UTILISATEUR(user_id)
                                        ↓
                          Oracle returns only user's champs
```

### TECHNICIEN
```
Login → Session (role=TECHNICIEN) → GET /api/alertes
                                       ↓
                     Backend queries all alertes (no filter)
                                       ↓
                     Oracle RLS allows access to all alertes
                                       ↓
                     Can call PRC_RESOUDRE_ALERTE()
```

### INSPECTEUR
```
Login → Session (role=INSPECTEUR) → GET /api/alertes (read-only)
                                       ↓
                      Backend queries alertes
                                       ↓
                      Oracle RLS allows SELECT but not UPDATE
```

### ADMIN
```
Login → Session (role=ADMIN) → Full access to all endpoints
                                  ↓
                Oracle RLS bypasses restrictions for ADMIN
```

## Security Layers

### Layer 1: Frontend
- Form validation
- UI elements hidden based on role
- Client-side error handling

### Layer 2: Flask Backend
- Session validation (`@login_required`)
- Role checking (`@role_required`)
- Password hashing (SHA-256)
- CORS configuration
- Input sanitization

### Layer 3: Oracle Database
- Stored procedures (prevent SQL injection)
- Row-Level Security (RLS)
- Column-level permissions
- Audit trails
- Constraints and triggers

## Session Management

```
┌──────────────────────────────────────────────┐
│              Flask Session                    │
├──────────────────────────────────────────────┤
│  user_id: 123                                 │
│  email: "jean.dupont@example.com"            │
│  role: "AGRICULTEUR"                          │
│  nom: "Dupont"                                │
│  prenom: "Jean"                               │
└──────────────────────────────────────────────┘
          ↓
    Stored server-side
          ↓
    Cookie with session_id sent to browser
          ↓
    Validated on each request
```

## Database Connection Strategy

### Connection Pool (Future Enhancement)
```python
# Current: New connection per request
def get_db_connection():
    return cx_Oracle.connect(user, pass, dsn)

# Future: Connection pooling
pool = cx_Oracle.SessionPool(user, pass, dsn, min=2, max=10)
def get_db_connection():
    return pool.acquire()
```

## API Response Format

### Success Response
```json
{
  "champs": [
    {
      "champ_id": 1,
      "nom": "Champ Nord",
      "superficie": 10.5,
      "statut": "ACTIF"
    }
  ]
}
```

### Error Response
```json
{
  "error": "Insufficient permissions"
}
```

## Procedure Call Flow

### Example: Creating a Champ

```
Frontend                Backend                 Oracle
   |                       |                       |
   |  POST /api/champs     |                       |
   |---------------------->|                       |
   |                       |                       |
   |                       | check session         |
   |                       | check role            |
   |                       |                       |
   |                       | CREATE_CHAMP()        |
   |                       |---------------------->|
   |                       |                       |
   |                       |                       | validate data
   |                       |                       | check permissions
   |                       |                       | INSERT INTO CHAMP
   |                       |                       |
   |                       |  champ_id=42          |
   |                       |<----------------------|
   |                       |                       |
   |  {champ_id: 42}       |                       |
   |<----------------------|                       |
   |                       |                       |
```

## Error Handling Chain

```
Database Error (ORA-XXXXX)
    ↓
Caught by cx_Oracle
    ↓
Converted to Python exception
    ↓
Caught in route handler
    ↓
Formatted as JSON error
    ↓
Returned with HTTP status code
    ↓
Displayed in UI as alert
```

## Frontend State Management

```javascript
// Current user state
let currentUser = {
    user_id: 123,
    email: "user@example.com",
    role: "AGRICULTEUR",
    nom: "Dupont",
    prenom: "Jean"
};

// Used to:
// 1. Display user info in sidebar
// 2. Filter UI elements
// 3. Make role-based API calls
// 4. Show/hide features
```

## Scaling Considerations

### Current Architecture (Small Scale)
- Single Flask process
- Direct Oracle connections
- Server-side sessions in filesystem

### Future Improvements (Medium Scale)
- Multiple Flask workers (Gunicorn)
- Connection pooling
- Redis for session storage
- Load balancer (Nginx)

### Enterprise Scale
- Microservices architecture
- Message queue (RabbitMQ/Kafka)
- Distributed caching (Redis cluster)
- Database replication
- Container orchestration (Kubernetes)

## Monitoring Points

1. **Backend Metrics**
   - Request rate
   - Response time
   - Error rate
   - Active sessions

2. **Database Metrics**
   - Query execution time
   - Connection pool usage
   - Procedure call frequency
   - Lock contention

3. **User Metrics**
   - Active users by role
   - Feature usage
   - Login success rate
   - Session duration
