from flask import Flask, request, jsonify
from passlib.context import CryptContext
import cx_Oracle
import os

app = Flask(__name__)

# Config passlib : bcrypt ou argon2
pwd_context = CryptContext(schemes=["bcrypt"], bcrypt__rounds=12) 

# Connexion Oracle (compte technique)
DSN = "host:1521/ORCL"
DB_USER = "app_user"
DB_PASS = "app_pass"

def get_db_conn():
    return cx_Oracle.connect(DB_USER, DB_PASS, DSN)

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    login = data['login']
    password = data['password']
    nom = data.get('nom')
    prenom = data.get('prenom')
    email = data.get('email')
    role = data.get('role', 'AGRICULTEUR') 

    # 1) Hash côté application
    password_hash = pwd_context.hash(password) 

    # 2) Appeler procédure CREER_UTILISATEUR ou insert direct
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO UTILISATEUR (login, password_hash, nom, prenom, email, role)
            VALUES (:login, :phash, :nom, :prenom, :email, :role)
        """, {
            'login': login,
            'phash': password_hash,
            'nom': nom,
            'prenom': prenom,
            'email': email,
            'role': role
        })
        conn.commit()
    finally:
        cur.close()
        conn.close()

    return jsonify({"message": "Utilisateur créé"}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    login = data['login']
    password = data['password']

    conn = get_db_conn()
    cur = conn.cursor()
    cur.execute("SELECT user_id, password_hash, role FROM UTILISATEUR WHERE login = :login", {'login': login})
    row = cur.fetchone()
    cur.close()
    conn.close()

    if not row:
        return jsonify({"error":"Invalid credentials"}), 401

    user_id, password_hash_db, role = row

    # Vérifier le mot de passe
    if not pwd_context.verify(password, password_hash_db):
        return jsonify({"error":"Invalid credentials"}), 401

    # OK -> créer session / JWT, etc.
    return jsonify({"message":"Logged in", "user_id": user_id, "role": role})
