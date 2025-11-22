import { useState, useEffect } from 'react';
import api from '../api/axios';
import toast from 'react-hot-toast';
import { Check, X, Camera, MapPin, Calendar, User, Filter } from 'lucide-react';

const Photographers = () => {
    const [activeTab, setActiveTab] = useState('all'); // 'all' | 'pending'
    const [photographers, setPhotographers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [pagination, setPagination] = useState({
        page: 1,
        limit: 20,
        total: 0,
        pages: 1
    });

    useEffect(() => {
        const delayDebounceFn = setTimeout(() => {
            fetchPhotographers(1);
        }, 500);

        return () => clearTimeout(delayDebounceFn);
    }, [searchTerm]);

    useEffect(() => {
        fetchPhotographers(pagination.page);
    }, [activeTab, pagination.page]);

    const fetchPhotographers = async (page = 1) => {
        try {
            setLoading(true);
            let url = activeTab === 'pending'
                ? `/admin/photographers/pending?page=${page}&limit=${pagination.limit}&search=${searchTerm}`
                : `/admin/photographers?page=${page}&limit=${pagination.limit}&search=${searchTerm}`;

            const { data } = await api.get(url);
            setPhotographers(data.data);
            if (data.pagination) {
                setPagination(prev => ({
                    ...prev,
                    page: data.pagination.page,
                    total: data.pagination.total,
                    pages: data.pagination.pages
                }));
            }
        } catch (error) {
            console.error('Error fetching photographers:', error);
            toast.error('فشل في جلب المصورين');
            setPhotographers([]);
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (id) => {
        try {
            await api.patch(`/admin/photographers/${id}/approve`);
            setPhotographers(photographers.filter(p => p._id !== id));
            toast.success('تم قبول المصور بنجاح');
            // Refresh if needed or just remove from list
            if (activeTab === 'all') fetchPhotographers(pagination.page);
        } catch (error) {
            console.error('Error approving photographer:', error);
            toast.error('فشل في قبول المصور');
        }
    };

    const handleReject = async (id) => {
        try {
            await api.patch(`/admin/photographers/${id}/reject`);
            setPhotographers(photographers.filter(p => p._id !== id));
            toast.success('تم رفض المصور');
            if (activeTab === 'all') fetchPhotographers(pagination.page);
        } catch (error) {
            console.error('Error rejecting photographer:', error);
            toast.error('فشل في رفض المصور');
        }
    };

    const handleRevoke = async (id) => {
        if (!window.confirm('هل أنت متأكد من سحب التوثيق من هذا المصور؟')) return;

        try {
            await api.patch(`/admin/photographers/${id}/revoke`);
            // Update the photographer in the list instead of removing
            setPhotographers(photographers.map(p =>
                p._id === id ? { ...p, verification: { ...p.verification, status: 'not_submitted' } } : p
            ));
            toast.success('تم سحب التوثيق بنجاح');
        } catch (error) {
            console.error('Error revoking verification:', error);
            toast.error('فشل في سحب التوثيق');
        }
    };

    const renderPagination = () => (
        <div className="bg-gray-50 dark:bg-gray-800/50 px-6 py-4 border-t border-gray-100 dark:border-dark-border flex items-center justify-between mt-6 rounded-b-xl">
            <div className="text-sm text-gray-500 dark:text-gray-400">
                عرض {photographers.length} من أصل {pagination.total} مصور
            </div>
            <div className="flex gap-2">
                <button
                    onClick={() => setPagination(prev => ({ ...prev, page: prev.page - 1 }))}
                    disabled={pagination.page === 1}
                    className="px-3 py-1 border border-gray-300 dark:border-gray-600 rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300"
                >
                    السابق
                </button>
                <span className="px-3 py-1 text-sm flex items-center text-gray-700 dark:text-gray-300">
                    صفحة {pagination.page} من {pagination.pages}
                </span>
                <button
                    onClick={() => setPagination(prev => ({ ...prev, page: prev.page + 1 }))}
                    disabled={pagination.page === pagination.pages}
                    className="px-3 py-1 border border-gray-300 dark:border-gray-600 rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300"
                >
                    التالي
                </button>
            </div>
        </div>
    );

    if (loading && photographers.length === 0) return (
        <div className="flex justify-center items-center h-full">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
    );

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">إدارة المصورين</h1>
                    <p className="text-gray-500 dark:text-gray-400 mt-1">عرض وإدارة جميع المصورين وطلبات الانضمام</p>
                </div>
                <div className="relative w-full sm:w-64">
                    <input
                        type="text"
                        placeholder="بحث عن مصور..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full pl-4 pr-10 py-2 border border-gray-300 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-dark-card text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
                    />
                    <div className="absolute left-3 top-2.5 text-gray-400 dark:text-gray-500">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                            <circle cx="11" cy="11" r="8"></circle>
                            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                        </svg>
                    </div>
                </div>
            </div>

            {/* Tabs */}
            <div className="border-b border-gray-200 dark:border-dark-border">
                <nav className="-mb-px flex space-x-8 space-x-reverse">
                    <button
                        onClick={() => { setActiveTab('all'); setPagination(p => ({ ...p, page: 1 })); }}
                        className={`${activeTab === 'all'
                            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600'
                            } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center`}
                    >
                        <User size={16} className="ml-2" />
                        جميع المصورين
                    </button>
                    <button
                        onClick={() => { setActiveTab('pending'); setPagination(p => ({ ...p, page: 1 })); }}
                        className={`${activeTab === 'pending'
                            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600'
                            } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center`}
                    >
                        <Filter size={16} className="ml-2" />
                        طلبات الانضمام
                        {activeTab !== 'pending' && (
                            <span className="mr-2 bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400 py-0.5 px-2 rounded-full text-xs">
                                جديد
                            </span>
                        )}
                    </button>
                </nav>
            </div>

            {photographers.length === 0 ? (
                <div className="text-center py-12 bg-white dark:bg-dark-card rounded-xl border border-gray-100 dark:border-dark-border">
                    <Camera size={48} className="mx-auto text-gray-300 dark:text-gray-600 mb-4" />
                    <p className="text-gray-500 dark:text-gray-400 text-lg">
                        {activeTab === 'pending' ? 'لا توجد طلبات معلقة حالياً' : 'لا يوجد مصورين حالياً'}
                    </p>
                </div>
            ) : (
                <>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {photographers.map((photographer) => (
                            <div key={photographer._id} className="bg-white dark:bg-dark-card rounded-xl shadow-sm border border-gray-100 dark:border-dark-border overflow-hidden hover:shadow-md transition-all duration-200 flex flex-col">
                                <div className="p-6 flex-1">
                                    <div className="flex items-center justify-between mb-4">
                                        <div className="h-12 w-12 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400 font-bold text-xl overflow-hidden">
                                            {photographer.user?.avatar ? (
                                                <img src={photographer.user.avatar} alt={photographer.user.name} className="h-full w-full object-cover" />
                                            ) : (
                                                (photographer.user?.name || photographer.name || '?').charAt(0).toUpperCase()
                                            )}
                                        </div>
                                        <span className={`px-3 py-1 rounded-full text-xs font-medium ${photographer.verification?.status === 'approved' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300' :
                                            photographer.verification?.status === 'rejected' ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300' :
                                                photographer.verification?.status === 'pending' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300' :
                                                    'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                            }`}>
                                            {photographer.verification?.status === 'approved' ? 'معتمد' :
                                                photographer.verification?.status === 'rejected' ? 'مرفوض' :
                                                    photographer.verification?.status === 'pending' ? 'قيد المراجعة' :
                                                        'غير موثق'}
                                        </span>
                                    </div>
                                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-1">
                                        {photographer.user?.name || photographer.name || 'مستخدم غير معروف'}
                                    </h3>
                                    <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">{photographer.user?.email || photographer.email}</p>

                                    <div className="space-y-2 text-sm text-gray-600 dark:text-gray-300 mb-6">
                                        <div className="flex items-center">
                                            <Camera size={16} className="ml-2 text-gray-400 dark:text-gray-500" />
                                            <span>{photographer.specialty || photographer.specialties?.[0] || 'غير محدد'}</span>
                                        </div>
                                        <div className="flex items-center">
                                            <MapPin size={16} className="ml-2 text-gray-400 dark:text-gray-500" />
                                            <span>
                                                {typeof photographer.location === 'object' && photographer.location !== null
                                                    ? `${photographer.location.city || ''} - ${photographer.location.area || ''}`
                                                    : photographer.location || 'غير محدد'}
                                            </span>
                                        </div>
                                        <div className="flex items-center">
                                            <Calendar size={16} className="ml-2 text-gray-400 dark:text-gray-500" />
                                            <span>{photographer.experience || 'غير محدد'}</span>
                                        </div>
                                    </div>
                                </div>

                                {photographer.verification?.status === 'pending' && (
                                    <div className="p-4 bg-gray-50 dark:bg-gray-800/50 border-t border-gray-100 dark:border-dark-border flex gap-3">
                                        <button
                                            onClick={() => handleApprove(photographer._id)}
                                            className="flex-1 bg-green-600 hover:bg-green-700 text-white py-2 rounded-lg font-medium transition-colors flex items-center justify-center text-sm"
                                        >
                                            <Check size={16} className="ml-1" />
                                            قبول
                                        </button>
                                        <button
                                            onClick={() => handleReject(photographer._id)}
                                            className="flex-1 bg-white dark:bg-dark-card border border-red-200 dark:border-red-900/50 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 py-2 rounded-lg font-medium transition-colors flex items-center justify-center text-sm"
                                        >
                                            <X size={16} className="ml-1" />
                                            رفض
                                        </button>
                                    </div>
                                )}

                                {photographer.verification?.status === 'approved' && (
                                    <div className="p-4 bg-gray-50 dark:bg-gray-800/50 border-t border-gray-100 dark:border-dark-border">
                                        <button
                                            onClick={() => handleRevoke(photographer._id)}
                                            className="w-full bg-white dark:bg-dark-card border border-orange-200 dark:border-orange-900/50 text-orange-600 dark:text-orange-400 hover:bg-orange-50 dark:hover:bg-orange-900/20 py-2 rounded-lg font-medium transition-colors flex items-center justify-center text-sm"
                                        >
                                            <X size={16} className="ml-1" />
                                            سحب التوثيق
                                        </button>
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                    {renderPagination()}
                </>
            )}
        </div>
    );
};

export default Photographers;
