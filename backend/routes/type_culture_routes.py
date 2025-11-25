from flask import Blueprint, request, jsonify
from database import get_db_connection
import oracledb
from auth import login_required, role_required

type_culture_bp = Blueprint('type_culture', __name__, url_prefix='/api/type-cultures')

@type_culture_bp.route('/', methods=['GET'])
@login_required
def get_type_cultures():
    """Get all type cultures"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        query = """
            SELECT tc.*, 
                   (SELECT COUNT(*) FROM PARCELLE WHERE type_culture_id = tc.type_culture_id) as nb_parcelles
            FROM TYPE_CULTURE tc
            ORDER BY tc.nom
        """
        cursor.execute(query)
        
        columns = [d[0].lower() for d in cursor.description]
        type_cultures = [dict(zip(columns, row)) for row in cursor.fetchall()]
        
        return jsonify({'type_cultures': type_cultures}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()


@type_culture_bp.route('/<int:type_culture_id>', methods=['GET'])
@login_required
def get_type_culture(type_culture_id):
    """Get specific type culture details"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        query = """
            SELECT tc.*,
                   (SELECT COUNT(*) FROM PARCELLE WHERE type_culture_id = tc.type_culture_id) as nb_parcelles
            FROM TYPE_CULTURE tc
            WHERE tc.type_culture_id = :type_culture_id
        """
        cursor.execute(query, {'type_culture_id': type_culture_id})
        
        columns = [d[0].lower() for d in cursor.description]
        row = cursor.fetchone()
        
        if row:
            type_culture = dict(zip(columns, row))
            return jsonify({'type_culture': type_culture}), 200
        else:
            return jsonify({'error': 'Type culture not found'}), 404
            
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()


@type_culture_bp.route('/', methods=['POST'])
@role_required('ADMIN', 'AGRICULTEUR')
def create_type_culture():
    """Create a new type culture using ajouter_type_culture procedure"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        required_fields = ['nom', 'categorie', 'duree_croissance_jours']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Use ajouter_type_culture procedure
        cursor.callproc('AJOUTER_TYPE_CULTURE', [
            data['nom'],
            data['categorie'],
            data['duree_croissance_jours'],
            data.get('rendement_moyen_tonne_hectare'),
            data.get('saison_ideale')
        ])
        conn.commit()
        
        return jsonify({'message': 'Type culture created successfully'}), 201
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@type_culture_bp.route('/<int:type_culture_id>', methods=['PUT'])
@role_required('ADMIN')
def update_type_culture(type_culture_id):
    """Update type culture details"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Build update query dynamically
        update_fields = []
        params = {'type_culture_id': type_culture_id}
        
        if 'nom' in data:
            update_fields.append("nom = :nom")
            params['nom'] = data['nom']
        
        if 'categorie' in data:
            update_fields.append("categorie = :categorie")
            params['categorie'] = data['categorie']
        
        if 'duree_croissance_jours' in data:
            update_fields.append("duree_croissance_jours = :duree")
            params['duree'] = data['duree_croissance_jours']
        
        if 'rendement_moyen_tonne_hectare' in data:
            update_fields.append("rendement_moyen_tonne_hectare = :rendement")
            params['rendement'] = data['rendement_moyen_tonne_hectare']
        
        if 'saison_ideale' in data:
            update_fields.append("saison_ideale = :saison")
            params['saison'] = data['saison_ideale']
        
        if not update_fields:
            return jsonify({'error': 'No fields to update'}), 400
        
        query = f"UPDATE TYPE_CULTURE SET {', '.join(update_fields)} WHERE type_culture_id = :type_culture_id"
        cursor.execute(query, params)
        conn.commit()
        
        return jsonify({'message': 'Type culture updated successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()


@type_culture_bp.route('/<int:type_culture_id>', methods=['DELETE'])
@role_required('ADMIN')
def delete_type_culture(type_culture_id):
    """Delete type culture (only if not used)"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Check if type culture is used
        cursor.execute(
            "SELECT COUNT(*) FROM PARCELLE WHERE type_culture_id = :id",
            {'id': type_culture_id}
        )
        count = cursor.fetchone()[0]
        
        if count > 0:
            return jsonify({'error': f'Cannot delete: {count} parcelles use this type culture'}), 400
        
        cursor.execute(
            "DELETE FROM TYPE_CULTURE WHERE type_culture_id = :id",
            {'id': type_culture_id}
        )
        conn.commit()
        
        return jsonify({'message': 'Type culture deleted successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    finally:
        cursor.close()
        conn.close()
