from typing import Optional
import datetime
import decimal

from sqlalchemy import CheckConstraint, DateTime, Enum, ForeignKeyConstraint, Identity, Index, LargeBinary, PrimaryKeyConstraint, TIMESTAMP, Text, VARCHAR, text
from sqlalchemy.dialects.oracle import NUMBER
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

class Base(DeclarativeBase):
    pass




class TypeCulture(Base):
    __tablename__ = 'type_culture'
    __table_args__ = (
        PrimaryKeyConstraint('type_culture_id', name='sys_c008671'),
        Index('sys_c008672', 'nom', unique=True),
        {'comment': 'Référentiel des types de cultures avec leurs caractéristiques'}
    )

    type_culture_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    nom: Mapped[str] = mapped_column(VARCHAR(50), nullable=False)
    categorie: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    cycle_croissance_jours: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    coefficient_cultural_kc: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(3, 2, True))
    description: Mapped[Optional[str]] = mapped_column(VARCHAR(500))
    date_creation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE\n'))

    seuil_culture: Mapped[list['SeuilCulture']] = relationship('SeuilCulture', back_populates='type_culture')
    parcelle: Mapped[list['Parcelle']] = relationship('Parcelle', back_populates='type_culture')


class Utilisateur(Base):
    __tablename__ = 'utilisateur'
    __table_args__ = (
        PrimaryKeyConstraint('user_id', name='sys_c008659'),
        Index('sys_c008661', 'email', unique=True)
    )

    user_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    password_hash: Mapped[str] = mapped_column(VARCHAR(64), nullable=False)
    nom: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    prenom: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    email: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    role: Mapped[str] = mapped_column(Enum('AGRICULTEUR', 'TECHNICIEN', 'INSPECTEUR', 'ADMIN'), nullable=False)
    telephone: Mapped[Optional[str]] = mapped_column(VARCHAR(20))
    statut: Mapped[Optional[str]] = mapped_column(Enum('ACTIF', 'INACTIF', 'BLOQUE'), server_default=text("'ACTIF' "))
    region_affectation: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    tentatives_echec: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False), server_default=text('0'))
    date_derniere_connexion: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    date_creation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE'))
    date_modification: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    champ: Mapped[list['Champ']] = relationship('Champ', back_populates='user')
    rapport: Mapped[list['Rapport']] = relationship('Rapport', back_populates='user')
    alerte: Mapped[list['Alerte']] = relationship('Alerte', back_populates='utilisateur')
    intervention: Mapped[list['Intervention']] = relationship('Intervention', back_populates='technicien')
    notification: Mapped[list['Notification']] = relationship('Notification', back_populates='user')


class Champ(Base):
    __tablename__ = 'champ'
    __table_args__ = (
        ForeignKeyConstraint(['user_id'], ['utilisateur.user_id'], name='sys_c008668'),
        PrimaryKeyConstraint('champ_id', name='sys_c008667'),
        {'comment': 'Zone de culture principale appartenant à un agriculteur'}
    )

    champ_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    user_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    nom: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    superficie: Mapped[decimal.Decimal] = mapped_column(NUMBER(10, 2, True), nullable=False)
    type_champs: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    type_sol: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    systeme_irrigation: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    adresse: Mapped[Optional[str]] = mapped_column(VARCHAR(200))
    region: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    ville: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    code_postal: Mapped[Optional[str]] = mapped_column(VARCHAR(10))
    latitude: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(10, 7, True))
    longitude: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(10, 7, True))
    date_plantation: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime)
    statut: Mapped[Optional[str]] = mapped_column(Enum('ACTIF', 'INACTIF', 'EN_REPOS'), server_default=text("'ACTIF' "))
    date_creation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE'))
    date_modification: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    user: Mapped['Utilisateur'] = relationship('Utilisateur', back_populates='champ')
    parcelle: Mapped[list['Parcelle']] = relationship('Parcelle', back_populates='champ')
    rapport: Mapped[list['Rapport']] = relationship('Rapport', back_populates='champ')




class SeuilCulture(Base):
    __tablename__ = 'seuil_culture'
    __table_args__ = (
        ForeignKeyConstraint(['type_culture_id'], ['type_culture.type_culture_id'], name='sys_c008688'),
        PrimaryKeyConstraint('seuil_id', name='sys_c008686'),
        Index('sys_c008687', 'type_culture_id', 'type_seuil', 'stade_croissance', unique=True),
        {'comment': 'Seuils de mesures recommandés par type de culture et stade de '
                'croissance'}
    )

    seuil_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    type_culture_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    type_seuil: Mapped[str] = mapped_column(VARCHAR(50), nullable=False)
    seuil_min: Mapped[decimal.Decimal] = mapped_column(NUMBER(10, 2, True), nullable=False)
    seuil_max: Mapped[decimal.Decimal] = mapped_column(NUMBER(10, 2, True), nullable=False)
    unite_mesure: Mapped[Optional[str]] = mapped_column(VARCHAR(10))
    tolerance_pourcentage: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(5, 2, True), server_default=text('5'))
    stade_croissance: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    date_application: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE'))
    date_modification: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    type_culture: Mapped['TypeCulture'] = relationship('TypeCulture', back_populates='seuil_culture')




class Parcelle(Base):
    __tablename__ = 'parcelle'
    __table_args__ = (
        ForeignKeyConstraint(['champ_id'], ['champ.champ_id'], name='sys_c008679'),
        ForeignKeyConstraint(['type_culture_id'], ['type_culture.type_culture_id'], name='sys_c008680'),
        PrimaryKeyConstraint('parcelle_id', name='sys_c008678'),
        {'comment': "Subdivision d'un champ équipée de capteurs IoT avec une culture "
                'spécifique'}
    )

    parcelle_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    champ_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    nom: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    superficie: Mapped[decimal.Decimal] = mapped_column(NUMBER(10, 2, True), nullable=False)
    type_culture_id: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    latitude: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(10, 7, True))
    longitude: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(10, 7, True))
    date_plantation: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime)
    date_recolte_prevue: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime)
    statut: Mapped[Optional[str]] = mapped_column(Enum('ACTIVE', 'INACTIVE', 'EN_REPOS'), server_default=text("'ACTIVE' "))
    date_creation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE'))
    date_modification: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    champ: Mapped['Champ'] = relationship('Champ', back_populates='parcelle')
    type_culture: Mapped[Optional['TypeCulture']] = relationship('TypeCulture', back_populates='parcelle')
    capteur: Mapped[list['Capteur']] = relationship('Capteur', back_populates='parcelle')
    alerte: Mapped[list['Alerte']] = relationship('Alerte', back_populates='parcelle')
    intervention: Mapped[list['Intervention']] = relationship('Intervention', back_populates='parcelle')


class Rapport(Base):
    __tablename__ = 'rapport'
    __table_args__ = (
        ForeignKeyConstraint(['champ_id'], ['champ.champ_id'], name='sys_c008735'),
        ForeignKeyConstraint(['user_id'], ['utilisateur.user_id'], name='sys_c008734'),
        PrimaryKeyConstraint('rapport_id', name='sys_c008733'),
        {'comment': 'Rapports générés pour analyse des données'}
    )

    rapport_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    user_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    champ_id: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    type_rapport: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    date_debut: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime)
    date_fin: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime)
    contenu: Mapped[Optional[str]] = mapped_column(Text)
    date_generation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE\n'))

    champ: Mapped[Optional['Champ']] = relationship('Champ', back_populates='rapport')
    user: Mapped['Utilisateur'] = relationship('Utilisateur', back_populates='rapport')


class Capteur(Base):
    __tablename__ = 'capteur'
    __table_args__ = (
        CheckConstraint('niveau_batterie BETWEEN 0 AND 100', name='sys_c008694'),
        ForeignKeyConstraint(['parcelle_id'], ['parcelle.parcelle_id'], name='sys_c008697'),
        PrimaryKeyConstraint('capteur_id', name='sys_c008695'),
        Index('sys_c008696', 'numero_serie', unique=True),
        {'comment': 'Capteurs IoT installés sur les parcelles pour la collecte de '
                'données'}
    )

    capteur_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    parcelle_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    numero_serie: Mapped[str] = mapped_column(VARCHAR(50), nullable=False)
    type_capteur: Mapped[str] = mapped_column(VARCHAR(50), nullable=False)
    modele: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    statut: Mapped[Optional[str]] = mapped_column(Enum('ACTIF', 'INACTIF', 'EN_PANNE', 'MAINTENANCE'), server_default=text("'ACTIF' "))
    niveau_batterie: Mapped[Optional[float]] = mapped_column(NUMBER(3, 0, False))
    frequence_mesure: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False), server_default=text('15'))
    date_installation: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime)
    date_derniere_mesure: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    date_derniere_maintenance: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    date_creation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE\n'))

    parcelle: Mapped['Parcelle'] = relationship('Parcelle', back_populates='capteur')
    mesure: Mapped[list['Mesure']] = relationship('Mesure', back_populates='capteur')
    intervention: Mapped[list['Intervention']] = relationship('Intervention', back_populates='capteur')


class Mesure(Base):
    __tablename__ = 'mesure'
    __table_args__ = (
        CheckConstraint('qualite_signal BETWEEN 0 AND 100', name='sys_c008701'),
        ForeignKeyConstraint(['capteur_id'], ['capteur.capteur_id'], name='sys_c008704'),
        PrimaryKeyConstraint('mesure_id', name='sys_c008703'),
        {'comment': 'Données collectées en temps réel par les capteurs'}
    )

    mesure_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    capteur_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    date_mesure: Mapped[datetime.datetime] = mapped_column(TIMESTAMP, nullable=False, server_default=text('SYSDATE '))
    type_mesure: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    valeur_mesure: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(10, 2, True))
    unite_mesure: Mapped[Optional[str]] = mapped_column(VARCHAR(10))
    qualite_signal: Mapped[Optional[float]] = mapped_column(NUMBER(3, 0, False))
    anomalie_detectee: Mapped[Optional[str]] = mapped_column(Enum('OUI', 'NON'), server_default=text("'NON' "))
    date_creation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE\n'))

    capteur: Mapped['Capteur'] = relationship('Capteur', back_populates='mesure')
    alerte: Mapped[list['Alerte']] = relationship('Alerte', back_populates='mesure')


class Alerte(Base):
    __tablename__ = 'alerte'
    __table_args__ = (
        CheckConstraint("type_alerte IN (\n    'DEPASSEMENT_DEBIT', \n    'DEPASSEMENT_PRESSION', \n    'HUMIDITE_BASSE', \n    'HUMIDITE_HAUTE',\n    'FUITE', \n    'CAPTEUR_DEFAILLANT',\n    'BATTERIE_FAIBLE',\n    'SURCONSOMMATION'\n  )", name='sys_c008710'),
        ForeignKeyConstraint(['mesure_id'], ['mesure.mesure_id'], name='sys_c008716'),
        ForeignKeyConstraint(['parcelle_id'], ['parcelle.parcelle_id'], name='sys_c008717'),
        ForeignKeyConstraint(['resolu_par'], ['utilisateur.user_id'], name='sys_c008718'),
        PrimaryKeyConstraint('alerte_id', name='sys_c008715'),
        {'comment': 'Alertes générées automatiquement lors de dépassement de seuils'}
    )

    alerte_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    parcelle_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    type_alerte: Mapped[str] = mapped_column(VARCHAR(50), nullable=False)
    severite: Mapped[str] = mapped_column(Enum('INFO', 'ATTENTION', 'HAUTE', 'CRITIQUE'), nullable=False)
    date_detection: Mapped[datetime.datetime] = mapped_column(TIMESTAMP, nullable=False, server_default=text('SYSDATE '))
    mesure_id: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    description: Mapped[Optional[str]] = mapped_column(VARCHAR(500))
    valeur_mesuree: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(10, 2, True))
    valeur_seuil: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(10, 2, True))
    pourcentage_depassement: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(5, 2, True))
    date_resolution: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    duree_minutes: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    statut: Mapped[Optional[str]] = mapped_column(Enum('ACTIVE', 'EN_COURS', 'RESOLUE', 'IGNOREE'), server_default=text("'ACTIVE' "))
    resolu_par: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    notifie_agriculteur: Mapped[Optional[str]] = mapped_column(Enum('OUI', 'NON'), server_default=text("'NON' "))
    notifie_technicien: Mapped[Optional[str]] = mapped_column(Enum('OUI', 'NON'), server_default=text("'NON' "))
    date_notification_tech: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    mesure: Mapped[Optional['Mesure']] = relationship('Mesure', back_populates='alerte')
    parcelle: Mapped['Parcelle'] = relationship('Parcelle', back_populates='alerte')
    utilisateur: Mapped[Optional['Utilisateur']] = relationship('Utilisateur', back_populates='alerte')
    intervention: Mapped[list['Intervention']] = relationship('Intervention', back_populates='alerte')
    notification: Mapped[list['Notification']] = relationship('Notification', back_populates='alerte')


class Intervention(Base):
    __tablename__ = 'intervention'
    __table_args__ = (
        CheckConstraint("type_intervention IN (\n    'REPARATION_FUITE', \n    'MAINTENANCE_CAPTEUR', \n    'REMPLACEMENT_PIECE', \n    'REMPLACEMENT_CAPTEUR',\n    'CALIBRATION', \n    'INSPECTION',\n    'REMPLACEMENT_BATTERIE',\n    'AUTRE'\n  )", name='sys_c008723'),
        ForeignKeyConstraint(['alerte_id'], ['alerte.alerte_id'], name='sys_c008727'),
        ForeignKeyConstraint(['capteur_id'], ['capteur.capteur_id'], name='sys_c008729'),
        ForeignKeyConstraint(['parcelle_id'], ['parcelle.parcelle_id'], name='sys_c008728'),
        ForeignKeyConstraint(['technicien_id'], ['utilisateur.user_id'], name='sys_c008730'),
        PrimaryKeyConstraint('intervention_id', name='sys_c008726'),
        {'comment': 'Interventions techniques planifiées ou en réponse aux alertes'}
    )

    intervention_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    parcelle_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    type_intervention: Mapped[str] = mapped_column(VARCHAR(50), nullable=False)
    priorite: Mapped[str] = mapped_column(Enum('BASSE', 'MOYENNE', 'HAUTE', 'URGENTE'), nullable=False)
    alerte_id: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    capteur_id: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    technicien_id: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    statut: Mapped[Optional[str]] = mapped_column(Enum('EN_ATTENTE', 'ASSIGNEE', 'EN_COURS', 'TERMINE', 'ANNULEE'), server_default=text("'EN_ATTENTE' "))
    description: Mapped[Optional[str]] = mapped_column(VARCHAR(500))
    date_creation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE'))
    date_assignation: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    date_debut: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    date_fin: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    duree_minutes: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    cout_intervention: Mapped[Optional[decimal.Decimal]] = mapped_column(NUMBER(10, 2, True))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    signature_technicien: Mapped[Optional[bytes]] = mapped_column(LargeBinary)

    alerte: Mapped[Optional['Alerte']] = relationship('Alerte', back_populates='intervention')
    capteur: Mapped[Optional['Capteur']] = relationship('Capteur', back_populates='intervention')
    parcelle: Mapped['Parcelle'] = relationship('Parcelle', back_populates='intervention')
    technicien: Mapped[Optional['Utilisateur']] = relationship('Utilisateur', back_populates='intervention')
    notification: Mapped[list['Notification']] = relationship('Notification', back_populates='intervention')


class Notification(Base):
    __tablename__ = 'notification'
    __table_args__ = (
        CheckConstraint("type_notification IN (\n    'ALERTE_DEPASSEMENT',\n    'ALERTE_FUITE',\n    'INTERVENTION_ASSIGNEE',\n    'INTERVENTION_TERMINEE',\n    'RAPPORT_DISPONIBLE',\n    'BATTERIE_FAIBLE',\n    'CAPTEUR_DEFAILLANT',\n    'SYSTEME'\n  )", name='sys_c008740'),
        ForeignKeyConstraint(['alerte_id'], ['alerte.alerte_id'], name='sys_c008744'),
        ForeignKeyConstraint(['intervention_id'], ['intervention.intervention_id'], name='sys_c008745'),
        ForeignKeyConstraint(['user_id'], ['utilisateur.user_id'], name='sys_c008743'),
        PrimaryKeyConstraint('notification_id', name='sys_c008742'),
        {'comment': 'Notifications envoyées aux utilisateurs'}
    )

    notification_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(always=True, on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    user_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    type_notification: Mapped[str] = mapped_column(VARCHAR(50), nullable=False)
    message: Mapped[str] = mapped_column(VARCHAR(1000), nullable=False)
    alerte_id: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    intervention_id: Mapped[Optional[float]] = mapped_column(NUMBER(asdecimal=False))
    lue: Mapped[Optional[str]] = mapped_column(Enum('OUI', 'NON'), server_default=text("'NON' "))
    date_envoi: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSDATE'))
    date_lecture: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    alerte: Mapped[Optional['Alerte']] = relationship('Alerte', back_populates='notification')
    intervention: Mapped[Optional['Intervention']] = relationship('Intervention', back_populates='notification')
    user: Mapped['Utilisateur'] = relationship('Utilisateur', back_populates='notification')
