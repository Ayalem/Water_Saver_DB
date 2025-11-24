from flask import Blueprint, request, jsonify, session
from auth import login_required, role_required
import oracledb
from database import get_db_connection, fetch_cursor_results

champ_bp = Blueprint('champ', __name__, url_prefix='/api/champs')

@champ_bp.route('/', methods=['GET'])
@login_required
def get_champs():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # TECHNICIEN should NOT have access to champs
        if session['role'] == 'TECHNICIEN':
            return jsonify({'error': 'Access denied - technicians cannot view champs'}), 403
            
        if session['role'] == 'AGRICULTEUR':
            # Call the PL/SQL function that returns a REF CURSOR
            # The function LISTER_CHAMPS_UTILISATEUR is assumed to return a SYS_REFCURSOR
            ref_cursor = cursor.callfunc(
                'LISTER_CHAMPS_UTILISATEUR',
                oracledb.CURSOR,
                [session['user_id']]
            )
            results = fetch_cursor_results(ref_cursor)
            ref_cursor.close() # Close the ref cursor after fetching results
        else:
            # For other roles (ADMIN, INSPECTEUR), execute a direct SQL query
            cursor.execute("""
                SELECT c.*, u.nom as proprietaire_nom, u.prenom as proprietaire_prenom
                FROM CHAMP c
                JOIN UTILISATEUR u ON c.user_id = u.user_id
                ORDER BY c.date_creation DESC
            """)
            results = fetch_cursor_results(cursor) # Use the main cursor

        return jsonify({'champs': results}), 200

    except oracledb.DatabaseError as e:
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
        # Call the PL/SQL function that returns a REF CURSOR for a single champ
        ref_cursor = cursor.callfunc(
            'AFFICHER_DETAILS_CHAMP',
            oracledb.CURSOR,
            [champ_id]
        )
        results = fetch_cursor_results(ref_cursor)
        ref_cursor.close() # Close the ref cursor after fetching results

        if results:
            return jsonify({'champ': results[0]}), 200
        else:
            return jsonify({'message': 'Champ not found'}), 404

    except oracledb.DatabaseError as e:
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

        champ_id = cursor.var(oracledb.NUMBER)
        champ_id = cursor.callfunc(
            'CREATE_CHAMP',
            oracledb.NUMBER,
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
        
        conn.commit()  # Explicitly commit the transaction

        return jsonify({'message': 'Champ created', 'champ_id': int(champ_id)}), 201

    except oracledb.DatabaseError as e:
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
            bool,
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

    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400

    finally:
        cursor.close()
        conn.close()
