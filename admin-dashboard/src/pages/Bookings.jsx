import { useState, useEffect } from 'react';
import api from '../api/axios';
import toast from 'react-hot-toast';
import { Calendar, Clock, MapPin, User, Search } from 'lucide-react';

const Bookings = () => {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        fetchBookings();
    }, []);

    const fetchBookings = async () => {
        try {
            const { data } = await api.get('/admin/bookings');
            setBookings(data.data);
        } catch (error) {
            console.error('Error fetching bookings:', error);
            toast.error('فشل في جلب الحجوزات');
            // Fallback mock data
            setBookings([]);
        } finally {
            setLoading(false);
        }
    };

    const getStatusBadge = (status) => {
        switch (status) {
            case 'confirmed': return <span className="px-2 py-1 bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300 rounded-full text-xs font-medium">مؤكد</span>;
            case 'pending': return <span className="px-2 py-1 bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300 rounded-full text-xs font-medium">قيد الانتظار</span>;
            case 'cancelled': return <span className="px-2 py-1 bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300 rounded-full text-xs font-medium">ملغي</span>;
            case 'completed': return <span className="px-2 py-1 bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300 rounded-full text-xs font-medium">مكتمل</span>;
            default: return <span className="px-2 py-1 bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300 rounded-full text-xs font-medium">{status}</span>;
        }
    };

    const filteredBookings = bookings.filter(booking =>
        booking.client?.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        booking.photographer?.name.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) return (
        <div className="flex justify-center items-center h-full">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
    );

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">إدارة الحجوزات</h1>
                    <p className="text-gray-500 dark:text-gray-400 mt-1">تتبع ومراقبة جميع جلسات التصوير</p>
                </div>
                <div className="relative w-full sm:w-64">
                    <input
                        type="text"
                        placeholder="بحث في الحجوزات..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full pl-4 pr-10 py-2 border border-gray-300 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-dark-card text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
                    />
                    <Search className="absolute left-3 top-2.5 text-gray-400 dark:text-gray-500" size={18} />
                </div>
            </div>

            <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm border border-gray-100 dark:border-dark-border overflow-hidden transition-colors duration-200">
                <div className="overflow-x-auto">
                    <table className="w-full text-right">
                        <thead className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-dark-border">
                            <tr>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">العميل</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">المصور</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">التاريخ والوقت</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الموقع</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الحالة</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100 dark:divide-dark-border">
                            {filteredBookings.map((booking) => (
                                <tr key={booking._id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center text-sm text-gray-900 dark:text-white font-medium">
                                            <User size={16} className="ml-2 text-gray-400 dark:text-gray-500" />
                                            {booking.client?.name || 'غير معروف'}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-300">
                                            <User size={16} className="ml-2 text-gray-400 dark:text-gray-500" />
                                            {booking.photographer?.name || 'غير معروف'}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex flex-col space-y-1">
                                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-300">
                                                <Calendar size={14} className="ml-2 text-gray-400 dark:text-gray-500" />
                                                {new Date(booking.date).toLocaleDateString('ar-EG')}
                                            </div>
                                            <div className="flex items-center text-xs text-gray-500 dark:text-gray-400">
                                                <Clock size={12} className="ml-2 text-gray-400 dark:text-gray-500" />
                                                {booking.time}
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-300">
                                            <MapPin size={14} className="ml-2 text-gray-400 dark:text-gray-500" />
                                            {booking.location || 'غير محدد'}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        {getStatusBadge(booking.status)}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
                {filteredBookings.length === 0 && (
                    <div className="text-center py-12">
                        <p className="text-gray-500 dark:text-gray-400 text-lg">لا توجد حجوزات مطابقة</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Bookings;
