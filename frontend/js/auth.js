function toggleForms() {
    const loginForm = document.getElementById('login-form');
    const registerForm = document.getElementById('register-form');

    if (loginForm.style.display === 'none') {
        loginForm.style.display = 'block';
        registerForm.style.display = 'none';
    } else {
        loginForm.style.display = 'none';
        registerForm.style.display = 'block';
    }
}

document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;

    try {
        const result = await api.auth.login({ email, password });
        showAlert('Connexion réussie', 'success');
        setTimeout(() => {
            window.location.href = 'dashboard.html';
        }, 1000);
    } catch (error) {
        handleError(error);
    }
});

document.getElementById('registerForm').addEventListener('submit', async (e) => {
    e.preventDefault();

    const data = {
        nom: document.getElementById('register-nom').value,
        prenom: document.getElementById('register-prenom').value,
        email: document.getElementById('register-email').value,
        password: document.getElementById('register-password').value,
        telephone: document.getElementById('register-telephone').value,
        role: document.getElementById('register-role').value,
        region_affectation: document.getElementById('register-region').value || null
    };

    try {
        await api.auth.register(data);
        showAlert('Inscription réussie! Vous pouvez maintenant vous connecter.', 'success');
        setTimeout(() => {
            toggleForms();
        }, 1500);
    } catch (error) {
        handleError(error);
    }
});
