from flask import Blueprint, request, jsonify, session
from database import get_db_connection
import oracledb
from auth import login_required, role_required

rapport_bp = Blueprint('rapport', __name__)

@rapport_bp.route('/', methods=['GET'])
@login_required
def get_rapports():
    """
    Get rapports based on user role:
    - AGRICULTEUR: Only their own rapports (for their champs)
    - INSPECTEUR: All rapports (read-only)
    - ADMIN: All rapports
    - TECHNICIEN: No access
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_role = session.get('role')
        user_id = session.get('user_id')
        
        if user_role == 'AGRICULTEUR':
            # Only rapports for own champs
            query = """
                SELECT r.rapport_id, r.type_rapport, r.date_debut, r.date_fin, 
                       r.date_generation,
                       c.nom as champ_nom, c.champ_id
                FROM RAPPORT r
                LEFT JOIN CHAMP c ON r.champ_id = c.champ_id
                WHERE r.user_id = :user_id
                ORDER BY r.date_generation DESC
            """
            cursor.execute(query, {'user_id': user_id})
            
        elif user_role in ['INSPECTEUR', 'ADMIN']:
            # All rapports
            query = """
                SELECT r.rapport_id, r.type_rapport, r.date_debut, r.date_fin,
                       r.date_generation,
                       c.nom as champ_nom, c.champ_id,
                       u.nom || ' ' || u.prenom as agriculteur_nom
                FROM RAPPORT r
                LEFT JOIN CHAMP c ON r.champ_id = c.champ_id
                LEFT JOIN UTILISATEUR u ON r.user_id = u.user_id
                ORDER BY r.date_generation DESC
            """
            cursor.execute(query)
            
        else:
            # TECHNICIEN has no access to rapports
            return jsonify({'error': 'Access denied'}), 403
        
        columns = [d[0].lower() for d in cursor.description]
        rapports = []
        for row in cursor.fetchall():
            rapport = dict(zip(columns, row))
            rapports.append(rapport)
        
        return jsonify({'rapports': rapports}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    
    finally:
        cursor.close()
        conn.close()


@rapport_bp.route('/<int:rapport_id>', methods=['GET'])
@login_required
def get_rapport(rapport_id):
    """Get a specific rapport - role-based access"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_role = session.get('role')
        user_id = session.get('user_id')
        
        if user_role == 'AGRICULTEUR':
            # Only own rapports
            query = """
                SELECT r.*, c.nom as champ_nom
                FROM RAPPORT r
                LEFT JOIN CHAMP c ON r.champ_id = c.champ_id
                WHERE r.rapport_id = :rapport_id AND r.user_id = :user_id
            """
            cursor.execute(query, {'rapport_id': rapport_id, 'user_id': user_id})
            
        elif user_role in ['INSPECTEUR', 'ADMIN']:
            # All rapports
            query = """
                SELECT r.*, c.nom as champ_nom,
                       u.nom || ' ' || u.prenom as agriculteur_nom
                FROM RAPPORT r
                LEFT JOIN CHAMP c ON r.champ_id = c.champ_id
                LEFT JOIN UTILISATEUR u ON r.user_id = u.user_id
                WHERE r.rapport_id = :rapport_id
            """
            cursor.execute(query, {'rapport_id': rapport_id})
            
        else:
            return jsonify({'error': 'Access denied'}), 403
        
        columns = [d[0].lower() for d in cursor.description]
        row = cursor.fetchone()
        
        if row:
            rapport = dict(zip(columns, row))
            return jsonify({'rapport': rapport}), 200
        else:
            return jsonify({'error': 'Rapport not found'}), 404
            
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    
    finally:
        cursor.close()
        conn.close()


@rapport_bp.route('/generate', methods=['POST'])
@role_required('AGRICULTEUR', 'ADMIN')
def generate_rapport():
    """
    Generate a new rapport using PRC_GENERER_RAPPORT_AUDIT_FINAL
    - AGRICULTEUR: Can generate rapports for their own champs
    - ADMIN: Can generate rapports for any champ
    """
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_role = session.get('role')
        user_id = session.get('user_id')
        champ_id = data.get('champ_id')
        type_rapport = data.get('type_rapport', 'AUDIT_ADHOC')
        date_debut = data.get('date_debut')
        date_fin = data.get('date_fin')
        
        if not champ_id or not date_debut or not date_fin:
            return jsonify({'error': 'champ_id, date_debut, and date_fin are required'}), 400
        
        # Verify ownership if AGRICULTEUR
        if user_role == 'AGRICULTEUR':
            cursor.execute(
                "SELECT 1 FROM CHAMP WHERE champ_id = :champ_id AND user_id = :user_id",
                {'champ_id': champ_id, 'user_id': user_id}
            )
            if not cursor.fetchone():
                return jsonify({'error': 'Access denied - not your champ'}), 403
        
        # Call existing stored procedure PRC_GENERER_RAPPORT_AUDIT_FINAL
        cursor.callproc('PRC_GENERER_RAPPORT_AUDIT_FINAL', [
            user_id,
            champ_id,
            type_rapport,
            date_debut,
            date_fin
        ])
        
        conn.commit()
        
        return jsonify({
            'message': 'Rapport generated successfully',
            'type_rapport': type_rapport
        }), 201
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400
    
    finally:
        cursor.close()
        conn.close()
