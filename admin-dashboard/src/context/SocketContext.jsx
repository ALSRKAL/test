import { createContext, useContext, useEffect, useState } from 'react';
import io from 'socket.io-client';
import { useAuth } from './AuthContext';

const SocketContext = createContext();

export const useSocket = () => {
    return useContext(SocketContext);
};

export const SocketProvider = ({ children }) => {
    const [socket, setSocket] = useState(null);
    const { user } = useAuth();

    useEffect(() => {
        if (user && user.role === 'admin') {
            // Validate Socket URL
            const socketUrl = import.meta.env.VITE_API_URL;
            if (!socketUrl) {
                console.warn('⚠️ VITE_API_URL is not defined. Using default: http://localhost:5000');
            }
            
            const newSocket = io(socketUrl || 'http://localhost:5000', {
                query: { userId: user.id },
            });

            setSocket(newSocket);

            return () => newSocket.close();
        } else {
            if (socket) {
                socket.close();
                setSocket(null);
            }
        }
    }, [user]);

    return (
        <SocketContext.Provider value={socket}>
            {children}
        </SocketContext.Provider>
    );
};
