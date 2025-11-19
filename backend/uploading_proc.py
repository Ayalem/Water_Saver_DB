import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
load_dotenv()
connection_string = (
    f"oracle+oracledb://{os.getenv('ORACLE_USER')}:"
    f"{os.getenv('ORACLE_PASSWORD')}@"
    f"{os.getenv('ORACLE_HOST')}:{os.getenv('ORACLE_PORT')}/"
    f"?service_name={os.getenv('ORACLE_SERVICE')}"
)
engine=create_engine(connection_string,echo=True)
sql_root = "sql_scripts"

# Loop through procedure folders
for table_folder in sorted(os.listdir(sql_root)):
    folder_path = os.path.join(sql_root, table_folder)
    if os.path.isdir(folder_path):
        for file in sorted(os.listdir(folder_path)):
            if file.endswith(".sql"):
                # Skip any CREATE TABLE scripts just in case
                if "CREATE TABLE" in open(os.path.join(folder_path, file)).read():
                    print(f"Skipping {file} (DDL)")
                    continue

                with open(os.path.join(folder_path, file), "r") as f:
                    sql = f.read()
                with engine.connect() as conn:
                    try:
                        conn.execute(text(sql))
                        print(f"Executed {file} in {table_folder}")
                        conn.commit()   
                        print(f"commited{file} in {table_folder}") 
                    except Exception as e:
                        print(f"Error executing {file}: {e}")
