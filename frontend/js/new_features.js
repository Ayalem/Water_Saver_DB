// Capteurs, Mesures, Type Cultures, and User Management functionality

// ============================================================================
// CAPTEURS
// ============================================================================

async function loadCapteurs() {
    try {
        const response = await api.capteurs.getAll();
        const capteurs = response.capteurs || [];

        const container = document.getElementById('capteurs-list');
        if (capteurs.length === 0) {
            container.innerHTML = '<p class="no-data">Aucun capteur trouvé</p>';
            return;
        }

        container.innerHTML = capteurs.map(capteur => `
            <div class="data-card">
                <div class="data-header">
                    <h3>Capteur #${capteur.capteur_id} - ${capteur.type_capteur}</h3>
                    <span class="badge ${capteur.statut === 'ACTIF' ? 'badge-success' : 'badge-warning'}">
                        ${capteur.statut}
                    </span>
                </div>
                <div class="data-body">
                    <p><strong>Modèle:</strong> ${capteur.modele}</p>
                    <p><strong>Parcelle:</strong> ${capteur.parcelle_nom || 'N/A'}</p>
                    <p><strong>Batterie:</strong> ${capteur.niveau_batterie || 0}%</p>
                    <p><strong>Installation:</strong> ${new Date(capteur.date_installation).toLocaleDateString()}</p>
                </div>
                <div class="data-actions" id="capteur-actions-${capteur.capteur_id}">
                    <button onclick="performMaintenance(${capteur.capteur_id})" class="btn btn-secondary btn-sm">
                        🔧 Maintenance
                    </button>
                    <button onclick="viewCapteurMesures(${capteur.capteur_id})" class="btn btn-primary btn-sm">
                        📊 Voir Mesures
                    </button>
                </div>
            </div>
        `).join('');

        // Hide actions based on role
        hideElementsByRole('capteur-actions');

    } catch (error) {
        handleError(error);
    }
}

async function performMaintenance(capteurId) {
    const batteryLevel = prompt('Nouveau niveau de batterie (0-100):', '100');
    if (!batteryLevel) return;

    try {
        await api.capteurs.maintenance(capteurId, { nouveau_niveau_batterie: parseInt(batteryLevel) });
        showAlert('Maintenance effectuée avec succès', 'success');
        loadCapteurs();
    } catch (error) {
        handleError(error);
    }
}

function viewCapteurMesures(capteurId) {
    showSection('mesures');
    document.getElementById('capteur-filter').value = capteurId;
    loadMesures();
}

// ============================================================================
// MESURES
// ============================================================================

async function loadMesures() {
    try {
        const capteurId = document.getElementById('capteur-filter')?.value;
        const limit = document.getElementById('limit-filter')?.value || 100;

        const params = { limit };
        if (capteurId) params.capteur_id = capteurId;

        const response = await api.mesures.getAll(params);
        const mesures = response.mesures || [];

        const container = document.getElementById('mesures-list');
        if (mesures.length === 0) {
            container.innerHTML = '<p class="no-data">Aucune mesure trouvée</p>';
            return;
        }

        container.innerHTML = mesures.map(mesure => `
            <div class="data-card">
                <div class="data-header">
                    <h3>${mesure.type_capteur} - ${mesure.parcelle_nom || 'N/A'}</h3>
                    <span class="badge badge-info">${new Date(mesure.date_mesure).toLocaleString()}</span>
                </div>
                <div class="data-body">
                    <p><strong>Valeur:</strong> ${mesure.valeur} ${getUnitForType(mesure.type_capteur)}</p>
                    <p><strong>Capteur ID:</strong> ${mesure.capteur_id}</p>
                </div>
            </div>
        `).join('');

        // Load capteur options for filter
        loadCapteurFilter();

    } catch (error) {
        handleError(error);
    }
}

async function loadCapteurFilter() {
    try {
        const response = await api.capteurs.getAll();
        const capteurs = response.capteurs || [];

        const select = document.getElementById('capteur-filter');
        if (!select) return;

        const currentValue = select.value;
        select.innerHTML = '<option value="">Tous les capteurs</option>' +
            capteurs.map(c => `<option value="${c.capteur_id}">Capteur #${c.capteur_id} - ${c.type_capteur}</option>`).join('');
        select.value = currentValue;
    } catch (error) {
        console.error('Error loading capteur filter:', error);
    }
}

function getUnitForType(type) {
    const units = {
        'HUMIDITE': '%',
        'TEMPERATURE': '°C',
        'PH': '',
        'CONDUCTIVITE': 'mS/cm'
    };
    return units[type] || '';
}

// ============================================================================
// TYPE CULTURES
// ============================================================================

async function loadTypeCultures() {
    try {
        const response = await api.typeCultures.getAll();
        const typeCultures = response.type_cultures || [];

        const container = document.getElementById('type-cultures-list');
        if (typeCultures.length === 0) {
            container.innerHTML = '<p class="no-data">Aucun type de culture trouvé</p>';
            return;
        }

        container.innerHTML = typeCultures.map(tc => `
            <div class="data-card">
                <div class="data-header">
                    <h3>${tc.nom}</h3>
                    <span class="badge badge-success">${tc.categorie}</span>
                </div>
                <div class="data-body">
                    <p><strong>Durée croissance:</strong> ${tc.duree_croissance_jours} jours</p>
                    <p><strong>Rendement moyen:</strong> ${tc.rendement_moyen_tonne_hectare || 'N/A'} t/ha</p>
                    <p><strong>Saison idéale:</strong> ${tc.saison_ideale || 'N/A'}</p>
                    <p><strong>Parcelles utilisant:</strong> ${tc.nb_parcelles || 0}</p>
                </div>
                <div class="data-actions" id="type-culture-actions-${tc.type_culture_id}">
                    <button onclick="editTypeCulture(${tc.type_culture_id})" class="btn btn-secondary btn-sm">
                        ✏️ Modifier
                    </button>
                    <button onclick="deleteTypeCulture(${tc.type_culture_id}, ${tc.nb_parcelles})" class="btn btn-danger btn-sm">
                        🗑️ Supprimer
                    </button>
                </div>
            </div>
        `).join('');

        hideElementsByRole('type-culture-actions');

    } catch (error) {
        handleError(error);
    }
}

async function deleteTypeCulture(id, nbParcelles) {
    if (nbParcelles > 0) {
        showAlert(`Impossible de supprimer: ${nbParcelles} parcelle(s) utilisent ce type`, 'error');
        return;
    }

    if (!confirm('Êtes-vous sûr de vouloir supprimer ce type de culture?')) return;

    try {
        await api.typeCultures.delete(id);
        showAlert('Type de culture supprimé', 'success');
        loadTypeCultures();
    } catch (error) {
        handleError(error);
    }
}

// ============================================================================
// USER MANAGEMENT (ADMIN)
// ============================================================================

async function loadUsers() {
    try {
        const response = await api.users.getAll();
        const users = response.users || [];

        const container = document.getElementById('users-list');
        if (users.length === 0) {
            container.innerHTML = '<p class="no-data">Aucun utilisateur trouvé</p>';
            return;
        }

        container.innerHTML = users.map(user => `
            <div class="data-card">
                <div class="data-header">
                    <h3>${user.nom} ${user.prenom}</h3>
                    <span class="badge ${user.statut === 'ACTIF' ? 'badge-success' : 'badge-danger'}">
                        ${user.statut}
                    </span>
                </div>
                <div class="data-body">
                    <p><strong>Email:</strong> ${user.email}</p>
                    <p><strong>Rôle:</strong> ${user.role}</p>
                    <p><strong>Téléphone:</strong> ${user.telephone || 'N/A'}</p>
                    <p><strong>Région:</strong> ${user.region_affectation || 'N/A'}</p>
                    <p><strong>Créé le:</strong> ${new Date(user.date_creation).toLocaleDateString()}</p>
                </div>
                <div class="data-actions">
                    <select onchange="changeUserStatus(${user.user_id}, this.value)" class="select-sm">
                        <option value="">Changer statut...</option>
                        <option value="ACTIF">Activer</option>
                        <option value="INACTIVE">Désactiver</option>
                    </select>
                    <select onchange="changeUserRole(${user.user_id}, this.value)" class="select-sm">
                        <option value="">Changer rôle...</option>
                        <option value="AGRICULTEUR">Agriculteur</option>
                        <option value="TECHNICIEN">Technicien</option>
                        <option value="INSPECTEUR">Inspecteur</option>
                        <option value="ADMIN">Admin</option>
                    </select>
                    <button onclick="deleteUser(${user.user_id}, '${user.email}')" class="btn btn-danger btn-sm">
                        🗑️ Supprimer
                    </button>
                </div>
            </div>
        `).join('');

    } catch (error) {
        handleError(error);
    }
}

async function changeUserStatus(userId, newStatus) {
    if (!newStatus) return;

    try {
        await api.users.updateStatus(userId, newStatus);
        showAlert('Statut utilisateur mis à jour', 'success');
        loadUsers();
    } catch (error) {
        handleError(error);
    }
}

async function changeUserRole(userId, newRole) {
    if (!newRole) return;

    if (!confirm(`Êtes-vous sûr de vouloir changer le rôle vers ${newRole}?`)) return;

    try {
        await api.users.updateRole(userId, newRole);
        showAlert('Rôle utilisateur mis à jour', 'success');
        loadUsers();
    } catch (error) {
        handleError(error);
    }
}

async function deleteUser(userId, email) {
    if (!confirm(`Êtes-vous sûr de vouloir supprimer l'utilisateur ${email}?`)) return;

    try {
        await api.users.delete(userId);
        showAlert('Utilisateur supprimé', 'success');
        loadUsers();
    } catch (error) {
        handleError(error);
    }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function hideElementsByRole(prefix) {
    const userRole = sessionStorage.getItem('userRole');

    // Hide admin-only actions for non-admins
    if (userRole !== 'ADMIN') {
        document.querySelectorAll(`[id^="${prefix}"]`).forEach(el => {
            const deleteBtn = el.querySelector('.btn-danger');
            if (deleteBtn) deleteBtn.style.display = 'none';
        });
    }

    // Hide technician actions for non-technicians/admins
    if (userRole !== 'TECHNICIEN' && userRole !== 'ADMIN') {
        document.querySelectorAll(`[id^="${prefix}"]`).forEach(el => {
            const maintenanceBtn = el.querySelector('.btn-secondary');
            if (maintenanceBtn && maintenanceBtn.textContent.includes('Maintenance')) {
                maintenanceBtn.style.display = 'none';
            }
        });
    }
}
