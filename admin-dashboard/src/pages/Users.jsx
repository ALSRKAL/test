import { useState, useEffect } from 'react';
import api from '../api/axios';
import toast from 'react-hot-toast';
import { Search, UserX, UserCheck, MoreVertical, Shield, Mail, Phone, Calendar, Camera, Plus, X, Edit2, Trash2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const UsersPage = () => {
    const { user: currentUser } = useAuth();
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [pagination, setPagination] = useState({
        page: 1,
        limit: 20,
        total: 0,
        pages: 1
    });
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingUser, setEditingUser] = useState(null);
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        password: '',
        phone: '',
        role: 'client',
        permissions: []
    });

    useEffect(() => {
        const delayDebounceFn = setTimeout(() => {
            fetchUsers(1);
        }, 500);

        return () => clearTimeout(delayDebounceFn);
    }, [searchTerm]);

    useEffect(() => {
        fetchUsers(pagination.page);
    }, [pagination.page]);

    const fetchUsers = async (page = 1) => {
        try {
            setLoading(true);
            const { data } = await api.get(`/admin/users?page=${page}&limit=${pagination.limit}&search=${searchTerm}`);
            setUsers(data.data);
            setPagination(prev => ({
                ...prev,
                page: data.pagination.page,
                total: data.pagination.total,
                pages: data.pagination.pages
            }));
        } catch (error) {
            console.error('Error fetching users:', error);
            toast.error('فشل في جلب المستخدمين');
            setUsers([]);
        } finally {
            setLoading(false);
        }
    };

    const toggleBlockUser = async (userId, currentStatus) => {
        try {
            await api.patch(`/admin/users/${userId}/block`);
            setUsers(users.map(user =>
                user._id === userId ? { ...user, isBlocked: !currentStatus } : user
            ));
            toast.success(currentStatus ? 'تم إلغاء حظر المستخدم بنجاح' : 'تم حظر المستخدم بنجاح');
        } catch (error) {
            console.error('Error toggling user block status:', error);
            toast.error('فشل في تحديث حالة المستخدم');
        }
    };

    const handleDeleteUser = async (userId) => {
        if (!window.confirm('هل أنت متأكد من حذف هذا المستخدم؟')) return;
        try {
            await api.delete(`/admin/users/${userId}`);
            setUsers(users.filter(user => user._id !== userId));
            toast.success('تم حذف المستخدم بنجاح');
        } catch (error) {
            console.error('Error deleting user:', error);
            toast.error('فشل في حذف المستخدم');
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingUser) {
                const { data } = await api.put(`/admin/users/${editingUser._id}`, formData);
                setUsers(users.map(u => u._id === editingUser._id ? data.data : u));
                toast.success('تم تحديث المستخدم بنجاح');
            } else {
                const { data } = await api.post('/admin/users', formData);
                setUsers([...users, data.data]);
                toast.success('تم إنشاء المستخدم بنجاح');
            }
            closeModal();
        } catch (error) {
            console.error('Error saving user:', error);
            toast.error(error.response?.data?.message || 'فشل في حفظ المستخدم');
        }
    };

    const openModal = (user = null) => {
        if (user) {
            setEditingUser(user);
            setFormData({
                name: user.name,
                email: user.email,
                phone: user.phone || '',
                role: user.role,
                permissions: user.permissions || []
            });
        } else {
            setEditingUser(null);
            setFormData({
                name: '',
                email: '',
                password: '',
                phone: '',
                role: 'client',
                permissions: []
            });
        }
        setIsModalOpen(true);
    };

    const closeModal = () => {
        setIsModalOpen(false);
        setEditingUser(null);
        setFormData({
            name: '',
            email: '',
            password: '',
            phone: '',
            role: 'client',
            permissions: []
        });
    };

    // Filter logic moved to backend
    const filteredUsers = users;

    if (loading) return (
        <div className="flex justify-center items-center h-full">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
    );

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 dark:text-white">إدارة النظام والمستخدمين</h1>
                    <p className="text-gray-500 dark:text-gray-400 mt-1">إدارة الصلاحيات والمستخدمين والتحكم الكامل بالنظام</p>
                </div>
                <div className="flex gap-3 w-full sm:w-auto">
                    <div className="relative flex-1 sm:w-64">
                        <input
                            type="text"
                            placeholder="بحث عن مستخدم..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-4 pr-10 py-2 border border-gray-300 dark:border-dark-border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-dark-card text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
                        />
                        <Search className="absolute left-3 top-2.5 text-gray-400 dark:text-gray-500" size={18} />
                    </div>
                    {currentUser?.role === 'superadmin' && (
                        <button
                            onClick={() => openModal()}
                            className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                        >
                            <Plus size={20} className="ml-2" />
                            مستخدم جديد
                        </button>
                    )}
                </div>
            </div>

            <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm border border-gray-100 dark:border-dark-border overflow-hidden transition-colors duration-200">
                <div className="overflow-x-auto">
                    <table className="w-full text-right">
                        <thead className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-dark-border">
                            <tr>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">المستخدم</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">معلومات الاتصال</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الدور</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">تاريخ الانضمام</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">الحالة</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">إجراءات</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100 dark:divide-dark-border">
                            {filteredUsers.map((user) => (
                                <tr key={user._id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center">
                                            <div className="h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold text-lg shadow-sm">
                                                {user.name.charAt(0).toUpperCase()}
                                            </div>
                                            <div className="mr-4">
                                                <div className="text-sm font-medium text-gray-900 dark:text-white">{user.name}</div>
                                                <div className="text-xs text-gray-500 dark:text-gray-400">ID: {user._id.substring(0, 8)}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex flex-col space-y-1">
                                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-300">
                                                <Mail size={14} className="ml-2 text-gray-400 dark:text-gray-500" />
                                                {user.email}
                                            </div>
                                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-300">
                                                <Phone size={14} className="ml-2 text-gray-400 dark:text-gray-500" />
                                                {user.phone || 'غير متوفر'}
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${user.role === 'superadmin' ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300' :
                                            user.role === 'admin' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300' :
                                                user.role === 'photographer' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300' :
                                                    'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                            }`}>
                                            <Shield size={12} className="ml-1" />
                                            {user.role === 'superadmin' ? 'مدير النظام' :
                                                user.role === 'admin' ? 'مسؤول' :
                                                    user.role === 'photographer' ? 'مصور' : 'عميل'}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
                                            <Calendar size={14} className="ml-2 text-gray-400 dark:text-gray-500" />
                                            {new Date(user.createdAt).toLocaleDateString('ar-EG')}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <span className={`inline-flex px-2 text-xs font-semibold leading-5 rounded-full ${user.isBlocked
                                            ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300'
                                            : 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                            }`}>
                                            {user.isBlocked ? 'محظور' : 'نشط'}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        {currentUser?.role === 'superadmin' ? (
                                            <div className="flex items-center gap-2">
                                                <button
                                                    onClick={() => openModal(user)}
                                                    className="text-blue-600 dark:text-blue-400 hover:text-blue-900 dark:hover:text-blue-300 p-1 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded"
                                                    title="تعديل"
                                                >
                                                    <Edit2 size={16} />
                                                </button>
                                                <button
                                                    onClick={() => toggleBlockUser(user._id, user.isBlocked)}
                                                    className={`${user.isBlocked ? 'text-green-600 dark:text-green-400 hover:text-green-900 dark:hover:text-green-300' : 'text-orange-600 dark:text-orange-400 hover:text-orange-900 dark:hover:text-orange-300'} p-1 hover:bg-gray-50 dark:hover:bg-gray-700 rounded`}
                                                    title={user.isBlocked ? 'إلغاء الحظر' : 'حظر'}
                                                >
                                                    {user.isBlocked ? <UserCheck size={16} /> : <UserX size={16} />}
                                                </button>
                                                <button
                                                    onClick={() => handleDeleteUser(user._id)}
                                                    className="text-red-600 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300 p-1 hover:bg-red-50 dark:hover:bg-red-900/20 rounded"
                                                    title="حذف"
                                                >
                                                    <Trash2 size={16} />
                                                </button>
                                            </div>
                                        ) : (
                                            <span className="text-gray-400 dark:text-gray-500 text-xs">عرض فقط</span>
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                {/* Pagination */}
                <div className="bg-gray-50 dark:bg-gray-800/50 px-6 py-4 border-t border-gray-100 dark:border-dark-border flex items-center justify-between">
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                        عرض {users.length} من أصل {pagination.total} مستخدم
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
            </div>

            {/* Add/Edit User Modal */}
            {
                isModalOpen && (
                    <div className="fixed inset-0 z-50 overflow-y-auto">
                        <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
                            <div className="fixed inset-0 transition-opacity" aria-hidden="true">
                                <div className="absolute inset-0 bg-gray-900 opacity-50 dark:opacity-70" onClick={closeModal}></div>
                            </div>

                            <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>

                            <div className="inline-block align-bottom bg-white dark:bg-dark-card rounded-lg text-right overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full relative z-50 border border-gray-100 dark:border-dark-border">
                                <div className="bg-white dark:bg-dark-card px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                                    <div className="flex justify-between items-center mb-4">
                                        <h3 className="text-lg leading-6 font-medium text-gray-900 dark:text-white">
                                            {editingUser ? 'تعديل المستخدم' : 'إضافة مستخدم جديد'}
                                        </h3>
                                        <button onClick={closeModal} className="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300">
                                            <X size={20} />
                                        </button>
                                    </div>
                                    <form onSubmit={handleSubmit} className="space-y-4">
                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">الاسم</label>
                                            <input
                                                type="text"
                                                required
                                                value={formData.name}
                                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">البريد الإلكتروني</label>
                                            <input
                                                type="email"
                                                required
                                                value={formData.email}
                                                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white"
                                            />
                                        </div>
                                        {!editingUser && (
                                            <div>
                                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">كلمة المرور</label>
                                                <input
                                                    type="password"
                                                    required
                                                    value={formData.password}
                                                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                                                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white"
                                                />
                                            </div>
                                        )}
                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">رقم الهاتف</label>
                                            <input
                                                type="text"
                                                value={formData.phone}
                                                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">الدور</label>
                                            <select
                                                value={formData.role}
                                                onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-dark-bg text-gray-900 dark:text-white"
                                            >
                                                <option value="client">عميل</option>
                                                <option value="photographer">مصور</option>
                                                <option value="admin">مسؤول</option>
                                                <option value="superadmin">مدير النظام</option>
                                            </select>
                                        </div>
                                        <div className="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
                                            <button
                                                type="submit"
                                                className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:col-start-2 sm:text-sm"
                                            >
                                                حفظ
                                            </button>
                                            <button
                                                type="button"
                                                onClick={closeModal}
                                                className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 dark:border-gray-600 shadow-sm px-4 py-2 bg-white dark:bg-gray-700 text-base font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:col-start-1 sm:text-sm"
                                            >
                                                إلغاء
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }
        </div >
    );
};

export default UsersPage;
