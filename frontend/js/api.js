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
        const response = await fetch(`${API_URL}${endpoint}`, options);
        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.error || 'Request failed');
        }

        return result;
    } catch (error) {
        console.error('API Error:', error);
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
    }
};

function showAlert(message, type = 'success') {
    const container = document.getElementById('alert-container');
    const alert = document.createElement('div');
    alert.className = `alert alert-${type}`;
    alert.textContent = message;
    container.appendChild(alert);

    setTimeout(() => {
        alert.remove();
    }, 5000);
}

function handleError(error) {
    showAlert(error.message || 'Une erreur est survenue', 'error');
}
