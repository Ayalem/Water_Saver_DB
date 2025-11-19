from flask import Flask ,jsonify,request
from sqlalchemy import create_engine,text
from sqlalchemy.orm import sessionmaker
import oracledb
import os
from dotenv import load_dotenv
from models import Base
load_dotenv()
app=Flask(__name__)
connection_string = (
    f"oracle+oracledb://{os.getenv('ORACLE_USER')}:"
    f"{os.getenv('ORACLE_PASSWORD')}@"
    f"{os.getenv('ORACLE_HOST')}:{os.getenv('ORACLE_PORT')}/"
    f"?service_name={os.getenv('ORACLE_SERVICE')}"
)
engine=create_engine(connection_string,echo=True)
Session=sessionmaker(bind=engine)
@app.route('/health')
def health():
    """ Test the database connection"""
    try:
        with engine.connect() as conn:
            result=conn.execute(text("SELECT 1 FROM DUAL"))
            return jsonify({
                 "status":"connected",
                 "result":result.scalar()
            })
        
    except Exception as e:
        return jsonify({
             "status":"Error",
             "result":str(e)

            }),500

if __name__ == '__main__':
    app.run(debug=True, port=5000)