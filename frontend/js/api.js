const API_URL = 'http://localhost:5000/api';

async function apiCall(endpoint, method = 'GET', data = null) {
    const options = {
        method,
        headers: {
            'Content-Type': 'application/json',
        },
        credentials: 'include'
    };

    if (data) {
        options.body = JSON.stringify(data);
    }

    try {
        console.log(`Making API call to: ${API_URL}${endpoint}`, { method, data });
        const response = await fetch(`${API_URL}${endpoint}`, options);
        console.log(`Response status: ${response.status}`);

        const result = await response.json();
        console.log('Response data:', result);

        if (!response.ok) {
            throw new Error(result.error || 'Request failed');
        }

        return result;
    } catch (error) {
        console.error('API Error:', error);
        console.error('Error details:', error.message);
        throw error;
    }
}

const api = {
    auth: {
        register: (data) => apiCall('/auth/register', 'POST', data),
        login: (data) => apiCall('/auth/login', 'POST', data),
        logout: () => apiCall('/auth/logout', 'POST'),
        getMe: () => apiCall('/auth/me')
    },

    champs: {
        getAll: () => apiCall('/champs'),
        getById: (id) => apiCall(`/champs/${id}`),
        create: (data) => apiCall('/champs', 'POST', data),
        update: (id, data) => apiCall(`/champs/${id}`, 'PUT', data)
    },

    parcelles: {
        getAll: (champId = null) => apiCall(`/parcelles${champId ? `?champ_id=${champId}` : ''}`),
        getById: (id) => apiCall(`/parcelles/${id}`),
        create: (data) => apiCall('/parcelles', 'POST', data),
        update: (id, data) => apiCall(`/parcelles/${id}`, 'PUT', data)
    },

    alertes: {
        getAll: (filters = {}) => {
            const params = new URLSearchParams(filters).toString();
            return apiCall(`/alertes${params ? `?${params}` : ''}`);
        },
        resolve: (id) => apiCall(`/alertes/${id}/resolve`, 'POST')
    },

    notifications: {
        getAll: (lue = null) => apiCall(`/notifications${lue ? `?lue=${lue}` : ''}`),
        markRead: (id) => apiCall(`/notifications/${id}/mark-read`, 'POST'),
        countUnread: () => apiCall('/notifications/count-unread')
    },

    interventions: {
        getAll: () => apiCall('/interventions'),
        getById: (id) => apiCall(`/interventions/${id}`),
        updateStatus: (id, data) => apiCall(`/interventions/${id}/update-status`, 'PUT', data)
    },

    rapports: {
        getAll: () => apiCall('/rapports'),
        getById: (id) => apiCall(`/rapports/${id}`),
        generate: (data) => apiCall('/rapports/generate', 'POST', data)
    }
};

function showAlert(message, type = 'success') {
    const container = document.getElementById('alert-container');
    if (!container) {
        console.error('Alert container not found!');
        alert(message); // Fallback to browser alert
        return;
    }

    const alert = document.createElement('div');
    alert.className = `alert alert-${type}`;
    alert.textContent = message;
    alert.style.display = 'block';
    container.appendChild(alert);

    console.log(`Alert shown: [${type}] ${message}`);

    setTimeout(() => {
        alert.remove();
    }, 5000);
}

function handleError(error) {
    const errorMessage = error.message || 'Une erreur est survenue';
    console.error('Handling error:', errorMessage);
    showAlert(errorMessage, 'error');
}
