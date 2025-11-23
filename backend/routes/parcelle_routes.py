from flask import Blueprint, request, jsonify, session
from auth import login_required, role_required
import cx_Oracle
from database import get_db_connection

parcelle_bp = Blueprint('parcelle', __name__, url_prefix='/api/parcelles')

@parcelle_bp.route('/', methods=['GET'])
@login_required
def get_parcelles():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
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
        results = []
        for row in cursor.fetchall():
            results.append(dict(zip(columns, row)))

        return jsonify({'parcelles': results}), 200

    except cx_Oracle.DatabaseError as e:
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
        result_cursor = cursor.var(cx_Oracle.CURSOR)
        cursor.callfunc(
            'GET_PARCELLE_BY_ID',
            cx_Oracle.CURSOR,
            [parcelle_id]
        )
        result_cursor = cursor.fetchone()[0]

        columns = [d[0].lower() for d in result_cursor.description]
        row = result_cursor.fetchone()

        if row:
            parcelle = dict(zip(columns, row))
            return jsonify({'parcelle': parcelle}), 200
        else:
            return jsonify({'error': 'Parcelle not found'}), 404

    except cx_Oracle.DatabaseError as e:
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
            cx_Oracle.NUMBER,
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

        return jsonify({'message': 'Parcelle created', 'parcelle_id': int(parcelle_id)}), 201

    except cx_Oracle.DatabaseError as e:
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
            cx_Oracle.NUMBER,
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

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400

    finally:
        cursor.close()
        conn.close()
