import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { Search, Bell, User, Settings, LogOut, Moon, Sun } from 'lucide-react';

const Header = () => {
    const { user } = useAuth();
    const { theme, toggleTheme } = useTheme();
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);

    return (
        <header className="bg-white dark:bg-dark-card border-b border-gray-200 dark:border-dark-border h-16 flex items-center justify-between px-8 fixed top-0 right-64 left-0 z-40 transition-colors duration-200">
            <div className="flex items-center flex-1 max-w-xl">
                <div className="relative w-full">
                    <input
                        type="text"
                        placeholder="بحث..."
                        className="w-full pl-4 pr-10 py-2 bg-gray-50 dark:bg-dark-bg border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-sm text-gray-900 dark:text-dark-text placeholder-gray-400 dark:placeholder-gray-500"
                    />
                    <Search className="absolute right-3 top-2.5 text-gray-400 dark:text-gray-500" size={18} />
                </div>
            </div>

            <div className="flex items-center space-x-4 space-x-reverse">
                <button
                    onClick={toggleTheme}
                    className="p-2 text-gray-400 hover:text-gray-600 dark:text-gray-400 dark:hover:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-full transition-colors"
                >
                    {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
                </button>

                <button className="p-2 text-gray-400 hover:text-gray-600 dark:text-gray-400 dark:hover:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-full transition-colors relative">
                    <Bell size={20} />
                    <span className="absolute top-2 left-2 h-2 w-2 bg-red-500 rounded-full border border-white dark:border-dark-card"></span>
                </button>

                <div className="relative">
                    <button
                        onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                        className="flex items-center pr-4 border-r border-gray-200 dark:border-dark-border hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors rounded-lg p-1"
                    >
                        <div className="text-left ml-3 hidden sm:block">
                            <p className="text-sm font-medium text-gray-900 dark:text-dark-text">{user?.name || 'المسؤول'}</p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">{user?.role === 'superadmin' ? 'مدير النظام' : 'مسؤول'}</p>
                        </div>
                        <div className="h-9 w-9 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-400 font-bold border border-blue-200 dark:border-blue-800">
                            {user?.name?.charAt(0).toUpperCase() || 'A'}
                        </div>
                    </button>

                    {isDropdownOpen && (
                        <div className="absolute left-0 mt-2 w-48 bg-white dark:bg-dark-card rounded-xl shadow-lg border border-gray-100 dark:border-dark-border py-1 animate-fade-in z-50">
                            <div className="px-4 py-2 border-b border-gray-100 dark:border-dark-border">
                                <p className="text-sm font-medium text-gray-900 dark:text-dark-text truncate">{user?.name}</p>
                                <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{user?.email}</p>
                            </div>
                            <Link
                                to="/profile"
                                className="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
                                onClick={() => setIsDropdownOpen(false)}
                            >
                                <User size={16} className="ml-2" />
                                الملف الشخصي
                            </Link>
                            <Link
                                to="/users"
                                className="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
                                onClick={() => setIsDropdownOpen(false)}
                            >
                                <Settings size={16} className="ml-2" />
                                إدارة النظام
                            </Link>
                            <button
                                onClick={() => {
                                    setIsDropdownOpen(false);
                                    // Add logout logic here if needed or rely on Sidebar
                                }}
                                className="flex w-full items-center px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
                            >
                                <LogOut size={16} className="ml-2" />
                                تسجيل الخروج
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </header>
    );
};

export default Header;
