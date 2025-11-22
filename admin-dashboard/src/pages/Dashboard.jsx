import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Users, Camera, Calendar, DollarSign, ArrowUpRight, AlertCircle } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts';
import { useSocket } from '../context/SocketContext';
import toast from 'react-hot-toast';

const Dashboard = () => {
    const [stats, setStats] = useState({
        totalUsers: 0,
        totalPhotographers: 0,
        totalBookings: 0,
        totalRevenue: 0,
        revenueData: [],
        userGrowthData: [],
    });
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const socket = useSocket();

    const fetchStats = async () => {
        try {
            setLoading(true);
            const { data } = await api.get('/admin/dashboard');
            if (data.success) {
                setStats(data.data);
                setError(null);
            }
        } catch (error) {
            console.error('Error fetching dashboard stats:', error);
            setError('فشل في تحميل البيانات. يرجى المحاولة مرة أخرى.');
            toast.error('فشل في تحميل البيانات');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStats();
    }, []);

    useEffect(() => {
        if (socket) {
            socket.on('new_booking', () => {
                toast.success('حجز جديد!');
                fetchStats();
            });

            socket.on('new_user', () => {
                fetchStats();
            });

            return () => {
                socket.off('new_booking');
                socket.off('new_user');
            };
        }
    }, [socket]);

    if (loading) return (
        <div className="flex justify-center items-center h-full min-h-[400px]">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
    );

    if (error) return (
        <div className="flex flex-col justify-center items-center h-full min-h-[400px] text-center">
            <AlertCircle size={48} className="text-red-500 mb-4" />
            <p className="text-gray-800 dark:text-gray-200 font-medium mb-2">{error}</p>
            <button
                onClick={fetchStats}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
                إعادة المحاولة
            </button>
        </div>
    );

    // Format revenue for display
    const formatCurrency = (value) => {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0
        }).format(value);
    };

    const StatCard = ({ title, value, icon: Icon, color, trend }) => (
        <div className="bg-white dark:bg-dark-card rounded-xl p-6 shadow-sm border border-gray-100 dark:border-dark-border hover:shadow-md transition-all duration-200">
            <div className="flex items-center justify-between mb-4">
                <div className={`p-3 rounded-lg ${color}`}>
                    <Icon size={24} className="text-white" />
                </div>
                {trend && (
                    <div className="flex items-center text-green-500 text-sm font-medium bg-green-50 dark:bg-green-900/20 px-2 py-1 rounded-full">
                        <ArrowUpRight size={14} className="ml-1" />
                        {trend}
                    </div>
                )}
            </div>
            <div>
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">{title}</p>
                <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{value}</h3>
            </div>
        </div>
    );

    return (
        <div className="space-y-8 animate-fade-in">
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">لوحة التحكم</h1>
                <p className="text-gray-500 dark:text-gray-400 mt-1">مرحباً بك في لوحة تحكم المسؤول.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <StatCard
                    title="إجمالي المستخدمين"
                    value={stats.users?.total || 0}
                    icon={Users}
                    color="bg-blue-500"
                />
                <StatCard
                    title="المصورين"
                    value={stats.photographers?.total || 0}
                    icon={Camera}
                    color="bg-purple-500"
                />
                <StatCard
                    title="إجمالي الحجوزات"
                    value={stats.bookings?.total || 0}
                    icon={Calendar}
                    color="bg-orange-500"
                />
                <StatCard
                    title="إجمالي الإيرادات"
                    value={formatCurrency(stats.revenue?.totalRevenue || 0)}
                    icon={DollarSign}
                    color="bg-green-500"
                />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <div className="bg-white dark:bg-dark-card p-6 rounded-xl shadow-sm border border-gray-100 dark:border-dark-border transition-colors duration-200">
                    <div className="flex items-center justify-between mb-6">
                        <h3 className="text-lg font-bold text-gray-900 dark:text-white">نظرة عامة على الإيرادات</h3>
                    </div>
                    <div className="h-80" style={{ width: '100%', height: 320 }}>
                        {stats.revenue?.chartData?.length > 0 && (
                            <ResponsiveContainer width="100%" height="100%">
                                <BarChart data={stats.revenue?.chartData}>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" className="dark:stroke-gray-700" />
                                    <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fill: '#9ca3af' }} dy={10} />
                                    <YAxis axisLine={false} tickLine={false} tick={{ fill: '#9ca3af' }} dx={-10} />
                                    <Tooltip
                                        contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)', backgroundColor: '#fff', color: '#374151' }}
                                        cursor={{ fill: '#f9fafb' }}
                                    />
                                    <Bar dataKey="revenue" fill="#3b82f6" radius={[4, 4, 0, 0]} barSize={40} />
                                </BarChart>
                            </ResponsiveContainer>
                        )}
                    </div>
                </div>

                <div className="bg-white dark:bg-dark-card p-6 rounded-xl shadow-sm border border-gray-100 dark:border-dark-border transition-colors duration-200">
                    <div className="flex items-center justify-between mb-6">
                        <h3 className="text-lg font-bold text-gray-900 dark:text-white">نمو المستخدمين</h3>
                    </div>
                    <div className="h-80" style={{ width: '100%', height: 320 }}>
                        {stats.metrics?.userGrowth?.length > 0 && (
                            <ResponsiveContainer width="100%" height="100%">
                                <LineChart data={stats.metrics?.userGrowth}>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" className="dark:stroke-gray-700" />
                                    <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fill: '#9ca3af' }} dy={10} />
                                    <YAxis axisLine={false} tickLine={false} tick={{ fill: '#9ca3af' }} dx={-10} />
                                    <Tooltip
                                        contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)', backgroundColor: '#fff', color: '#374151' }}
                                    />
                                    <Line
                                        type="monotone"
                                        dataKey="count"
                                        stroke="#8b5cf6"
                                        strokeWidth={3}
                                        dot={{ r: 4, fill: '#8b5cf6', strokeWidth: 2, stroke: '#fff' }}
                                        activeDot={{ r: 6 }}
                                    />
                                </LineChart>
                            </ResponsiveContainer>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
