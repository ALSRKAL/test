import { useState, useEffect } from 'react';
import api from '../api/axios';
import toast from 'react-hot-toast';
import { Check, X, FileText, Calendar, User, Eye, ShieldCheck } from 'lucide-react';

const VerificationRequests = () => {
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedRequest, setSelectedRequest] = useState(null);
    const [rejectModalOpen, setRejectModalOpen] = useState(false);
    const [rejectionReason, setRejectionReason] = useState('');
    const [pagination, setPagination] = useState({
        page: 1,
        limit: 20,
        total: 0,
        pages: 1
    });

    useEffect(() => {
        fetchRequests(pagination.page);
    }, [pagination.page]);

    const fetchRequests = async (page = 1) => {
        try {
            setLoading(true);
            const { data } = await api.get(`/admin/photographers/pending?page=${page}&limit=${pagination.limit}`);
            setRequests(data.data);
            if (data.pagination) {
                setPagination(prev => ({
                    ...prev,
                    page: data.pagination.page,
                    total: data.pagination.total,
                    pages: data.pagination.pages
                }));
            }
        } catch (error) {
            console.error('Error fetching verification requests:', error);
            toast.error('فشل في جلب طلبات التوثيق');
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (id) => {
        if (!window.confirm('هل أنت متأكد من قبول طلب التوثيق هذا؟')) return;

        try {
            await api.patch(`/admin/photographers/${id}/approve`);
            setRequests(requests.filter(r => r._id !== id));
            toast.success('تم قبول التوثيق بنجاح');
            setSelectedRequest(null);
        } catch (error) {
            console.error('Error approving request:', error);
            toast.error('فشل في قبول التوثيق');
        }
    };

    const handleReject = async () => {
        if (!rejectionReason.trim()) {
            toast.error('الرجاء إدخال سبب الرفض');
            return;
        }

        try {
            await api.patch(`/admin/photographers/${selectedRequest._id}/reject`, { reason: rejectionReason });
            setRequests(requests.filter(r => r._id !== selectedRequest._id));
            toast.success('تم رفض التوثيق');
            setRejectModalOpen(false);
            setSelectedRequest(null);
            setRejectionReason('');
        } catch (error) {
            console.error('Error rejecting request:', error);
            toast.error('فشل في رفض التوثيق');
        }
    };

    const openRejectModal = (request) => {
        setSelectedRequest(request);
        setRejectModalOpen(true);
    };

    const renderPagination = () => (
        <div className="bg-gray-50 px-6 py-4 border-t border-gray-100 flex items-center justify-between mt-6 rounded-b-xl">
            <div className="text-sm text-gray-500">
                عرض {requests.length} من أصل {pagination.total} طلب
            </div>
            <div className="flex gap-2">
                <button
                    onClick={() => setPagination(prev => ({ ...prev, page: prev.page - 1 }))}
                    disabled={pagination.page === 1}
                    className="px-3 py-1 border border-gray-300 rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-100"
                >
                    السابق
                </button>
                <span className="px-3 py-1 text-sm flex items-center">
                    صفحة {pagination.page} من {pagination.pages}
                </span>
                <button
                    onClick={() => setPagination(prev => ({ ...prev, page: prev.page + 1 }))}
                    disabled={pagination.page === pagination.pages}
                    className="px-3 py-1 border border-gray-300 rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-100"
                >
                    التالي
                </button>
            </div>
        </div>
    );

    if (loading && requests.length === 0) return (
        <div className="flex justify-center items-center h-full">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
    );

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
                        <ShieldCheck className="text-blue-600" />
                        طلبات التوثيق
                    </h1>
                    <p className="text-gray-500 mt-1">مراجعة وإدارة طلبات توثيق المصورين</p>
                </div>
            </div>

            {requests.length === 0 ? (
                <div className="text-center py-12 bg-white rounded-xl border border-gray-100">
                    <ShieldCheck size={48} className="mx-auto text-gray-300 mb-4" />
                    <p className="text-gray-500 text-lg">لا توجد طلبات توثيق معلقة حالياً</p>
                </div>
            ) : (
                <>
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        {requests.map((request) => (
                            <div key={request._id} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow">
                                <div className="p-6">
                                    <div className="flex items-center justify-between mb-4">
                                        <div className="flex items-center gap-3">
                                            <div className="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-xl overflow-hidden">
                                                {request.user?.avatar ? (
                                                    <img src={request.user.avatar} alt={request.user.name} className="h-full w-full object-cover" />
                                                ) : (
                                                    (request.user?.name || '?').charAt(0).toUpperCase()
                                                )}
                                            </div>
                                            <div>
                                                <h3 className="text-lg font-bold text-gray-900">
                                                    {request.user?.name || 'مستخدم غير معروف'}
                                                </h3>
                                                <p className="text-sm text-gray-500">{request.user?.email}</p>
                                            </div>
                                        </div>
                                        <span className="px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                                            قيد المراجعة
                                        </span>
                                    </div>

                                    <div className="space-y-3 mb-6">
                                        <div className="flex items-center text-sm text-gray-600">
                                            <Calendar size={16} className="ml-2 text-gray-400" />
                                            <span>تاريخ الطلب: {new Date(request.verification?.submittedAt).toLocaleDateString('ar-SA')}</span>
                                        </div>

                                        <div className="bg-gray-50 p-4 rounded-lg">
                                            <h4 className="text-sm font-semibold text-gray-900 mb-3 flex items-center">
                                                <FileText size={16} className="ml-2 text-blue-600" />
                                                المستندات المرفقة
                                            </h4>
                                            <div className="grid grid-cols-2 gap-3">
                                                {request.verification?.documents?.idCard && (
                                                    <a
                                                        href={request.verification.documents.idCard}
                                                        target="_blank"
                                                        rel="noopener noreferrer"
                                                        className="flex items-center justify-center p-3 bg-white border border-gray-200 rounded-lg hover:border-blue-500 hover:text-blue-600 transition-colors text-sm group"
                                                    >
                                                        <Eye size={16} className="ml-2 text-gray-400 group-hover:text-blue-600" />
                                                        الهوية الشخصية
                                                    </a>
                                                )}
                                                {request.verification?.documents?.portfolioSamples?.length > 0 && (
                                                    <button
                                                        onClick={() => setSelectedRequest(request)}
                                                        className="flex items-center justify-center p-3 bg-white border border-gray-200 rounded-lg hover:border-blue-500 hover:text-blue-600 transition-colors text-sm group"
                                                    >
                                                        <Eye size={16} className="ml-2 text-gray-400 group-hover:text-blue-600" />
                                                        نماذج الأعمال ({request.verification.documents.portfolioSamples.length})
                                                    </button>
                                                )}
                                            </div>
                                        </div>
                                    </div>

                                    <div className="flex gap-3">
                                        <button
                                            onClick={() => handleApprove(request._id)}
                                            className="flex-1 bg-green-600 hover:bg-green-700 text-white py-2 rounded-lg font-medium transition-colors flex items-center justify-center text-sm"
                                        >
                                            <Check size={16} className="ml-1" />
                                            قبول التوثيق
                                        </button>
                                        <button
                                            onClick={() => openRejectModal(request)}
                                            className="flex-1 bg-white border border-red-200 text-red-600 hover:bg-red-50 py-2 rounded-lg font-medium transition-colors flex items-center justify-center text-sm"
                                        >
                                            <X size={16} className="ml-1" />
                                            رفض
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                    {renderPagination()}
                </>
            )}

            {/* Document Viewer Modal */}
            {selectedRequest && !rejectModalOpen && (
                <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col">
                        <div className="p-4 border-b border-gray-100 flex justify-between items-center">
                            <h3 className="text-lg font-bold text-gray-900">مراجعة المستندات - {selectedRequest.user?.name}</h3>
                            <button onClick={() => setSelectedRequest(null)} className="text-gray-400 hover:text-gray-600">
                                <X size={24} />
                            </button>
                        </div>
                        <div className="p-6 overflow-y-auto bg-gray-50">
                            <div className="space-y-6">
                                <div>
                                    <h4 className="font-semibold mb-3 text-gray-900">الهوية الشخصية</h4>
                                    {selectedRequest.verification?.documents?.idCard ? (
                                        <img
                                            src={selectedRequest.verification.documents.idCard}
                                            alt="ID Card"
                                            className="max-w-full h-auto rounded-lg border border-gray-200 shadow-sm"
                                        />
                                    ) : (
                                        <p className="text-gray-500 text-sm">لا توجد هوية مرفقة</p>
                                    )}
                                </div>

                                <div>
                                    <h4 className="font-semibold mb-3 text-gray-900">نماذج الأعمال</h4>
                                    {selectedRequest.verification?.documents?.portfolioSamples?.length > 0 ? (
                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                            {selectedRequest.verification.documents.portfolioSamples.map((sample, idx) => (
                                                <img
                                                    key={idx}
                                                    src={sample}
                                                    alt={`Portfolio Sample ${idx + 1}`}
                                                    className="w-full h-64 object-cover rounded-lg border border-gray-200 shadow-sm"
                                                />
                                            ))}
                                        </div>
                                    ) : (
                                        <p className="text-gray-500 text-sm">لا توجد نماذج أعمال مرفقة</p>
                                    )}
                                </div>
                            </div>
                        </div>
                        <div className="p-4 border-t border-gray-100 flex justify-end gap-3 bg-white">
                            <button
                                onClick={() => openRejectModal(selectedRequest)}
                                className="px-4 py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-50 text-sm font-medium"
                            >
                                رفض الطلب
                            </button>
                            <button
                                onClick={() => handleApprove(selectedRequest._id)}
                                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm font-medium"
                            >
                                قبول الطلب
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Reject Modal */}
            {rejectModalOpen && (
                <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-2xl max-w-md w-full p-6">
                        <h3 className="text-lg font-bold text-gray-900 mb-4">رفض طلب التوثيق</h3>
                        <p className="text-sm text-gray-500 mb-4">
                            الرجاء ذكر سبب الرفض وسيتم إرساله للمصور عبر البريد الإلكتروني.
                        </p>
                        <textarea
                            value={rejectionReason}
                            onChange={(e) => setRejectionReason(e.target.value)}
                            placeholder="سبب الرفض..."
                            className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent mb-4 min-h-[100px]"
                        />
                        <div className="flex justify-end gap-3">
                            <button
                                onClick={() => {
                                    setRejectModalOpen(false);
                                    setRejectionReason('');
                                }}
                                className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg text-sm font-medium"
                            >
                                إلغاء
                            </button>
                            <button
                                onClick={handleReject}
                                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm font-medium"
                            >
                                تأكيد الرفض
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default VerificationRequests;
