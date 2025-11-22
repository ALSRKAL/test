import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Home, Users, Camera, Calendar, BarChart2, Star, Bell, CreditCard, LogOut, Flag, Shield } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const Sidebar = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const { logout, user } = useAuth();

    const navItems = [
        { path: '/', label: 'لوحة التحكم', icon: Home },
        { path: '/users', label: 'المستخدمين', icon: Users },
        { path: '/photographers', label: 'المصورين', icon: Camera },
        { path: '/verifications', label: 'طلبات التوثيق', icon: Shield },
        { path: '/bookings', label: 'الحجوزات', icon: Calendar },
        { path: '/analytics', label: 'التحليلات', icon: BarChart2 },
        { path: '/reviews', label: 'التقييمات', icon: Star },
        { path: '/notifications', label: 'الإشعارات', icon: Bell },
        { path: '/subscriptions', label: 'الاشتراكات', icon: CreditCard },
        { path: '/reports', label: 'البلاغات', icon: Flag },
        { path: '/system-admin', label: 'مسؤول النظام', icon: Shield },
    ];

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    return (
        <div className="h-screen w-64 bg-white/80 dark:bg-dark-card/80 backdrop-blur-xl border-l border-gray-200 dark:border-dark-border flex flex-col fixed right-0 top-0 z-50 shadow-[0_0_15px_rgba(0,0,0,0.05)] transition-colors duration-200">
            <div className="p-6 flex items-center justify-center border-b border-gray-100/50 dark:border-dark-border/50">
                <h1 className="text-3xl font-black bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent tracking-tight">حجزي</h1>
            </div>

            <nav className="flex-1 p-4 space-y-1 overflow-y-auto custom-scrollbar">
                <div className="text-xs font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-4 mt-2 px-4 opacity-70">القائمة الرئيسية</div>
                {navItems.filter(item => {
                    if (!user) return false;
                    if (user.role === 'superadmin') return true;

                    // Map paths to permission keys
                    const permissionMap = {
                        '/users': 'users',
                        '/photographers': 'photographers',
                        '/bookings': 'bookings',
                        '/analytics': 'analytics',
                        '/reviews': 'reviews',
                        '/notifications': 'notifications',
                        '/subscriptions': 'subscriptions',
                        '/reports': 'reports',
                        '/system-admin': 'system_admin' // Usually restricted to superadmin anyway
                    };

                    // Dashboard is always accessible
                    if (item.path === '/') return true;

                    // System Admin page is superadmin only (handled by route protection, but hide from sidebar too)
                    if (item.path === '/system-admin') return false;

                    const permKey = permissionMap[item.path];
                    return user.permissions && user.permissions[permKey];
                }).map((item) => {
                    const Icon = item.icon;
                    const isActive = location.pathname === item.path;
                    return (
                        <Link
                            key={item.path}
                            to={item.path}
                            className={`flex items-center px-4 py-3.5 rounded-xl transition-all duration-300 group relative overflow-hidden ${isActive
                                ? 'bg-gradient-to-l from-blue-50 to-transparent dark:from-blue-900/20 text-blue-600 dark:text-blue-400 font-bold shadow-sm'
                                : 'text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-200'
                                }`}
                        >
                            {isActive && (
                                <div className="absolute right-0 top-0 bottom-0 w-1 bg-blue-600 dark:bg-blue-500 rounded-l-full"></div>
                            )}
                            <Icon size={22} className={`ml-3 transition-transform duration-300 ${isActive ? 'text-blue-600 dark:text-blue-400 scale-110' : 'text-gray-400 dark:text-gray-500 group-hover:text-gray-600 dark:group-hover:text-gray-300 group-hover:scale-105'}`} />
                            <span className="relative z-10">{item.label}</span>
                        </Link>
                    );
                })}
            </nav>

            <div className="p-4 border-t border-gray-100/50 dark:border-dark-border/50 bg-gray-50/50 dark:bg-dark-bg/50">
                <button
                    onClick={handleLogout}
                    className="flex items-center w-full px-4 py-3 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 hover:shadow-sm rounded-xl transition-all duration-200 group"
                >
                    <LogOut size={20} className="ml-3 group-hover:-translate-x-1 transition-transform" />
                    <span className="font-medium">تسجيل الخروج</span>
                </button>
            </div>
        </div>
    );
};

export default Sidebar;
