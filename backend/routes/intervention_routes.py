from flask import Blueprint, request, jsonify, session
from database import get_db_connection
import oracledb
from auth import login_required, role_required

intervention_bp = Blueprint('intervention', __name__, url_prefix='/api/interventions')

@intervention_bp.route('/', methods=['GET'])
@login_required
def get_interventions():
    """
    Get interventions using voir_interventions procedure
    This ensures proper role-based filtering:
    - TECHNICIEN: Only assigned interventions
    - AGRICULTEUR: Interventions on their parcelles
    - ADMIN/INSPECTEUR: All interventions
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_role = session.get('role')
        user_id = session.get('user_id')
        
        # Use the voir_interventions procedure for role-based access
        result_cursor = cursor.var(oracledb.CURSOR)
        cursor.callproc('VOIR_INTERVENTIONS', [user_id, user_role, result_cursor])
        
        # Fetch results from the returned cursor
        interventions = []
        ref_cursor = result_cursor.getvalue()
        
        if ref_cursor:
            columns = [d[0].lower() for d in ref_cursor.description]
            for row in ref_cursor:
                interventions.append(dict(zip(columns, row)))
        
        return jsonify({'interventions': interventions}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    finally:
        cursor.close()
        conn.close()


@intervention_bp.route('/<int:intervention_id>', methods=['GET'])
@login_required
def get_intervention(intervention_id):
    """Get specific intervention details using view"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_role = session.get('role')
        user_id = session.get('user_id')
        
        # Use V_INTERVENTION_DETAILS view with role-based filtering
        query = "SELECT * FROM V_INTERVENTION_DETAILS WHERE intervention_id = :intervention_id"
        
        # Add access control based on role
        if user_role == 'TECHNICIEN':
            query += " AND technicien_id = :user_id"
            cursor.execute(query, {'intervention_id': intervention_id, 'user_id': user_id})
        elif user_role == 'AGRICULTEUR':
            # Agriculteur can see interventions on their parcelles
            query += """ AND parcelle_id IN (
                SELECT parcelle_id FROM PARCELLE p 
                JOIN CHAMP c ON p.champ_id = c.champ_id 
                WHERE c.user_id = :user_id
            )"""
            cursor.execute(query, {'intervention_id': intervention_id, 'user_id': user_id})
        else:  # ADMIN or INSPECTEUR
            cursor.execute(query, {'intervention_id': intervention_id})
        
        columns = [d[0].lower() for d in cursor.description]
        row = cursor.fetchone()
        
        if row:
            intervention = dict(zip(columns, row))
            return jsonify({'intervention': intervention}), 200
        else:
            return jsonify({'error': 'Intervention not found or access denied'}), 404
            
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 500
    
    finally:
        cursor.close()
        conn.close()


@intervention_bp.route('/<int:intervention_id>/assign', methods=['POST'])
@role_required('ADMIN')
def assign_intervention(intervention_id):
    """Assign intervention to a technician using procedure (ADMIN only)"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        technicien_id = data.get('technicien_id')
        
        if not technicien_id:
            return jsonify({'error': 'technicien_id is required'}), 400
        
        # Use assigner_intervention procedure
        # This procedure verifies the technician exists and has correct role
        cursor.callproc('ASSIGNER_INTERVENTION', [intervention_id, technicien_id])
        conn.commit()
        
        return jsonify({'message': 'Intervention assigned successfully'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        conn.rollback()
        return jsonify({'error': error_obj.message}), 400
    
    finally:
        cursor.close()
        conn.close()


@intervention_bp.route('/<int:intervention_id>/update-status', methods=['PUT'])
@role_required('TECHNICIEN', 'ADMIN')
def update_intervention_status(intervention_id):
    """Update intervention status (TECHNICIEN can update their own, ADMIN can update any)"""
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        user_role = session.get('role')
        user_id = session.get('user_id')
        new_status = data.get('statut')
        notes = data.get('notes')
        
        if not new_status:
            return jsonify({'error': 'statut is required'}), 400
        
        # Verify ownership if TECHNICIEN
        if user_role == 'TECHNICIEN':
            cursor.execute(
                "SELECT 1 FROM INTERVENTION WHERE intervention_id = :int_id AND technicien_id = :user_id",
                {'int_id': intervention_id, 'user_id': user_id}
            )
            if not cursor.fetchone():
                return jsonify({'error': 'Access denied - not your intervention'}), 403
        
        # Update intervention
        update_query = """
            UPDATE INTERVENTION
            SET statut = :status,
                notes = :notes,
                date_debut = CASE WHEN :status = 'EN_COURS' AND date_debut IS NULL THEN SYSTIMESTAMP ELSE date_debut END,
                date_fin = CASE WHEN :status = 'TERMINE' THEN SYSTIMESTAMP ELSE date_fin END
            WHERE intervention_id = :int_id
        """
        cursor.execute(update_query, {'status': new_status, 'notes': notes, 'int_id': intervention_id})
        
        conn.commit()
        
        return jsonify({'message': 'Intervention status updated'}), 200
        
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        return jsonify({'error': error_obj.message}), 400
    
    finally:
        cursor.close()
        conn.close()
