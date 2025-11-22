import { useState, useEffect } from 'react';
import api from '../api/axios';
import toast from 'react-hot-toast';
import { Flag, CheckCircle, XCircle, AlertTriangle, MessageSquare, User } from 'lucide-react';

const Reports = () => {
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('all');

    useEffect(() => {
        fetchReports();
    }, []);

    const fetchReports = async () => {
        try {
            const { data } = await api.get('/admin/reports');
            setReports(data.data || []);
        } catch (error) {
            console.error('Error fetching reports:', error);
            toast.error('فشل في جلب البلاغات');
        } finally {
            setLoading(false);
        }
    };

    const handleResolve = async (id, status) => {
        try {
            await api.patch(`/admin/reports/${id}/resolve`, { status });
            setReports(reports.map(r => r._id === id ? { ...r, status } : r));
            toast.success('تم تحديث حالة البلاغ بنجاح');
        } catch (error) {
            console.error('Error resolving report:', error);
            toast.error('فشل في تحديث حالة البلاغ');
        }
    };

    const filteredReports = filter === 'all'
        ? reports
        : reports.filter(r => r.status === filter);

    const getStatusBadge = (status) => {
        switch (status) {
            case 'pending': return <span className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-full text-xs font-medium flex items-center gap-1"><AlertTriangle size={12} /> قيد الانتظار</span>;
            case 'resolved': return <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs font-medium flex items-center gap-1"><CheckCircle size={12} /> تم الحل</span>;
            case 'dismissed': return <span className="px-2 py-1 bg-gray-100 text-gray-800 rounded-full text-xs font-medium flex items-center gap-1"><XCircle size={12} /> تم التجاهل</span>;
            default: return null;
        }
    };

    if (loading) return (
        <div className="flex justify-center items-center h-full">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
    );

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">البلاغات والشكاوى</h1>
                    <p className="text-gray-500 dark:text-gray-400 mt-1">إدارة بلاغات المستخدمين والمحتوى المخالف</p>
                </div>
                <div className="flex gap-2">
                    <select
                        value={filter}
                        onChange={(e) => setFilter(e.target.value)}
                        className="border border-gray-300 dark:border-dark-border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-dark-card text-gray-700 dark:text-gray-200"
                    >
                        <option value="all">الكل</option>
                        <option value="pending">قيد الانتظار</option>
                        <option value="resolved">تم الحل</option>
                        <option value="dismissed">تم التجاهل</option>
                    </select>
                </div>
            </div>

            <div className="grid gap-6">
                {filteredReports.length === 0 ? (
                    <div className="text-center py-12 bg-white dark:bg-dark-card rounded-xl border border-gray-100 dark:border-dark-border transition-colors duration-200">
                        <Flag size={48} className="mx-auto text-gray-300 dark:text-gray-600 mb-4" />
                        <p className="text-gray-500 dark:text-gray-400 text-lg">لا توجد بلاغات حالياً</p>
                    </div>
                ) : (
                    filteredReports.map((report) => (
                        <div key={report._id} className="bg-white dark:bg-dark-card p-6 rounded-xl shadow-sm border border-gray-100 dark:border-dark-border hover:shadow-md transition-all duration-200">
                            <div className="flex justify-between items-start mb-4">
                                <div className="flex items-center gap-3">
                                    <div className="p-2 bg-red-50 dark:bg-red-900/20 rounded-lg">
                                        <Flag className="text-red-500 dark:text-red-400" size={20} />
                                    </div>
                                    <div>
                                        <h3 className="font-bold text-gray-900 dark:text-white">{report.reason}</h3>
                                        <p className="text-sm text-gray-500 dark:text-gray-400">
                                            من: {report.reporter?.name || 'مستخدم محذوف'}
                                        </p>
                                    </div>
                                </div>
                                {getStatusBadge(report.status)}
                            </div>

                            <div className="bg-gray-50 dark:bg-gray-800/50 p-4 rounded-lg mb-4">
                                <p className="text-gray-700 dark:text-gray-300 text-sm">{report.description || 'لا يوجد وصف إضافي'}</p>
                            </div>

                            <div className="flex items-center justify-between pt-4 border-t border-gray-100 dark:border-dark-border">
                                <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                                    <User size={14} />
                                    <span>المبلغ عنه: {report.reportedUser?.name || 'غير محدد'}</span>
                                </div>

                                {report.status === 'pending' && (
                                    <div className="flex gap-2">
                                        <button
                                            onClick={() => handleResolve(report._id, 'resolved')}
                                            className="px-3 py-1.5 bg-green-600 text-white text-sm font-medium rounded-lg hover:bg-green-700 transition-colors"
                                        >
                                            حل المشكلة
                                        </button>
                                        <button
                                            onClick={() => handleResolve(report._id, 'dismissed')}
                                            className="px-3 py-1.5 bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 text-sm font-medium rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors"
                                        >
                                            تجاهل
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
};

export default Reports;
