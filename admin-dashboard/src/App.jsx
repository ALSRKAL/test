import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './context/AuthContext';
import { SocketProvider } from './context/SocketContext';
import { ThemeProvider } from './context/ThemeContext';
import Login from './pages/Login';
import ProtectedRoute from './components/ProtectedRoute';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Photographers from './pages/Photographers';
import Bookings from './pages/Bookings';
import Analytics from './pages/Analytics';
import Reviews from './pages/Reviews';
import Notifications from './pages/Notifications';
import Subscriptions from './pages/Subscriptions';
import Reports from './pages/Reports';
import SystemAdmin from './pages/SystemAdmin';
import VerificationRequests from './pages/VerificationRequests';
import Profile from './pages/Profile';

// Placeholder for Dashboard
const DashboardPlaceholder = () => <div>Dashboard Content</div>;

function App() {
  return (
    <AuthProvider>
      <ThemeProvider>
        <SocketProvider>
          <Router>
            <Toaster position="top-right" />
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route element={<ProtectedRoute />}>
                <Route element={<Layout />}>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/users" element={<Users />} />
                  <Route path="/photographers" element={<Photographers />} />
                  <Route path="/bookings" element={<Bookings />} />
                  <Route path="/analytics" element={<Analytics />} />
                  <Route path="/reviews" element={<Reviews />} />
                  <Route path="/notifications" element={<Notifications />} />
                  <Route path="/subscriptions" element={<Subscriptions />} />
                  <Route path="/reports" element={<Reports />} />
                  <Route path="/system-admin" element={<SystemAdmin />} />
                  <Route path="/verifications" element={<VerificationRequests />} />
                  <Route path="/profile" element={<Profile />} />
                  {/* Add other protected routes here */}
                </Route>
              </Route>
            </Routes>
          </Router>
        </SocketProvider>
      </ThemeProvider>
    </AuthProvider>
  );
}

export default App;
