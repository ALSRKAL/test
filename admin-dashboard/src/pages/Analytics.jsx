import { useState, useEffect } from 'react';
import api from '../api/axios';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { TrendingUp, DollarSign, Users, Star, Calendar, ArrowUpRight, ArrowDownRight } from 'lucide-react';

const Analytics = () => {
    const [data, setData] = useState({
        usersGrowth: [],
        bookingsTrend: [],
        revenueTrend: [],
        topPhotographers: [],
        popularSpecialties: [],
    });
    const [loading, setLoading] = useState(true);
    const [timeRange, setTimeRange] = useState('month');

    useEffect(() => {
        fetchAnalytics();
    }, []);

    const fetchAnalytics = async () => {
        try {
            const { data } = await api.get('/admin/analytics');
            setData(data.data);
        } catch (error) {
            console.error('Error fetching analytics:', error);
            // Fallback mock data
            setData({
                usersGrowth: [],
                bookingsTrend: [],
                revenueTrend: [],
                topPhotographers: [],
                popularSpecialties: [],
            });
        } finally {
            setLoading(false);
        }
    };

    // Mock Data - Replace with API data later
    const revenueData = [
        { name: 'يناير', value: 4000 },
        { name: 'فبراير', value: 3000 },
        { name: 'مارس', value: 2000 },
        { name: 'أبريل', value: 2780 },
        { name: 'مايو', value: 1890 },
        { name: 'يونيو', value: 2390 },
        { name: 'يوليو', value: 3490 },
    ];

    const userTypeData = [
        { name: 'عملاء', value: 400 },
        { name: 'مصورين', value: 300 },
    ];

    const COLORS = ['#3B82F6', '#8B5CF6'];

    const stats = [
        { title: 'إجمالي الإيرادات', value: '54,230 ر.س', change: '+12.5%', trend: 'up', icon: DollarSign, color: 'blue' },
        { title: 'المستخدمين النشطين', value: '2,430', change: '+8.2%', trend: 'up', icon: Users, color: 'purple' },
        { title: 'معدل الحجوزات', value: '156', change: '-2.4%', trend: 'down', icon: Calendar, color: 'orange' },
        { title: 'متوسط التقييم', value: '4.8', change: '+4.1%', trend: 'up', icon: TrendingUp, color: 'green' },
    ];

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">التحليلات والتقارير</h1>
                    <p className="text-gray-500 dark:text-gray-400 mt-1">نظرة شاملة على أداء المنصة</p>
                </div>
                <select
                    value={timeRange}
                    onChange={(e) => setTimeRange(e.target.value)}
                    className="bg-white dark:bg-dark-card border border-gray-300 dark:border-dark-border text-gray-700 dark:text-gray-200 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2.5 outline-none"
                >
                    <option value="week">آخر أسبوع</option>
                    <option value="month">آخر شهر</option>
                    <option value="year">آخر سنة</option>
                </select>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {stats.map((stat, index) => (
                    <div key={index} className="bg-white dark:bg-dark-card p-6 rounded-xl shadow-sm border border-gray-100 dark:border-dark-border transition-colors duration-200">
                        <div className="flex justify-between items-start">
                            <div>
                                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">{stat.title}</p>
                                <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-2">{stat.value}</h3>
                            </div>
                            <div className={`p-3 rounded-lg bg-${stat.color}-50 dark:bg-${stat.color}-900/20 text-${stat.color}-600 dark:text-${stat.color}-400`}>
                                <stat.icon size={24} />
                            </div>
                        </div>
                        <div className="mt-4 flex items-center text-sm">
                            <span className={`flex items-center font-medium ${stat.trend === 'up' ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'
                                }`}>
                                {stat.trend === 'up' ? <ArrowUpRight size={16} className="ml-1" /> : <ArrowDownRight size={16} className="ml-1" />}
                                {stat.change}
                            </span>
                            <span className="text-gray-400 dark:text-gray-500 mr-2">مقارنة بالشهر السابق</span>
                        </div>
                    </div>
                ))}
            </div>

            {/* Charts Section */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Revenue Chart */}
                <div className="lg:col-span-2 bg-white dark:bg-dark-card p-6 rounded-xl shadow-sm border border-gray-100 dark:border-dark-border transition-colors duration-200">
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-6">تحليل الإيرادات</h3>
                    <div className="h-80" style={{ width: '100%', height: 320 }}>
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={revenueData}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" className="dark:stroke-gray-700" />
                                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#6B7280' }} dy={10} />
                                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#6B7280' }} dx={-10} />
                                <Tooltip
                                    contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', color: '#374151' }}
                                    cursor={{ fill: '#F3F4F6' }}
                                />
                                <Bar dataKey="value" fill="#3B82F6" radius={[4, 4, 0, 0]} barSize={40} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* User Distribution Chart */}
                <div className="bg-white dark:bg-dark-card p-6 rounded-xl shadow-sm border border-gray-100 dark:border-dark-border transition-colors duration-200">
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-6">توزيع المستخدمين</h3>
                    <div className="h-64 relative" style={{ width: '100%', height: 256 }}>
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie
                                    data={userTypeData}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={80}
                                    fill="#8884d8"
                                    paddingAngle={5}
                                    dataKey="value"
                                >
                                    {userTypeData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', color: '#374151' }} />
                            </PieChart>
                        </ResponsiveContainer>
                        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 text-center">
                            <p className="text-xs text-gray-500 dark:text-gray-400">الإجمالي</p>
                            <p className="text-xl font-bold text-gray-900 dark:text-white">700</p>
                        </div>
                    </div>
                    <div className="mt-6 space-y-3">
                        {userTypeData.map((entry, index) => (
                            <div key={index} className="flex items-center justify-between">
                                <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: COLORS[index] }}></div>
                                <span className="text-sm text-gray-600 dark:text-gray-300">{entry.name}</span>
                                <span className="text-sm font-medium text-gray-900 dark:text-white">{entry.value}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            {/* Top Photographers Table */}
            <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm border border-gray-100 dark:border-dark-border overflow-hidden transition-colors duration-200">
                <div className="p-6 border-b border-gray-100 dark:border-dark-border">
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white">أفضل المصورين أداءً</h3>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full text-right">
                        <thead className="bg-gray-50 dark:bg-gray-800/50">
                            <tr>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">المصور</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الحجوزات</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">التقييم</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الإيرادات</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100 dark:divide-dark-border">
                            {[1, 2, 3, 4, 5].map((item) => (
                                <tr key={item} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center">
                                            <div className="h-8 w-8 rounded-full bg-gray-200 dark:bg-gray-700 flex items-center justify-center text-xs font-bold text-gray-600 dark:text-gray-300">
                                                م{item}
                                            </div>
                                            <span className="mr-3 text-sm font-medium text-gray-900 dark:text-white">مصور {item}</span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-300">
                                        {20 + item * 5}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <span className="text-sm font-medium text-yellow-500">★ 4.{9 - item}</span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                                        {1500 + item * 200} ر.س
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

export default Analytics;
