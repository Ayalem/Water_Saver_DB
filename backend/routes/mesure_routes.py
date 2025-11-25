from flask import Blueprint, request, jsonify, session
from database import get_db_connection
import oracledb
from auth import login_required, role_required

mesure_bp = Blueprint('mesure', __name__, url_prefix='/api/mesures')

@mesure_bp.route('/', methods=['GET'])
@login_required
def get_mesures():
    """Get mesures (filtered by role/parcelle)"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_role = session.get('role')
        user_id = session.get('user_id')
        
        # Get filter parameters
        capteur_id = request.args.get('capteur_id')
        parcelle_id = request.args.get('parcelle_id')
        limit = request.args.get('limit', 100)
        
        if user_role == 'AGRICULTEUR':
            # Only mesures from own parcelles
            query = """
                SELECT m.*, c.type_capteur, p.nom as parcelle_nom
                FROM MESURE m
                JOIN CAPTEUR c ON m.capteur_id = c.capteur_id
                JOIN PARCELLE p ON c.parcelle_id = p.parcelle_id
                JOIN CHAMP ch ON p.champ_id = ch.champ_id
                WHERE ch.user_id = :user_id
            """
            params = {'user_id': user_id}
        else:
            # All mesures
            query = """
                SELECT m.*, c.type_capteur, p.nom as parcelle_nom
                FROM MESURE m
                JOIN CAPTEUR c ON m.capteur_id = c.capteur_id
                LEFT JOIN PARCELLE p ON c.parcelle_id = p.parcelle_id
                WHERE 1=1
            """
            params = {}
        
        if capteur_id:
            query += " AND m.capteur_id = :capteur_id"
            params['capteur_id'] = capteur_id
        
        if parcelle_id:
            query += " AND c.parcelle_id = :parcelle_id"
            params['parcelle_id'] = parcelle_id
        
        query += " ORDER BY m.date_mesure DESC FETCH FIRST :limit ROWS ONLY"
        params['limit'] = limit
        
        cursor.execute(query, params)
        
        columns = [d[0].lower() for d in cursor.description]
        mesures = [dict(zip(columns, row)) for row in cursor.fetchall()]
        
        return jsonify({'mesures': mesures}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()


@mesure_bp.route('/<int:mesure_id>', methods=['GET'])
@login_required
def get_mesure(mesure_id):
    """Get specific mesure details"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        query = """
            SELECT m.*, c.type_capteur, c.modele, p.nom as parcelle_nom
            FROM MESURE m
            JOIN CAPTEUR c ON m.capteur_id = c.capteur_id
            LEFT JOIN PARCELLE p ON c.parcelle_id = p.parcelle_id
            WHERE m.mesure_id = :mesure_id
        """
        cursor.execute(query, {'mesure_id': mesure_id})
        
        columns = [d[0].lower() for d in cursor.description]
        row = cursor.fetchone()
        
        if row:
            mesure = dict(zip(columns, row))
            return jsonify({'mesure': mesure}), 200
        else:
            return jsonify({'error': 'Mesure not found'}), 404
            
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()


@mesure_bp.route('/', methods=['POST'])
@role_required('ADMIN')  # Only admin can manually collect mesures
def collect_mesure():
    """Collect a new mesure using collecter_mesure procedure"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        required_fields = ['capteur_id', 'valeur']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Use collecter_mesure procedure
        cursor.callproc('COLLECTER_MESURE', [
            data['capteur_id'],
            data['valeur']
        ])
        conn.commit()
        
        return jsonify({'message': 'Mesure collected successfully'}), 201
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@mesure_bp.route('/capteur/<int:capteur_id>', methods=['GET'])
@login_required
def get_mesures_by_capteur(capteur_id):
    """Get all mesures for a specific capteur"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        limit = request.args.get('limit', 100)
        
        query = """
            SELECT m.*, c.type_capteur
            FROM MESURE m
            JOIN CAPTEUR c ON m.capteur_id = c.capteur_id
            WHERE m.capteur_id = :capteur_id
            ORDER BY m.date_mesure DESC
            FETCH FIRST :limit ROWS ONLY
        """
        cursor.execute(query, {'capteur_id': capteur_id, 'limit': limit})
        
        columns = [d[0].lower() for d in cursor.description]
        mesures = [dict(zip(columns, row)) for row in cursor.fetchall()]
        
        return jsonify({'mesures': mesures}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()
