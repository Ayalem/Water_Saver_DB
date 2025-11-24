from flask import Blueprint, request, jsonify, session
from auth import register_user, authenticate_user, get_current_user, login_required, set_oracle_context

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
        
        # Set Oracle context for VPD policies
        set_oracle_context(user['user_id'], user['role'])

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
