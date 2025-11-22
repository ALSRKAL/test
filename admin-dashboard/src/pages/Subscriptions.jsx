import { useState, useEffect } from 'react';
import api from '../api/axios';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import { CreditCard, Users, CheckCircle, DollarSign, Crown, Zap, Shield } from 'lucide-react';

const Subscriptions = () => {
    const [stats, setStats] = useState({
        planCounts: { basic: 0, pro: 0, premium: 0 },
        totalPhotographers: 0,
        activeSubscriptions: 0,
        estimatedRevenue: 0,
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        try {
            const { data } = await api.get('/admin/subscriptions/stats');
            setStats(data.data);
        } catch (error) {
            console.error('Error fetching subscription stats:', error);
            // Fallback mock data
            setStats({
                planCounts: { basic: 0, pro: 0, premium: 0 },
                totalPhotographers: 0,
                activeSubscriptions: 0,
                estimatedRevenue: 0,
            });
        } finally {
            setLoading(false);
        }
    };

    const pieData = [
        { name: 'أساسي', value: stats.planCounts.basic },
        { name: 'احترافي', value: stats.planCounts.pro },
        { name: 'مميز', value: stats.planCounts.premium },
    ];

    const COLORS = ['#9CA3AF', '#3B82F6', '#F59E0B'];

    if (loading) return (
        <div className="flex justify-center items-center h-full">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
    );

    return (
        <div className="space-y-8">
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">نظرة عامة على الاشتراكات</h1>
                <p className="text-gray-500 dark:text-gray-400 mt-1">تتبع الإيرادات ومقاييس الاشتراكات</p>
            </div>

            {/* Stats Cards */}
            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex items-center">
                    <div className="p-4 rounded-full bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 ml-4">
                        <Users size={24} />
                    </div>
                    <div>
                        <p className="text-sm font-medium text-gray-500 dark:text-gray-400">إجمالي المصورين</p>
                        <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.totalPhotographers}</p>
                    </div>
                </div>

                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex items-center">
                    <div className="p-4 rounded-full bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 ml-4">
                        <CheckCircle size={24} />
                    </div>
                    <div>
                        <p className="text-sm font-medium text-gray-500 dark:text-gray-400">الاشتراكات النشطة</p>
                        <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.activeSubscriptions}</p>
                    </div>
                </div>

                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex items-center">
                    <div className="p-4 rounded-full bg-yellow-50 dark:bg-yellow-900/20 text-yellow-600 dark:text-yellow-400 ml-4">
                        <DollarSign size={24} />
                    </div>
                    <div>
                        <p className="text-sm font-medium text-gray-500 dark:text-gray-400">الإيرادات الشهرية المتوقعة</p>
                        <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.estimatedRevenue} ر.س</p>
                    </div>
                </div>

                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 flex items-center">
                    <div className="p-4 rounded-full bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 ml-4">
                        <CreditCard size={24} />
                    </div>
                    <div>
                        <p className="text-sm font-medium text-gray-500 dark:text-gray-400">معدل التحويل</p>
                        <p className="text-2xl font-bold text-gray-900 dark:text-white">
                            {stats.totalPhotographers > 0
                                ? ((stats.activeSubscriptions / stats.totalPhotographers) * 100).toFixed(1)
                                : 0}
                            %
                        </p>
                    </div>
                </div>
            </div>

            {/* Charts */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-6">توزيع الاشتراكات</h3>
                    <div className="h-80" style={{ width: '100%', height: 320 }}>
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie
                                    data={pieData}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={100}
                                    paddingAngle={5}
                                    dataKey="value"
                                >
                                    {pieData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip />
                                <Legend verticalAlign="bottom" height={36} />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-6">تفاصيل الباقات</h3>
                    <div className="space-y-4">
                        <div className="flex items-center justify-between p-5 bg-gray-50 dark:bg-gray-700/50 rounded-xl border border-gray-100 dark:border-gray-600 hover:border-gray-300 dark:hover:border-gray-500 transition-colors">
                            <div className="flex items-center">
                                <div className="p-2 bg-gray-200 dark:bg-gray-600 rounded-lg ml-4">
                                    <Shield size={20} className="text-gray-600 dark:text-gray-300" />
                                </div>
                                <div>
                                    <span className="font-bold text-gray-900 dark:text-white block">الباقة الأساسية</span>
                                    <span className="text-xs text-gray-500 dark:text-gray-400">مجانية</span>
                                </div>
                            </div>
                            <span className="text-xl font-bold text-gray-900 dark:text-white">{stats.planCounts.basic}</span>
                        </div>

                        <div className="flex items-center justify-between p-5 bg-blue-50 dark:bg-blue-900/20 rounded-xl border border-blue-100 dark:border-blue-800 hover:border-blue-300 dark:hover:border-blue-700 transition-colors">
                            <div className="flex items-center">
                                <div className="p-2 bg-blue-200 dark:bg-blue-800 rounded-lg ml-4">
                                    <Zap size={20} className="text-blue-700 dark:text-blue-300" />
                                </div>
                                <div>
                                    <span className="font-bold text-blue-900 dark:text-blue-100 block">الباقة الاحترافية</span>
                                    <span className="text-xs text-blue-600 dark:text-blue-300">9.99 ر.س/شهر</span>
                                </div>
                            </div>
                            <span className="text-xl font-bold text-blue-900 dark:text-blue-100">{stats.planCounts.pro}</span>
                        </div>

                        <div className="flex items-center justify-between p-5 bg-yellow-50 dark:bg-yellow-900/20 rounded-xl border border-yellow-100 dark:border-yellow-800 hover:border-yellow-300 dark:hover:border-yellow-700 transition-colors">
                            <div className="flex items-center">
                                <div className="p-2 bg-yellow-200 dark:bg-yellow-800 rounded-lg ml-4">
                                    <Crown size={20} className="text-yellow-700 dark:text-yellow-300" />
                                </div>
                                <div>
                                    <span className="font-bold text-yellow-900 dark:text-yellow-100 block">الباقة المميزة</span>
                                    <span className="text-xs text-yellow-600 dark:text-yellow-300">19.99 ر.س/شهر</span>
                                </div>
                            </div>
                            <span className="text-xl font-bold text-yellow-900 dark:text-yellow-100">{stats.planCounts.premium}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Subscriptions;
