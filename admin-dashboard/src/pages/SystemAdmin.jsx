import React, { useState, useEffect } from 'react';
import {
    Shield,
    UserPlus,
    Trash2,
    Edit,
    Check,
    X,
    Search,
    AlertTriangle,
    Loader,
    Eye,
    EyeOff
} from 'lucide-react';
import api from '../api/axios';
import { toast } from 'react-hot-toast';
import { useAuth } from '../context/AuthContext';

const SystemAdmin = () => {
    const { user } = useAuth();
    const [admins, setAdmins] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [editingId, setEditingId] = useState(null);
    const [showPassword, setShowPassword] = useState(false);

    const initialFormData = {
        name: '',
        email: '',
        password: '',
        role: 'admin',
        permissions: {
            users: false,
            photographers: false,
            bookings: false,
            analytics: false,
            reviews: false,
            notifications: false,
            subscriptions: false,
            reports: false,
        }
    };

    const [formData, setFormData] = useState(initialFormData);

    const permissionsList = [
        { key: 'users', label: 'إدارة المستخدمين' },
        { key: 'photographers', label: 'إدارة المصورين' },
        { key: 'bookings', label: 'إدارة الحجوزات' },
        { key: 'analytics', label: 'عرض التحليلات' },
        { key: 'reviews', label: 'إدارة التقييمات' },
        { key: 'notifications', label: 'إرسال الإشعارات' },
        { key: 'subscriptions', label: 'إدارة الاشتراكات' },
        { key: 'reports', label: 'معالجة البلاغات' },
    ];

    useEffect(() => {
        fetchAdmins();
    }, []);

    const fetchAdmins = async () => {
        try {
            const response = await api.get('/admin/admins');
            setAdmins(response.data.data || []);
        } catch (error) {
            console.error('Error fetching admins:', error);
            if (error.response?.status === 403) {
                toast.error('ليس لديك صلاحية لعرض هذه الصفحة');
            } else {
                toast.error('فشل في جلب بيانات المسؤولين');
            }
        } finally {
            setLoading(false);
        }
    };

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handlePermissionChange = (key) => {
        setFormData(prev => ({
            ...prev,
            permissions: {
                ...prev.permissions,
                [key]: !prev.permissions[key]
            }
        }));
    };

    const handleEdit = (admin) => {
        setEditingId(admin._id);
        setFormData({
            name: admin.name,
            email: admin.email,
            password: '',
            role: admin.role,
            permissions: {
                users: false,
                photographers: false,
                bookings: false,
                analytics: false,
                reviews: false,
                notifications: false,
                subscriptions: false,
                reports: false,
                ...(admin.permissions || {})
            }
        });
        setShowModal(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsSubmitting(true);

        try {
            if (editingId) {
                await api.put(`/admin/admins/${editingId}`, formData);
                toast.success('تم تحديث بيانات المسؤول بنجاح');
            } else {
                await api.post('/admin/admins', formData);
                toast.success('تم إنشاء المسؤول بنجاح');
            }

            setShowModal(false);
            setFormData(initialFormData);
            setEditingId(null);
            setShowPassword(false);
            fetchAdmins();
        } catch (error) {
            console.error('Error saving admin:', error);
            toast.error(error.response?.data?.message || 'فشل في حفظ بيانات المسؤول');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('هل أنت متأكد من رغبتك في حذف هذا المسؤول؟')) return;

        try {
            await api.delete(`/admin/admins/${id}`);
            toast.success('تم حذف المسؤول بنجاح');
            setAdmins(prev => prev.filter(admin => admin._id !== id));
        } catch (error) {
            console.error('Error deleting admin:', error);
            toast.error('فشل في حذف المسؤول');
        }
    };

    const filteredAdmins = admins.filter(admin =>
        admin.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        admin.email.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getRoleLabel = (role) => {
        switch (role) {
            case 'superadmin': return 'مدير عام';
            case 'admin': return 'مسؤول';
            case 'employee': return 'موظف';
            default: return role;
        }
    };

    const getPermissionLabel = (key) => {
        const perm = permissionsList.find(p => p.key === key);
        return perm ? perm.label : key;
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-screen">
                <Loader className="animate-spin text-blue-600" size={40} />
            </div>
        );
    }

    return (
        <div className="p-6 space-y-6" dir="rtl">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
                        <Shield className="text-blue-600 dark:text-blue-500" />
                        مسؤول النظام
                    </h1>
                    <p className="text-gray-500 dark:text-gray-400 mt-1">إدارة صلاحيات الوصول للنظام</p>
                </div>

                <button
                    onClick={() => {
                        setEditingId(null);
                        setFormData(initialFormData);
                        setShowModal(true);
                    }}
                    className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
                >
                    <UserPlus size={20} className="ml-2" />
                    إضافة مستخدم جديد
                </button>
            </div>

            {/* Search and Filter */}
            <div className="bg-white dark:bg-dark-card p-4 rounded-xl shadow-sm border border-gray-100 dark:border-dark-border transition-colors duration-200">
                <div className="relative">
                    <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
                    <input
                        type="text"
                        placeholder="بحث عن مسؤول..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full pr-10 pl-4 py-2 border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 transition-all"
                    />
                </div>
            </div>

            {/* Admins List */}
            <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm border border-gray-100 dark:border-dark-border overflow-hidden transition-colors duration-200">
                <div className="overflow-x-auto">
                    <table className="w-full text-right">
                        <thead className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-dark-border">
                            <tr>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">المستخدم</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الدور</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الصلاحيات</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الحالة</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-left">الإجراءات</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100 dark:divide-dark-border">
                            {filteredAdmins.length > 0 ? (
                                filteredAdmins.map((admin) => (
                                    <tr key={admin._id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/50 transition-colors">
                                        <td className="px-6 py-4">
                                            <div className="flex items-center">
                                                <div className="h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold text-lg shadow-sm">
                                                    {admin.name.charAt(0).toUpperCase()}
                                                </div>
                                                <div className="mr-4">
                                                    <div className="font-medium text-gray-900 dark:text-white">{admin.name}</div>
                                                    <div className="text-sm text-gray-500 dark:text-gray-400">{admin.email}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                        ${admin.role === 'superadmin' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300' :
                                                    admin.role === 'admin' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300' :
                                                        'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300'}`}>
                                                {getRoleLabel(admin.role)}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="flex flex-wrap gap-1">
                                                {admin.role === 'superadmin' ? (
                                                    <span className="text-xs text-gray-500 dark:text-gray-400 italic">صلاحيات كاملة</span>
                                                ) : (
                                                    Object.entries(admin.permissions || {})
                                                        .filter(([_, hasAccess]) => hasAccess)
                                                        .slice(0, 3)
                                                        .map(([key]) => (
                                                            <span key={key} className="px-2 py-0.5 bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 rounded text-xs">
                                                                {getPermissionLabel(key)}
                                                            </span>
                                                        ))
                                                )}
                                                {admin.role !== 'superadmin' && Object.values(admin.permissions || {}).filter(Boolean).length > 3 && (
                                                    <span className="text-xs text-gray-400 dark:text-gray-500 self-center">
                                                        +{Object.values(admin.permissions || {}).filter(Boolean).length - 3} المزيد
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300">
                                                نشط
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-left">
                                            {admin.role !== 'superadmin' && (
                                                <div className="flex justify-end gap-2">
                                                    <button
                                                        onClick={() => handleEdit(admin)}
                                                        className="text-blue-400 hover:text-blue-600 dark:text-blue-400 dark:hover:text-blue-300 transition-colors p-2 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg"
                                                        title="تعديل"
                                                    >
                                                        <Edit size={18} />
                                                    </button>
                                                    <button
                                                        onClick={() => handleDelete(admin._id)}
                                                        className="text-red-400 hover:text-red-600 dark:text-red-400 dark:hover:text-red-300 transition-colors p-2 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg"
                                                        title="حذف"
                                                    >
                                                        <Trash2 size={18} />
                                                    </button>
                                                </div>
                                            )}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="5" className="px-6 py-12 text-center text-gray-500 dark:text-gray-400">
                                        لا يوجد مسؤولين
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Create/Edit Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
                    <div className="bg-white dark:bg-dark-card rounded-2xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto transition-colors duration-200">
                        <div className="p-6 border-b border-gray-100 dark:border-dark-border flex justify-between items-center sticky top-0 bg-white dark:bg-dark-card z-10">
                            <h2 className="text-xl font-bold text-gray-900 dark:text-white">{editingId ? 'تعديل مسؤول' : 'إضافة مسؤول جديد'}</h2>
                            <button
                                onClick={() => setShowModal(false)}
                                className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
                            >
                                <X size={20} />
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} className="p-6 space-y-6">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div className="space-y-2">
                                    <label className="text-sm font-medium text-gray-700 dark:text-gray-300">الاسم الكامل</label>
                                    <input
                                        type="text"
                                        name="name"
                                        required
                                        value={formData.name}
                                        onChange={handleInputChange}
                                        className="w-full px-4 py-2 border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
                                        placeholder="الاسم"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <label className="text-sm font-medium text-gray-700 dark:text-gray-300">البريد الإلكتروني</label>
                                    <input
                                        type="email"
                                        name="email"
                                        required
                                        value={formData.email}
                                        onChange={handleInputChange}
                                        className="w-full px-4 py-2 border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
                                        placeholder="example@domain.com"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                                        كلمة المرور {editingId && <span className="text-gray-400 font-normal text-xs">(اتركه فارغاً للإبقاء على الحالي)</span>}
                                    </label>
                                    <div className="relative">
                                        <input
                                            type={showPassword ? "text" : "password"}
                                            name="password"
                                            required={!editingId}
                                            value={formData.password}
                                            onChange={handleInputChange}
                                            className="w-full px-4 py-2 border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
                                            placeholder="••••••••"
                                        />
                                        <button
                                            type="button"
                                            onClick={() => setShowPassword(!showPassword)}
                                            className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                                        >
                                            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                        </button>
                                    </div>
                                </div>

                                <div className="space-y-2">
                                    <label className="text-sm font-medium text-gray-700 dark:text-gray-300">الدور</label>
                                    <select
                                        name="role"
                                        value={formData.role}
                                        onChange={handleInputChange}
                                        className="w-full px-4 py-2 border border-gray-200 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white"
                                    >
                                        <option value="admin">مسؤول</option>
                                        <option value="superadmin">مدير عام</option>
                                        <option value="employee">موظف</option>
                                    </select>
                                </div>
                            </div>

                            {formData.role !== 'superadmin' && (
                                <div className="space-y-4">
                                    <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 border-b border-gray-100 dark:border-dark-border pb-2">الصلاحيات</h3>
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                        {permissionsList.map((perm) => (
                                            <label key={perm.key} className="flex items-center p-3 border border-gray-100 dark:border-dark-border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors">
                                                <input
                                                    type="checkbox"
                                                    checked={formData.permissions[perm.key]}
                                                    onChange={() => handlePermissionChange(perm.key)}
                                                    className="w-4 h-4 text-blue-600 rounded border-gray-300 dark:border-gray-600 focus:ring-blue-500 dark:bg-gray-700"
                                                />
                                                <span className="mr-3 text-sm text-gray-600 dark:text-gray-300">{perm.label}</span>
                                            </label>
                                        ))}
                                    </div>
                                </div>
                            )}

                            <div className="flex justify-end pt-4 border-t border-gray-100 dark:border-dark-border">
                                <button
                                    type="button"
                                    onClick={() => setShowModal(false)}
                                    className="px-6 py-2 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg ml-3 transition-colors"
                                >
                                    إلغاء
                                </button>
                                <button
                                    type="submit"
                                    disabled={isSubmitting}
                                    className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                                >
                                    {isSubmitting ? (
                                        <>
                                            <Loader size={18} className="animate-spin ml-2" />
                                            {editingId ? 'جاري الحفظ...' : 'جاري الإنشاء...'}
                                        </>
                                    ) : (
                                        editingId ? 'حفظ التغييرات' : 'إنشاء مستخدم'
                                    )}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default SystemAdmin;
