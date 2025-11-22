import axios from 'axios';

// Validate API URL
const apiUrl = import.meta.env.VITE_API_URL;
if (!apiUrl) {
    console.warn('⚠️ VITE_API_URL is not defined. Using default: http://localhost:5000/api');
}

const api = axios.create({
    baseURL: (apiUrl || 'http://localhost:5000') + '/api',
    headers: {
        'Content-Type': 'application/json',
    },
});

api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response && (error.response.status === 401 || error.response.status === 403)) {
            // Check if it's a block message or auth error
            const isBlocked = error.response.data?.message?.includes('blocked') ||
                error.response.data?.message?.includes('Account is blocked');

            if (error.response.status === 401 || isBlocked) {
                localStorage.removeItem('token');
                if (window.location.pathname !== '/login') {
                    window.location.href = '/login';
                }
            }
        }
        return Promise.reject(error);
    }
);

export default api;
