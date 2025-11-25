from flask import Blueprint, request, jsonify, session
from database import get_db_connection
import oracledb
from auth import login_required, role_required

capteur_bp = Blueprint('capteur', __name__, url_prefix='/api/capteurs')

@capteur_bp.route('/', methods=['GET'])
@login_required
def get_capteurs():
    """Get all capteurs (filtered by role)"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_role = session.get('role')
        user_id = session.get('user_id')
        
        if user_role == 'AGRICULTEUR':
            # Only capteurs on own parcelles
            query = """
                SELECT c.*, p.nom as parcelle_nom, ch.nom as champ_nom
                FROM CAPTEUR c
                LEFT JOIN PARCELLE p ON c.parcelle_id = p.parcelle_id
                LEFT JOIN CHAMP ch ON p.champ_id = ch.champ_id
                WHERE ch.user_id = :user_id
                ORDER BY c.date_installation DESC
            """
            cursor.execute(query, {'user_id': user_id})
        else:
            # TECHNICIEN, INSPECTEUR, ADMIN see all
            query = """
                SELECT c.*, p.nom as parcelle_nom, ch.nom as champ_nom,
                       u.nom || ' ' || u.prenom as agriculteur_nom
                FROM CAPTEUR c
                LEFT JOIN PARCELLE p ON c.parcelle_id = p.parcelle_id
                LEFT JOIN CHAMP ch ON p.champ_id = ch.champ_id
                LEFT JOIN UTILISATEUR u ON ch.user_id = u.user_id
                ORDER BY c.date_installation DESC
            """
            cursor.execute(query)
        
        columns = [d[0].lower() for d in cursor.description]
        capteurs = [dict(zip(columns, row)) for row in cursor.fetchall()]
        
        return jsonify({'capteurs': capteurs}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()


@capteur_bp.route('/<int:capteur_id>', methods=['GET'])
@login_required
def get_capteur(capteur_id):
    """Get specific capteur details"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        query = """
            SELECT c.*, p.nom as parcelle_nom, ch.nom as champ_nom
            FROM CAPTEUR c
            LEFT JOIN PARCELLE p ON c.parcelle_id = p.parcelle_id
            LEFT JOIN CHAMP ch ON p.champ_id = ch.champ_id
            WHERE c.capteur_id = :capteur_id
        """
        cursor.execute(query, {'capteur_id': capteur_id})
        
        columns = [d[0].lower() for d in cursor.description]
        row = cursor.fetchone()
        
        if row:
            capteur = dict(zip(columns, row))
            return jsonify({'capteur': capteur}), 200
        else:
            return jsonify({'error': 'Capteur not found'}), 404
            
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()


@capteur_bp.route('/', methods=['POST'])
@role_required('ADMIN', 'TECHNICIEN')
def install_capteur():
    """Install a new capteur using installer_capteur procedure"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        required_fields = ['parcelle_id', 'type_capteur', 'modele']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Use installer_capteur procedure
        cursor.callproc('INSTALLER_CAPTEUR', [
            data['parcelle_id'],
            data['type_capteur'],
            data['modele'],
            data.get('niveau_batterie', 100)
        ])
        conn.commit()
        
        return jsonify({'message': 'Capteur installed successfully'}), 201
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@capteur_bp.route('/<int:capteur_id>/maintenance', methods=['PUT'])
@role_required('TECHNICIEN', 'ADMIN')
def maintenance_capteur_route(capteur_id):
    """Perform maintenance on capteur using maintenance_capteur procedure"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Use maintenance_capteur procedure
        cursor.callproc('MAINTENANCE_CAPTEUR', [
            capteur_id,
            data.get('nouveau_niveau_batterie', 100)
        ])
        conn.commit()
        
        return jsonify({'message': 'Maintenance completed successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@capteur_bp.route('/<int:capteur_id>', methods=['PUT'])
@role_required('ADMIN', 'TECHNICIEN')
def update_capteur(capteur_id):
    """Update capteur details"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Build update query dynamically based on provided fields
        update_fields = []
        params = {'capteur_id': capteur_id}
        
        if 'statut' in data:
            update_fields.append("statut = :statut")
            params['statut'] = data['statut']
        
        if 'niveau_batterie' in data:
            update_fields.append("niveau_batterie = :niveau_batterie")
            params['niveau_batterie'] = data['niveau_batterie']
        
        if 'parcelle_id' in data:
            update_fields.append("parcelle_id = :parcelle_id")
            params['parcelle_id'] = data['parcelle_id']
        
        if not update_fields:
            return jsonify({'error': 'No fields to update'}), 400
        
        query = f"UPDATE CAPTEUR SET {', '.join(update_fields)} WHERE capteur_id = :capteur_id"
        cursor.execute(query, params)
        conn.commit()
        
        return jsonify({'message': 'Capteur updated successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@capteur_bp.route('/<int:capteur_id>', methods=['DELETE'])
@role_required('ADMIN')
def uninstall_capteur(capteur_id):
    """Uninstall capteur (set status to DESINSTALLE)"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute(
            "UPDATE CAPTEUR SET statut = 'DESINSTALLE', date_desinstallation = SYSTIMESTAMP WHERE capteur_id = :id",
            {'id': capteur_id}
        )
        conn.commit()
        
        return jsonify({'message': 'Capteur uninstalled successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()
