from flask import Blueprint, request, jsonify, session
from auth import login_required, role_required
import oracledb
from database import get_db_connection

parcelle_bp = Blueprint('parcelle', __name__, url_prefix='/api/parcelles')

@parcelle_bp.route('/', methods=['GET'])
@login_required
def get_parcelles():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # TECHNICIEN should NOT have access to parcelles
        if session['role'] == 'TECHNICIEN':
            return jsonify({'error': 'Access denied - technicians cannot view parcelles'}), 403
            
        champ_id = request.args.get('champ_id')

        if champ_id:
            cursor.execute("""
                SELECT p.*, tc.nom as type_culture_nom
                FROM PARCELLE p
                LEFT JOIN TYPE_CULTURE tc ON p.type_culture_id = tc.type_culture_id
                WHERE p.champ_id = :champ_id
                ORDER BY p.date_creation DESC
            """, {'champ_id': champ_id})
        else:
            cursor.execute("""
                SELECT p.*, tc.nom as type_culture_nom, c.nom as champ_nom
                FROM PARCELLE p
                LEFT JOIN TYPE_CULTURE tc ON p.type_culture_id = tc.type_culture_id
                JOIN CHAMP c ON p.champ_id = c.champ_id
                ORDER BY p.date_creation DESC
            """)

        columns = [d[0].lower() for d in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]

        return jsonify({'parcelles': results}), 200

    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500

    finally:
        cursor.close()
        conn.close()

@parcelle_bp.route('/<int:parcelle_id>', methods=['GET'])
@login_required
def get_parcelle(parcelle_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Call the function and get the cursor
        result_cursor = cursor.callfunc(
            'GET_PARCELLE_BY_ID',
            oracledb.CURSOR,
            [parcelle_id]
        )

        # Fetch from the returned cursor
        columns = [d[0].lower() for d in result_cursor.description]
        row = result_cursor.fetchone()

        if row:
            parcelle = dict(zip(columns, row))
            return jsonify({'parcelle': parcelle}), 200
        else:
            return jsonify({'error': 'Parcelle not found'}), 404

    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500

    finally:
        cursor.close()
        conn.close()

@parcelle_bp.route('/', methods=['POST'])
@role_required('AGRICULTEUR', 'ADMIN')
def create_parcelle():
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        parcelle_id = cursor.callfunc(
            'CREATE_PARCELLE',
            oracledb.NUMBER,
            [
                data['champ_id'],
                data.get('type_culture_id'),
                data['nom'],
                data['superficie'],
                data.get('latitude'),
                data.get('longitude'),
                data.get('date_plantation'),
                data.get('date_recolte_prevue')
            ]
        )
        
        conn.commit()  # Explicitly commit the transaction

        return jsonify({'message': 'Parcelle created', 'parcelle_id': int(parcelle_id)}), 201

    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400

    finally:
        cursor.close()
        conn.close()

@parcelle_bp.route('/<int:parcelle_id>', methods=['PUT'])
@role_required('AGRICULTEUR', 'ADMIN')
def update_parcelle(parcelle_id):
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        success = cursor.callfunc(
            'UPDATE_PARCELLE',
            bool,
            [
                parcelle_id,
                data.get('type_culture_id'),
                data.get('nom'),
                data.get('superficie'),
                data.get('latitude'),
                data.get('longitude'),
                data.get('date_plantation'),
                data.get('date_recolte_prevue'),
                data.get('statut')
            ]
        )

        if success:
            return jsonify({'message': 'Parcelle updated'}), 200
        else:
            return jsonify({'error': 'Parcelle not found'}), 404

    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400

    finally:
        cursor.close()
        conn.close()
