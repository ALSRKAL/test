import { createContext, useState, useContext, useEffect } from 'react';
import api from '../api/axios';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const checkAuth = async () => {
            const token = localStorage.getItem('token');
            if (token) {
                try {
                    // Verify token and get user profile
                    const response = await api.get('/admin/me');
                    if (response.data.success) {
                        setUser({ token, ...response.data.data });
                    } else {
                        throw new Error('Failed to fetch user profile');
                    }
                } catch (error) {
                    console.error("Auth check failed", error);
                    localStorage.removeItem('token');
                    setUser(null);
                }
            }
            setLoading(false);
        };
        checkAuth();
    }, []);

    const login = async (email, password) => {
        const response = await api.post('/admin/login', { email, password });
        const { data } = response.data; // Access the nested data object

        if (data && data.token) {
            localStorage.setItem('token', data.token);
            setUser({ token: data.token, ...data.user });
            return response.data;
        } else {
            throw new Error('Invalid response from server');
        }
    };

    const logout = () => {
        localStorage.removeItem('token');
        setUser(null);
        // Optional: Redirect to login is handled by the component calling logout or ProtectedRoute
    };

    return (
        <AuthContext.Provider value={{ user, login, logout, loading }}>
            {!loading && children}
        </AuthContext.Provider>
    );
};
