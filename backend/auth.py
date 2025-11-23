import hashlib
from functools import wraps
from flask import session, jsonify, request
import cx_Oracle
from database import get_db_connection, execute_query

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(password, password_hash):
    return hash_password(password) == password_hash

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'Authentication required'}), 401
        return f(*args, **kwargs)
    return decorated_function

def role_required(*allowed_roles):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session:
                return jsonify({'error': 'Authentication required'}), 401

            if 'role' not in session or session['role'] not in allowed_roles:
                return jsonify({'error': 'Insufficient permissions'}), 403

            return f(*args, **kwargs)
        return decorated_function
    return decorator

def register_user(email, password, nom, prenom, telephone, role, region_affectation=None):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        password_hash = hash_password(password)

        cursor.callproc('create_user', [
            email,
            nom,
            prenom,
            password_hash,
            telephone,
            role,
            region_affectation
        ])

        conn.commit()
        return {'success': True, 'message': 'User created successfully'}

    except cx_Oracle.DatabaseError as e:
        conn.rollback()
        error_obj, = e.args
        return {'success': False, 'error': error_obj.message}

    finally:
        cursor.close()
        conn.close()

def authenticate_user(email, password):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        password_hash = hash_password(password)

        cursor.callproc('login_utilisateur', [email, password_hash])

        user = execute_query(
            "SELECT user_id, nom, prenom, email, role, statut FROM UTILISATEUR WHERE email = :email",
            {'email': email},
            fetchone=True
        )

        if user:
            return {'success': True, 'user': user}
        else:
            return {'success': False, 'error': 'Login failed'}

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return {'success': False, 'error': error_obj.message}

    finally:
        cursor.close()
        conn.close()

def get_current_user():
    if 'user_id' not in session:
        return None

    user = execute_query(
        "SELECT user_id, nom, prenom, email, role, statut, region_affectation FROM UTILISATEUR WHERE user_id = :user_id",
        {'user_id': session['user_id']},
        fetchone=True
    )

    return user
