from flask import Blueprint, request, jsonify, session
from auth import login_required
import cx_Oracle
from database import get_db_connection

notification_bp = Blueprint('notification', __name__, url_prefix='/api/notifications')

@notification_bp.route('/', methods=['GET'])
@login_required
def get_notifications():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        lue = request.args.get('lue')

        query = """
            SELECT n.*
            FROM NOTIFICATION n
            WHERE n.user_id = :user_id
        """
        params = {'user_id': session['user_id']}

        if lue:
            query += " AND n.lue = :lue"
            params['lue'] = lue

        query += " ORDER BY n.date_envoi DESC"

        cursor.execute(query, params)

        columns = [d[0].lower() for d in cursor.description]
        results = []
        for row in cursor.fetchall():
            results.append(dict(zip(columns, row)))

        return jsonify({'notifications': results}), 200

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500

    finally:
        cursor.close()
        conn.close()

@notification_bp.route('/<int:notification_id>/mark-read', methods=['POST'])
@login_required
def mark_notification_read(notification_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.callproc('PRC_MARQUER_LUE', [notification_id, session['user_id']])

        return jsonify({'message': 'Notification marked as read'}), 200

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400

    finally:
        cursor.close()
        conn.close()

@notification_bp.route('/count-unread', methods=['GET'])
@login_required
def count_unread():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT COUNT(*) as count
            FROM NOTIFICATION
            WHERE user_id = :user_id AND lue = 'NON'
        """, {'user_id': session['user_id']})

        result = cursor.fetchone()
        count = result[0] if result else 0

        return jsonify({'count': count}), 200

    except cx_Oracle.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500

    finally:
        cursor.close()
        conn.close()
