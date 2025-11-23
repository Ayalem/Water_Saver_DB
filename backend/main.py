from flask import Flask, jsonify
from flask_cors import CORS
from flask_session import Session
from config import Config

app = Flask(__name__)
app.config.from_object(Config)

CORS(app, supports_credentials=True, origins=['http://localhost:3000', 'http://127.0.0.1:3000'])
Session(app)

from routes.auth_routes import auth_bp
from routes.champ_routes import champ_bp
from routes.parcelle_routes import parcelle_bp
from routes.alerte_routes import alerte_bp
from routes.notification_routes import notification_bp

app.register_blueprint(auth_bp)
app.register_blueprint(champ_bp)
app.register_blueprint(parcelle_bp)
app.register_blueprint(alerte_bp)
app.register_blueprint(notification_bp)

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'message': 'WaterSaver API is running'}), 200

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
