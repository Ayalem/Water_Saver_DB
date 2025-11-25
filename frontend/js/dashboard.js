let currentUser = null;

async function init() {
    try {
        const result = await api.auth.getMe();
        currentUser = result.user;

        document.getElementById('user-info').textContent =
            `${currentUser.prenom} ${currentUser.nom} (${currentUser.role})`;

        // Show admin menu for ADMIN users
        if (currentUser.role === 'ADMIN') {
            document.getElementById('admin-users-link').style.display = 'block';
        }

        // Store role in sessionStorage for role-based UI
        sessionStorage.setItem('userRole', currentUser.role);

        loadDashboard();
        loadNotificationCount();

        setInterval(loadNotificationCount, 30000);
    } catch (error) {
        window.location.href = 'index.html';
    }
}

async function loadDashboard() {
    try {
        const [champs, parcelles, alertes, notifications] = await Promise.all([
            api.champs.getAll(),
            api.parcelles.getAll(),
            api.alertes.getAll({ statut: 'ACTIVE' }),
            api.notifications.countUnread()
        ]);

        document.getElementById('total-champs').textContent = champs.champs.length;
        document.getElementById('total-parcelles').textContent = parcelles.parcelles.length;
        document.getElementById('total-alertes').textContent = alertes.alertes.length;
        document.getElementById('total-notifications').textContent = notifications.count;
    } catch (error) {
        handleError(error);
    }
}

async function loadChamps() {
    try {
        const result = await api.champs.getAll();
        const container = document.getElementById('champs-list');

        if (result.champs.length === 0) {
            container.innerHTML = '<p>Aucun champ trouvé</p>';
            return;
        }

        container.innerHTML = result.champs.map(champ => `
            <div class="data-card">
                <h3>${champ.nom}</h3>
                <div class="data-card-info">
                    <div class="info-item">
                        <span class="info-label">Superficie</span>
                        <span class="info-value">${champ.superficie} ha</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Type</span>
                        <span class="info-value">${champ.type_champs || 'N/A'}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Région</span>
                        <span class="info-value">${champ.region || 'N/A'}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Statut</span>
                        <span class="badge badge-success">${champ.statut}</span>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        handleError(error);
    }
}

async function loadParcelles() {
    try {
        const result = await api.parcelles.getAll();
        const container = document.getElementById('parcelles-list');

        if (result.parcelles.length === 0) {
            container.innerHTML = '<p>Aucune parcelle trouvée</p>';
            return;
        }

        container.innerHTML = result.parcelles.map(parcelle => `
            <div class="data-card">
                <h3>${parcelle.nom}</h3>
                <div class="data-card-info">
                    <div class="info-item">
                        <span class="info-label">Champ</span>
                        <span class="info-value">${parcelle.champ_nom}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Superficie</span>
                        <span class="info-value">${parcelle.superficie} ha</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Culture</span>
                        <span class="info-value">${parcelle.type_culture_nom || 'N/A'}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Statut</span>
                        <span class="badge badge-success">${parcelle.statut}</span>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        handleError(error);
    }
}

async function loadAlertes() {
    try {
        const statut = document.getElementById('alerte-statut-filter')?.value || '';
        const severite = document.getElementById('alerte-severite-filter')?.value || '';

        const filters = {};
        if (statut) filters.statut = statut;
        if (severite) filters.severite = severite;

        const result = await api.alertes.getAll(filters);
        const container = document.getElementById('alertes-list');

        if (result.alertes.length === 0) {
            container.innerHTML = '<p>Aucune alerte trouvée</p>';
            return;
        }

        container.innerHTML = result.alertes.map(alerte => {
            const severityClass = alerte.severite === 'CRITIQUE' ? 'danger' :
                alerte.severite === 'HAUTE' ? 'warning' : 'info';
            const statusClass = alerte.statut === 'RESOLUE' ? 'success' : 'warning';

            return `
                <div class="data-card">
                    <div style="display: flex; justify-content: space-between; align-items: start;">
                        <div>
                            <h3>${alerte.type_alerte}</h3>
                            <span class="badge badge-${severityClass}">${alerte.severite}</span>
                            <span class="badge badge-${statusClass}">${alerte.statut}</span>
                        </div>
                        ${alerte.statut !== 'RESOLUE' && currentUser.role === 'TECHNICIEN' ?
                    `<button onclick="resolveAlerte(${alerte.alerte_id})" class="btn btn-success">Résoudre</button>` : ''}
                    </div>
                    <div class="data-card-info" style="margin-top: 12px;">
                        <div class="info-item">
                            <span class="info-label">Parcelle</span>
                            <span class="info-value">${alerte.parcelle_nom}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Champ</span>
                            <span class="info-value">${alerte.champ_nom}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Date</span>
                            <span class="info-value">${new Date(alerte.date_detection).toLocaleString()}</span>
                        </div>
                    </div>
                    ${alerte.description ? `<p style="margin-top: 12px; color: var(--text-secondary);">${alerte.description}</p>` : ''}
                </div>
            `;
        }).join('');
    } catch (error) {
        handleError(error);
    }
}

async function loadNotifications() {
    try {
        const result = await api.notifications.getAll();
        const container = document.getElementById('notifications-list');

        if (result.notifications.length === 0) {
            container.innerHTML = '<p>Aucune notification</p>';
            return;
        }

        container.innerHTML = result.notifications.map(notif => `
            <div class="notification-item ${notif.lue === 'NON' ? 'unread' : ''}"
                 onclick="markNotificationRead(${notif.notification_id})">
                <div class="notification-header">
                    <span class="notification-type">${notif.type_notification}</span>
                    <span class="notification-date">${new Date(notif.date_envoi).toLocaleString()}</span>
                </div>
                <div class="notification-message">${notif.message}</div>
            </div>
        `).join('');
    } catch (error) {
        handleError(error);
    }
}

async function loadNotificationCount() {
    try {
        const result = await api.notifications.countUnread();
        const badge = document.getElementById('notif-badge');

        if (result.count > 0) {
            badge.textContent = result.count;
            badge.style.display = 'inline-block';
        } else {
            badge.style.display = 'none';
        }
    } catch (error) {
        console.error('Failed to load notification count:', error);
    }
}

async function markNotificationRead(id) {
    try {
        await api.notifications.markRead(id);
        loadNotifications();
        loadNotificationCount();
    } catch (error) {
        handleError(error);
    }
}

async function resolveAlerte(id) {
    if (!confirm('Voulez-vous marquer cette alerte comme résolue?')) return;

    ```
    try {
        await api.alertes.resolve(id);
        showAlert('Alerte résolue avec succès', 'success');
        loadAlertes();
        loadDashboard();
    } catch (error) {
        handleError(error);
    }
}

function showSection(sectionName) {
    console.log('Showing section:', sectionName);
    
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(function(section) {
        section.style.display = 'none';
    });
    
    // Remove active class from all nav links
    document.querySelectorAll('.nav-menu a').forEach(function(link) {
        link.classList.remove('active');
    });
    
    // Show selected section
    var sectionId = sectionName + '-section';
    var section = document.getElementById(sectionId);
    if (section) {
        section.style.display = 'block';
        
        // Add active class to corresponding nav link
        var selector = '.nav-menu a[onclick*="' + sectionName + '"]';
        var navLink = document.querySelector(selector);
        if (navLink) {
            navLink.classList.add('active');
        }
        
        // Load data for the section
        switch(sectionName) {
            case 'dashboard':
                loadDashboard();
                break;
            case 'champs':
                loadChamps();
                break;
            case 'parcelles':
                loadParcelles();
                break;
            case 'alertes':
                loadAlertes();
                break;
            case 'interventions':
                loadInterventions();
                break;
            case 'rapports':
                loadRapports();
                break;
            case 'notifications':
                loadNotifications();
                break;
            case 'capteurs':
                loadCapteurs();
                break;
            case 'mesures':
                loadMesures();
                break;
            case 'type-cultures':
                loadTypeCultures();
                break;
            case 'users':
                loadUsers();
                break;
        }
    }
}
        function showCreateChampModal() {
            const modal = document.getElementById('modal');
            const modalBody = document.getElementById('modal-body');

            modalBody.innerHTML = `
        < h2 > Nouveau Champ</h2 >
            <form id="createChampForm">
                <div class="form-group">
                    <label>Nom</label>
                    <input type="text" id="champ-nom" required>
                </div>
                <div class="form-group">
                    <label>Superficie (ha)</label>
                    <input type="number" step="0.01" id="champ-superficie" required>
                </div>
                <div class="form-group">
                    <label>Type de champ</label>
                    <input type="text" id="champ-type">
                </div>
                <div class="form-group">
                    <label>Région</label>
                    <input type="text" id="champ-region">
                </div>
                <button type="submit" class="btn btn-primary">Créer</button>
            </form>
    `;

            modal.style.display = 'block';

            document.getElementById('createChampForm').addEventListener('submit', async (e) => {
                e.preventDefault();

                const data = {
                    nom: document.getElementById('champ-nom').value,
                    superficie: parseFloat(document.getElementById('champ-superficie').value),
                    type_champs: document.getElementById('champ-type').value,
                    region: document.getElementById('champ-region').value
                };

                try {
                    await api.champs.create(data);
                    showAlert('Champ créé avec succès', 'success');
                    closeModal();
                    loadChamps();
                    loadDashboard();
                } catch (error) {
                    handleError(error);
                }
            });
        }

        function showCreateParcelleModal() {
            showAlert('Fonctionnalité en cours de développement', 'info');
        }

        function closeModal() {
            document.getElementById('modal').style.display = 'none';
        }

        async function logout() {
            try {
                await api.auth.logout();
                window.location.href = 'index.html';
            } catch (error) {
                handleError(error);
            }
        }

        window.onclick = function (event) {
            const modal = document.getElementById('modal');
            if (event.target === modal) {
                closeModal();
            }
        }

        init();
        // Add these functions to dashboard.js for interventions and rapports

        async function loadInterventions() {
            try {
                const result = await api.interventions.getAll();
                const container = document.getElementById('interventions-list');

                if (result.interventions.length === 0) {
                    container.innerHTML = '<p>Aucune intervention trouvée</p>';
                    return;
                }

                container.innerHTML = result.interventions.map(intervention => {
                    const priorityClass = intervention.priorite === 'URGENTE' ? 'danger' :
                        intervention.priorite === 'HAUTE' ? 'warning' : 'info';
                    const statusClass = intervention.statut === 'TERMINE' ? 'success' :
                        intervention.statut === 'EN_COURS' ? 'warning' : 'info';

                    return `
        < div class="data-card" >
                    <div style="display: flex; justify-content: space-between; align-items: start;">
                        <div>
                            <h3>${intervention.type_intervention.replace(/_/g, ' ')}</h3>
                            <span class="badge badge-${priorityClass}">${intervention.priorite}</span>
                            <span class="badge badge-${statusClass}">${intervention.statut}</span>
                        </div>
                    </div>
                    <div class="data-card-info" style="margin-top: 12px;">
                        <div class="info-item">
                            <span class="info-label">Parcelle</span>
                            <span class="info-value">${intervention.parcelle_nom || 'N/A'}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Champ</span>
                            <span class="info-value">${intervention.champ_nom || 'N/A'}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Technicien</span>
                            <span class="info-value">${intervention.technicien_nom || 'Non assigné'}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Date création</span>
                            <span class="info-value">${new Date(intervention.date_creation).toLocaleString()}</span>
                        </div>
                    </div>
                    ${ intervention.description ? `<p style="margin-top: 12px; color: var(--text-secondary);">${intervention.description}</p>` : '' }
                </div >
        `;
                }).join('');
            } catch (error) {
                handleError(error);
            }
        }

        async function loadRapports() {
            try {
                const result = await api.rapports.getAll();
                const container = document.getElementById('rapports-list');

                if (result.rapports.length === 0) {
                    container.innerHTML = '<p>Aucun rapport trouvé</p>';
                    return;
                }

                container.innerHTML = result.rapports.map(rapport => `
        < div class="data-card" >
                <h3>${rapport.type_rapport.replace(/_/g, ' ')}</h3>
                <div class="data-card-info">
                    <div class="info-item">
                        <span class="info-label">Champ</span>
                        <span class="info-value">${rapport.champ_nom}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Période</span>
                        <span class="info-value">${new Date(rapport.date_debut).toLocaleDateString()} - ${new Date(rapport.date_fin).toLocaleDateString()}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Généré le</span>
                        <span class="info-value">${new Date(rapport.date_generation).toLocaleString()}</span>
                    </div>
                </div>
                <button onclick="viewRapport(${rapport.rapport_id})" class="btn btn-primary" style="margin-top: 12px;">Voir détails</button>
            </div >
        `).join('');
            } catch (error) {
                handleError(error);
            }
        }

        function showGenerateRapportModal() {
            showAlert('Fonctionnalité en cours de développement', 'info');
        }

        function viewRapport(id) {
            showAlert('Détails du rapport - Fonctionnalité en cours de développement', 'info');
        }
