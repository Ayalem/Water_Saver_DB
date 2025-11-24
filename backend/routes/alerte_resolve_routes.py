from flask import Blueprint, request, jsonify, session
from database import get_db_connection
import oracledb
from auth import login_required, role_required

alerte_resolve_bp = Blueprint('alerte_resolve', __name__)

@alerte_resolve_bp.route('/alertes/<int:alerte_id>/resolve', methods=['PUT'])
@role_required('ADMIN', 'TECHNICIEN')
def resolve_alerte(alerte_id):
    """
    Resolve an alert (ADMIN or TECHNICIEN only)
    Uses PRC_RESOUDRE_ALERTE stored procedure
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_id = session.get('user_id')
        
        # Call stored procedure to resolve alert
        cursor.callproc('PRC_RESOUDRE_ALERTE', [alerte_id, user_id])
        
        conn.commit()
        
        return jsonify({'message': 'Alert resolved successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400
    
    finally:
        cursor.close()
        conn.close()
