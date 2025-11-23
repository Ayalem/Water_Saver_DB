import cx_Oracle
from config import Config

config = Config()

def get_db_connection():
    try:
        connection = cx_Oracle.connect(
            config.ORACLE_USER,
            config.ORACLE_PASSWORD,
            config.ORACLE_DSN
        )
        return connection
    except cx_Oracle.Error as error:
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
    except cx_Oracle.Error as error:
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
    except cx_Oracle.Error as error:
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
    except cx_Oracle.Error as error:
        raise error
    finally:
        cursor.close()
        conn.close()
