# WaterSaver - Pre-Launch Checklist

## ✅ Database Setup

- [ ] Oracle Database is running (`lsnrctl status`)
- [ ] Tables created (`sql_scripts/1_creation_bd/tables.sql`)
- [ ] Roles created (`sql_scripts/1_creation_bd/roles.sql`)
- [ ] Authentication procedures created (`sql_scripts/2_authentification/`)
- [ ] Alert procedures created (`sql_scripts/3_alertes/`)
- [ ] Notification procedures created (`sql_scripts/6_Notifications/`)
- [ ] All other procedures created (champ, parcelle, etc.)
- [ ] Test with: `SELECT COUNT(*) FROM UTILISATEUR;` (should work)

## ✅ Backend Setup

- [ ] Python 3.8+ installed (`python --version`)
- [ ] Oracle Instant Client installed
- [ ] Virtual environment created (`python -m venv venv`)
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] `.env` file created and configured
- [ ] Oracle connection works (test with `python -c "import cx_Oracle; print('OK')"`)
- [ ] Backend starts without errors (`cd backend && python main.py`)
- [ ] Health check responds: `curl http://localhost:5000/api/health`

## ✅ Frontend Setup

- [ ] Frontend files exist (`frontend/index.html`, `dashboard.html`)
- [ ] CSS file exists (`frontend/css/style.css`)
- [ ] JavaScript files exist (`frontend/js/*.js`)
- [ ] Frontend server starts (`cd frontend && python -m http.server 3000`)
- [ ] Can access login page: http://localhost:3000

## ✅ Authentication Tests

- [ ] Can access login page
- [ ] Can switch to registration form
- [ ] Can register as AGRICULTEUR
- [ ] Can register as TECHNICIEN
- [ ] Can register as INSPECTEUR
- [ ] Can login with correct credentials
- [ ] Login fails with wrong password
- [ ] Session persists on page refresh
- [ ] Logout clears session

## ✅ Role-Based Access Tests

### AGRICULTEUR
- [ ] Can view dashboard with stats
- [ ] Can see "Mes Champs" menu item
- [ ] Can create a new champ
- [ ] Can view own champs only
- [ ] Can create parcelles on own champs
- [ ] Can view alertes for own parcelles
- [ ] Cannot see other users' data

### TECHNICIEN
- [ ] Can view dashboard
- [ ] Can see all alertes (system-wide)
- [ ] Can resolve alertes
- [ ] Can view notifications
- [ ] Cannot create champs or parcelles

### INSPECTEUR
- [ ] Can view all alertes (read-only)
- [ ] Cannot resolve alertes
- [ ] Cannot modify any data

## ✅ API Endpoint Tests

```bash
# Test registration
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","nom":"Test","prenom":"User","telephone":"0612345678","role":"AGRICULTEUR"}'
# Expected: {"message": "Registration successful"}

# Test login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}' \
  -c cookies.txt
# Expected: {"message": "Login successful", "user": {...}}

# Test authenticated request
curl http://localhost:5000/api/auth/me -b cookies.txt
# Expected: {"user": {...}}

# Test creating champ
curl -X POST http://localhost:5000/api/champs \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{"nom":"Test","superficie":10}'
# Expected: {"message": "Champ created", "champ_id": X}

# Test listing champs
curl http://localhost:5000/api/champs -b cookies.txt
# Expected: {"champs": [...]}
```

## ✅ Security Checks

- [ ] Passwords are hashed (not stored in plaintext)
- [ ] Session cookie is HttpOnly
- [ ] Unauthorized requests return 401
- [ ] Forbidden requests return 403
- [ ] SQL injection prevented (using procedures)
- [ ] CORS configured correctly
- [ ] Environment variables not committed to git

## ✅ User Interface Tests

- [ ] Login page renders correctly
- [ ] Registration form validates inputs
- [ ] Dashboard loads after login
- [ ] User info displayed in sidebar
- [ ] Navigation menu works
- [ ] Stats cards show correct numbers
- [ ] Champs list displays correctly
- [ ] Create champ modal opens and submits
- [ ] Alertes list displays with filters
- [ ] Notifications display and update
- [ ] Notification badge shows unread count
- [ ] Error messages display properly
- [ ] Success messages display properly

## ✅ Database Integrity Tests

```sql
-- Test user creation
SELECT COUNT(*) FROM UTILISATEUR WHERE email = 'test@test.com';
-- Expected: 1

-- Test password hash exists
SELECT LENGTH(password_hash) FROM UTILISATEUR WHERE email = 'test@test.com';
-- Expected: 64 (SHA-256)

-- Test role is set correctly
SELECT role FROM UTILISATEUR WHERE email = 'test@test.com';
-- Expected: AGRICULTEUR

-- Test champ has user_id
SELECT user_id FROM CHAMP WHERE nom = 'Test';
-- Expected: (user_id of test@test.com)

-- Test RLS (if configured)
-- Login as different user, should not see others' data
```

## ✅ Error Handling Tests

- [ ] Invalid email format rejected
- [ ] Duplicate email registration prevented
- [ ] Wrong password shows error message
- [ ] Network errors handled gracefully
- [ ] Database errors shown to user
- [ ] Missing required fields validated
- [ ] Invalid JSON rejected

## ✅ Performance Tests

- [ ] Page loads in < 2 seconds
- [ ] API responses in < 500ms
- [ ] Dashboard stats load quickly
- [ ] Large lists paginate or load efficiently
- [ ] No memory leaks on long sessions

## ✅ Browser Compatibility

- [ ] Works in Chrome
- [ ] Works in Firefox
- [ ] Works in Safari
- [ ] Works in Edge
- [ ] Mobile responsive (if required)

## ✅ Documentation

- [ ] README.md is clear and complete
- [ ] SETUP.md has installation steps
- [ ] QUICK_START.md has 5-minute guide
- [ ] ARCHITECTURE.md explains system design
- [ ] API endpoints documented
- [ ] Environment variables documented

## 🚀 Ready to Launch

When all items above are checked:

1. **Production Preparation**
   - [ ] Change SECRET_KEY to strong random value
   - [ ] Update ORACLE credentials for production
   - [ ] Disable Flask debug mode
   - [ ] Setup production WSGI server (Gunicorn)
   - [ ] Configure Nginx reverse proxy
   - [ ] Setup SSL/TLS certificates
   - [ ] Configure firewall rules
   - [ ] Setup database backups
   - [ ] Configure logging
   - [ ] Setup monitoring

2. **Deployment**
   - [ ] Deploy backend to production server
   - [ ] Deploy frontend to web server or CDN
   - [ ] Test production environment
   - [ ] Create admin user
   - [ ] Import initial data
   - [ ] Announce to users

3. **Post-Launch**
   - [ ] Monitor logs for errors
   - [ ] Check performance metrics
   - [ ] Gather user feedback
   - [ ] Plan next features

## Common Issues & Solutions

### Issue: Backend won't start
- Check Oracle Instant Client installed
- Check `.env` file exists and has correct values
- Check Python dependencies installed
- Check Oracle database is running

### Issue: Can't login
- Check user exists in database
- Check password hash matches
- Check session configuration
- Check cookies enabled in browser

### Issue: Can't see data
- Check user role in database
- Check RLS policies configured
- Check user has created data
- Check API endpoint returns data

### Issue: CORS errors
- Check backend has Flask-CORS installed
- Check CORS origins configured
- Check browser console for exact error
- Try incognito mode to clear cache

## Testing Shortcuts

```bash
# Quick test all endpoints
./test_api.sh

# Quick database check
sqlplus app_user/app_pass@localhost:1521/ORCL @check_db.sql

# Quick frontend check
open http://localhost:3000

# View backend logs
tail -f backend/app.log
```

## Success Criteria

✅ All checklist items above are completed
✅ All test users can login
✅ Each role can access appropriate features
✅ No errors in browser console
✅ No errors in backend logs
✅ Database queries execute successfully
✅ UI is responsive and intuitive
✅ System is secure (passwords hashed, sessions working)

When all criteria met: **SYSTEM IS READY FOR USE** 🎉
