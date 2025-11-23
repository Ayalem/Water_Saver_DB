from flask import Blueprint, request, jsonify, session
from auth import login_required, role_required
import cx_Oracle
from database import get_db_connection

alerte_bp = Blueprint('alerte', __name__, url_prefix='/api/alertes')

@alerte_bp.route('/', methods=['GET'])
@login_required
def get_alertes():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        statut = request.args.get('statut')
        severite = request.args.get('severite')

        query = """
            SELECT a.*, p.nom as parcelle_nom, c.nom as champ_nom
            FROM ALERTE a
            JOIN PARCELLE p ON a.parcelle_id = p.parcelle_id
            JOIN CHAMP c ON p.champ_id = c.champ_id
            WHERE 1=1
        """
        params = {}

        if session['role'] == 'AGRICULTEUR':
            query += " AND c.user_id = :user_id"
            params['user_id'] = session['user_id']

        if statut:
            query += " AND a.statut = :statut"
            params['statut'] = statut

        if severite:
            query += " AND a.severite = :severite"
            params['severite'] = severite

        query += " ORDER BY a.date_detection DESC"

        cursor.execute(query, params)

        columns = [d[0].lower() for d in cursor.description]
        results = []
        for row in cursor.fetchall():
            results.append(dict(zip(columns, row)))

        return jsonify({'alertes': results}), 200

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500

    finally:
        cursor.close()
        conn.close()

@alerte_bp.route('/<int:alerte_id>/resolve', methods=['POST'])
@role_required('TECHNICIEN', 'ADMIN')
def resolve_alerte(alerte_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.callproc('PRC_RESOUDRE_ALERTE', [alerte_id, session['user_id']])

        return jsonify({'message': 'Alerte resolved'}), 200

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400

    finally:
        cursor.close()
        conn.close()
