from flask import Blueprint, request, jsonify, session
from auth import register_user, authenticate_user, get_current_user, login_required, role_required
from database import get_db_connection
import oracledb

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json

    required_fields = ['email', 'password', 'nom', 'prenom', 'telephone', 'role']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400

    result = register_user(
        email=data['email'],
        password=data['password'],
        nom=data['nom'],
        prenom=data['prenom'],
        telephone=data['telephone'],
        role=data['role'],
        region_affectation=data.get('region_affectation')
    )

    if result['success']:
        return jsonify({'message': 'Registration successful'}), 201
    else:
        return jsonify({'error': result['error']}), 400

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json

    if not data.get('email') or not data.get('password'):
        return jsonify({'error': 'Email and password required'}), 400

    result = authenticate_user(data['email'], data['password'])

    if result['success']:
        user = result['user']
        session['user_id'] = user['user_id']
        session['email'] = user['email']
        session['role'] = user['role']
        session['nom'] = user['nom']
        session['prenom'] = user['prenom']

        return jsonify({
            'message': 'Login successful',
            'user': {
                'user_id': user['user_id'],
                'email': user['email'],
                'nom': user['nom'],
                'prenom': user['prenom'],
                'role': user['role']
            }
        }), 200
    else:
        return jsonify({'error': result['error']}), 401

@auth_bp.route('/logout', methods=['POST'])
@login_required
def logout():
    session.clear()
    return jsonify({'message': 'Logout successful'}), 200

@auth_bp.route('/me', methods=['GET'])
@login_required
def get_me():
    user = get_current_user()
    if user:
        return jsonify({'user': user}), 200
    else:
        return jsonify({'error': 'User not found'}), 404


# ============================================================================
# ADMIN USER MANAGEMENT ENDPOINTS
# ============================================================================

@auth_bp.route('/users/<int:user_id>/status', methods=['PUT'])
@role_required('ADMIN')
def update_user_status(user_id):
    """Update user status (ADMIN only) using update_statut_user procedure"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        if 'statut' not in data:
            return jsonify({'error': 'statut is required'}), 400
        
        # Use update_statut_user procedure
        cursor.callproc('UPDATE_STATUT_USER', [user_id, data['statut']])
        conn.commit()
        
        return jsonify({'message': 'User status updated successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@auth_bp.route('/users/<int:user_id>/role', methods=['PUT'])
@role_required('ADMIN')
def update_user_role(user_id):
    """Update user role (ADMIN only) using update_user_role procedure"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        if 'role' not in data:
            return jsonify({'error': 'role is required'}), 400
        
        # Use update_user_role procedure
        cursor.callproc('UPDATE_USER_ROLE', [user_id, data['role']])
        conn.commit()
        
        return jsonify({'message': 'User role updated successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@auth_bp.route('/users/<int:user_id>', methods=['DELETE'])
@role_required('ADMIN')
def delete_user(user_id):
    """Delete user (ADMIN only) using delete_user procedure"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Prevent self-deletion
        if user_id == session.get('user_id'):
            return jsonify({'error': 'Cannot delete your own account'}), 400
        
        # Use delete_user procedure
        cursor.callproc('DELETE_USER', [user_id])
        conn.commit()
        
        return jsonify({'message': 'User deleted successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@auth_bp.route('/users', methods=['GET'])
@role_required('ADMIN')
def get_all_users():
    """Get all users (ADMIN only)"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        query = """
            SELECT user_id, email, nom, prenom, role, statut, 
                   telephone, region_affectation, date_creation
            FROM UTILISATEUR
            ORDER BY date_creation DESC
        """
        cursor.execute(query)
        
        columns = [d[0].lower() for d in cursor.description]
        users = [dict(zip(columns, row)) for row in cursor.fetchall()]
        
        return jsonify({'users': users}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()
