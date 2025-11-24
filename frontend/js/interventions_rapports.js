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
                <div class="data-card">
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
                    ${intervention.description ? `<p style="margin-top: 12px; color: var(--text-secondary);">${intervention.description}</p>` : ''}
                </div>
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
            <div class="data-card">
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
            </div>
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
