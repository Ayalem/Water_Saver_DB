import oracledb
import os
from config import Config

config = Config()

# Set NLS_LANG for UTF-8 encoding
os.environ['NLS_LANG'] = 'AMERICAN_AMERICA.AL32UTF8'

def get_db_connection():
    try:
        connection = oracledb.connect(
            user=config.ORACLE_USER,
            password=config.ORACLE_PASSWORD,
            dsn=config.ORACLE_DSN
        )
        
        # Set VPD context if user is logged in
        from flask import session
        if 'user_id' in session and 'role' in session:
            cursor = connection.cursor()
            try:
                plsql = """
                BEGIN
                    DBMS_SESSION.SET_CONTEXT('USER_CTX', 'USER_ID', :uid);
                    DBMS_SESSION.SET_CONTEXT('USER_CTX', 'ROLE', :role);
                END;
                """
                cursor.execute(plsql, {'uid': str(session['user_id']), 'role': session['role']})
                cursor.close()
            except Exception as e:
                print(f"Warning: Could not set VPD context: {e}")
                cursor.close()
        
        return connection
    except oracledb.Error as error:
        print(f"Database connection error: {error}")
        raise

def execute_procedure(proc_name, params=None):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        if params:
            cursor.callproc(proc_name, params)
        else:
            cursor.callproc(proc_name)
        conn.commit()
        return True
    except oracledb.Error as error:
        conn.rollback()
        raise error
    finally:
        cursor.close()
        conn.close()

def execute_function(func_name, return_type, params=None):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        result = cursor.var(return_type)
        if params:
            cursor.callfunc(func_name, return_type, params)
        else:
            cursor.callfunc(func_name, return_type)
        return result.getvalue()
    except oracledb.Error as error:
        raise error
    finally:
        cursor.close()
        conn.close()

def fetch_cursor_results(cursor_var):
    results = []
    for row in cursor_var:
        results.append(dict(zip([d[0].lower() for d in cursor_var.description], row)))
    return results

def execute_query(query, params=None, fetchone=False):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)

        if fetchone:
            result = cursor.fetchone()
            if result:
                columns = [d[0].lower() for d in cursor.description]
                return dict(zip(columns, result))
            return None
        else:
            results = []
            columns = [d[0].lower() for d in cursor.description]
            for row in cursor.fetchall():
                results.append(dict(zip(columns, row)))
            return results
    except oracledb.Error as error:
        raise error
    finally:
        cursor.close()
        conn.close()
