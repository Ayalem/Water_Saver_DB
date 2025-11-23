import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

    ORACLE_HOST = os.getenv('ORACLE_HOST', 'localhost')
    ORACLE_PORT = os.getenv('ORACLE_PORT', '1521')
    ORACLE_SERVICE = os.getenv('ORACLE_SERVICE', 'ORCL')
    ORACLE_USER = os.getenv('ORACLE_USER', 'app_user')
    ORACLE_PASSWORD = os.getenv('ORACLE_PASSWORD', 'app_pass')

    @property
    def ORACLE_DSN(self):
        return f"{self.ORACLE_HOST}:{self.ORACLE_PORT}/{self.ORACLE_SERVICE}"

    SESSION_TYPE = 'filesystem'
    SESSION_PERMANENT = False
    PERMANENT_SESSION_LIFETIME = 3600
