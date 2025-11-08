
# WaterSaver_PL_SQL 💧

**Projet académique : Gestion intelligente des ressources hydriques**
Langage principal : **PL/SQL**
Équipe : 4 membres

---

## 🌟 **Description du projet**

WaterSaver est une solution de gestion de l’irrigation et des interventions techniques dans les exploitations agricoles.
Le projet repose sur une **base de données relationnelle complète** permettant de gérer :

* Les utilisateurs multi-rôles : AGRICULTEUR, TECHNICIEN, INSPECTEUR, ADMIN
* Les  champs et parcelles
* Les capteurs IoT et la collecte de mesures en temps réel
* Les seuils et alertes automatiques
* Les interventions techniques planifiées
* Les rapports et notifications automatisées

L’objectif est de fournir une **gestion automatisée et fiable** des ressources hydriques avec des **procédures, triggers et vues PL/SQL robustes**.

---

## 🗂️ **Structure du projet**

```
WaterSaver_PL_SQL/
│
├── sql_scripts/                  # Scripts SQL principaux
│   ├── 1_creation_bd/            # Création des tables et contraintes
│   ├── 2_authentification/      # Procédures et triggers de login
│   ├── 3_notifications_alertes/ # Alertes et notifications
│   ├── 4_interventions/         # Gestion interventions
│   ├── 5_rapports/              # Procédures et vues pour rapports
│   └── data_inserts/            # Jeux de données initiaux
│
├── tests/                        # Scripts de tests unitaires
├── documentation/                # Schémas, manuel utilisateur et rapport final
      ├── diagrams/                       # Diagrammes MCD/MLD et flowcharts
├── README.md                       # Ce fichier
├── CONTRIBUTING.md                 # Règles de collaboration
└── .gitignore                      # Fichiers à ignorer dans Git
```

---

## ⚙️ **Fonctionnalités principales**

1. **Authentification multi-rôles** avec gestion des statuts et tentatives de connexion
2. **Création et gestion des exploitations, champs et parcelles**
3. **Gestion des capteurs IoT** (humidité, débit, pression…)
4. **Alertes automatiques** quand les seuils sont dépassés
5. **Notifications aux utilisateurs** (techniciens et agriculteurs)
6. **Planification et suivi des interventions techniques**
7. **Rapports générés automatiquement** pour analyse et suivi

---


---

## 🚀 **Installation & Déploiement**

1. Cloner le repository :

```bash
git clone https://github.com/aya-lemzouri/WaterSaver_PL_SQL.git
```

2. Importer les scripts SQL de `1_creation_bd/` dans votre instance Oracle.

3. Exécuter les scripts dans l’ordre :

```bash
# Création des tables
@sql_scripts/1_creation_bd/create_utilisateur.sql
# Création des triggers et procédures
@sql_scripts/2_authentification/procedures_login.sql
# … et ainsi de suite
```

4. Insérer les données initiales depuis `data_inserts/`.


## 📄 **Documentation**

* `documentation/schema_MCD_MLD.png` → Diagrammes conceptuel et logique
* `documentation/manuel_utilisation.md` → Guide utilisateur
* `documentation/rapport_final.pdf` → Rapport de projet




