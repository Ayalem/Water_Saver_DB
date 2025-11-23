from flask import Blueprint, request, jsonify, session
from auth import login_required, role_required
import cx_Oracle
from database import get_db_connection, fetch_cursor_results

champ_bp = Blueprint('champ', __name__, url_prefix='/api/champs')

@champ_bp.route('/', methods=['GET'])
@login_required
def get_champs():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if session['role'] == 'AGRICULTEUR':
            result_cursor = cursor.var(cx_Oracle.CURSOR)
            cursor.callfunc(
                'LISTER_CHAMPS_UTILISATEUR',
                cx_Oracle.CURSOR,
                [session['user_id'], None]
            )
            result_cursor = cursor.fetchone()[0]
        else:
            cursor.execute("""
                SELECT c.*, u.nom as proprietaire_nom, u.prenom as proprietaire_prenom
                FROM CHAMP c
                JOIN UTILISATEUR u ON c.user_id = u.user_id
                ORDER BY c.date_creation DESC
            """)
            result_cursor = cursor

        columns = [d[0].lower() for d in result_cursor.description]
        results = []
        for row in result_cursor:
            results.append(dict(zip(columns, row)))

        return jsonify({'champs': results}), 200

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500

    finally:
        cursor.close()
        conn.close()

@champ_bp.route('/<int:champ_id>', methods=['GET'])
@login_required
def get_champ(champ_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        result_cursor = cursor.var(cx_Oracle.CURSOR)
        cursor.callfunc(
            'AFFICHER_DETAILS_CHAMP',
            cx_Oracle.CURSOR,
            [champ_id]
        )
        result_cursor = cursor.fetchone()[0]

        columns = [d[0].lower() for d in result_cursor.description]
        row = result_cursor.fetchone()

        if row:
            champ = dict(zip(columns, row))
            return jsonify({'champ': champ}), 200
        else:
            return jsonify({'error': 'Champ not found'}), 404

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500

    finally:
        cursor.close()
        conn.close()

@champ_bp.route('/', methods=['POST'])
@role_required('AGRICULTEUR', 'ADMIN')
def create_champ():
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        user_id = session['user_id'] if session['role'] == 'AGRICULTEUR' else data.get('user_id')

        champ_id = cursor.var(cx_Oracle.NUMBER)
        champ_id = cursor.callfunc(
            'CREATE_CHAMP',
            cx_Oracle.NUMBER,
            [
                user_id,
                data['nom'],
                data['superficie'],
                data.get('type_champs'),
                data.get('type_sol'),
                data.get('systeme_irrigation'),
                data.get('adresse'),
                data.get('region'),
                data.get('ville'),
                data.get('code_postal'),
                data.get('latitude'),
                data.get('longitude'),
                data.get('date_plantation')
            ]
        )

        return jsonify({'message': 'Champ created', 'champ_id': int(champ_id)}), 201

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400

    finally:
        cursor.close()
        conn.close()

@champ_bp.route('/<int:champ_id>', methods=['PUT'])
@role_required('AGRICULTEUR', 'ADMIN')
def update_champ(champ_id):
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        success = cursor.callfunc(
            'UPDATE_CHAMP',
            cx_Oracle.NUMBER,
            [
                champ_id,
                data.get('nom'),
                data.get('superficie'),
                data.get('type_champs'),
                data.get('type_sol'),
                data.get('systeme_irrigation'),
                data.get('adresse'),
                data.get('region'),
                data.get('ville'),
                data.get('code_postal'),
                data.get('latitude'),
                data.get('longitude'),
                data.get('date_plantation'),
                data.get('statut')
            ]
        )

        if success:
            return jsonify({'message': 'Champ updated'}), 200
        else:
            return jsonify({'error': 'Champ not found'}), 404

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400

    finally:
        cursor.close()
        conn.close()
