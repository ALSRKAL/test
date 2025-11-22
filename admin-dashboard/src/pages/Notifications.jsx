import { useState } from 'react';
import api from '../api/axios';
import toast from 'react-hot-toast';
import { Send, Bell, Users, CheckCircle, AlertCircle } from 'lucide-react';

const Notifications = () => {
    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');
    const [targetGroup, setTargetGroup] = useState('all'); // all, clients, photographers
    const [sending, setSending] = useState(false);
    const [success, setSuccess] = useState(false);

    const handleBroadcast = async (e) => {
        e.preventDefault();
        if (!title.trim() || !message.trim()) {
            toast.error('الرجاء إدخال العنوان والرسالة');
            return;
        }

        setSending(true);
        try {
            await api.post('/admin/notifications/broadcast', {
                title,
                body: message,
                target: targetGroup
            });
            toast.success('تم إرسال الإشعار بنجاح');
            setSuccess(true);
            setTitle('');
            setMessage('');
            setTimeout(() => setSuccess(false), 3000);
        } catch (error) {
            console.error('Error sending notification:', error);
            toast.error('فشل في إرسال الإشعار');
        } finally {
            setSending(false);
        }
    };

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">إرسال إشعارات</h1>
                <p className="text-gray-500 dark:text-gray-400 mt-1">إرسال إشعارات فورية للمستخدمين والمصورين</p>
            </div>

            <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm border border-gray-100 dark:border-dark-border overflow-hidden transition-colors duration-200">
                <div className="p-6 sm:p-8">
                    {success ? (
                        <div className="text-center py-12">
                            <div className="mx-auto h-16 w-16 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center mb-4">
                                <CheckCircle size={32} className="text-green-600 dark:text-green-400" />
                            </div>
                            <h3 className="text-xl font-bold text-gray-900 dark:text-white">تم الإرسال بنجاح!</h3>
                            <p className="text-gray-500 dark:text-gray-400 mt-2">تم إرسال الإشعار إلى الفئة المستهدفة.</p>
                            <button
                                onClick={() => setSuccess(false)}
                                className="mt-6 text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium hover:underline"
                            >
                                إرسال إشعار آخر
                            </button>
                        </div>
                    ) : (
                        <form onSubmit={handleBroadcast} className="space-y-6">
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                                {/* Target Group Selection */}
                                <div className="md:col-span-1 space-y-4">
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">الفئة المستهدفة</label>

                                    <div
                                        className={`p-4 rounded-lg border cursor-pointer transition-all ${targetGroup === 'all' ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 ring-1 ring-blue-500' : 'border-gray-200 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-700'}`}
                                        onClick={() => setTargetGroup('all')}
                                    >
                                        <div className="flex items-center">
                                            <div className={`p-2 rounded-full ${targetGroup === 'all' ? 'bg-blue-200 text-blue-700 dark:bg-blue-800 dark:text-blue-200' : 'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400'}`}>
                                                <Users size={20} />
                                            </div>
                                            <div className="mr-3">
                                                <p className={`font-medium ${targetGroup === 'all' ? 'text-blue-900 dark:text-blue-300' : 'text-gray-900 dark:text-white'}`}>الجميع</p>
                                                <p className="text-xs text-gray-500 dark:text-gray-400">كل المستخدمين والمصورين</p>
                                            </div>
                                        </div>
                                    </div>

                                    <div
                                        className={`p-4 rounded-lg border cursor-pointer transition-all ${targetGroup === 'clients' ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 ring-1 ring-blue-500' : 'border-gray-200 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-700'}`}
                                        onClick={() => setTargetGroup('clients')}
                                    >
                                        <div className="flex items-center">
                                            <div className={`p-2 rounded-full ${targetGroup === 'clients' ? 'bg-blue-200 text-blue-700 dark:bg-blue-800 dark:text-blue-200' : 'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400'}`}>
                                                <Users size={20} />
                                            </div>
                                            <div className="mr-3">
                                                <p className={`font-medium ${targetGroup === 'clients' ? 'text-blue-900 dark:text-blue-300' : 'text-gray-900 dark:text-white'}`}>العملاء فقط</p>
                                                <p className="text-xs text-gray-500 dark:text-gray-400">المستخدمين العاديين</p>
                                            </div>
                                        </div>
                                    </div>

                                    <div
                                        className={`p-4 rounded-lg border cursor-pointer transition-all ${targetGroup === 'photographers' ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 ring-1 ring-blue-500' : 'border-gray-200 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-700'}`}
                                        onClick={() => setTargetGroup('photographers')}
                                    >
                                        <div className="flex items-center">
                                            <div className={`p-2 rounded-full ${targetGroup === 'photographers' ? 'bg-blue-200 text-blue-700 dark:bg-blue-800 dark:text-blue-200' : 'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400'}`}>
                                                <Users size={20} />
                                            </div>
                                            <div className="mr-3">
                                                <p className={`font-medium ${targetGroup === 'photographers' ? 'text-blue-900 dark:text-blue-300' : 'text-gray-900 dark:text-white'}`}>المصورين فقط</p>
                                                <p className="text-xs text-gray-500 dark:text-gray-400">مقدمي الخدمات</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {/* Message Content */}
                                <div className="md:col-span-2 space-y-6">
                                    <div>
                                        <label htmlFor="title" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">عنوان الإشعار</label>
                                        <div className="relative">
                                            <input
                                                type="text"
                                                id="title"
                                                value={title}
                                                onChange={(e) => setTitle(e.target.value)}
                                                className="w-full pl-4 pr-10 py-2.5 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-dark-bg text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
                                                placeholder="مثال: خصم خاص بمناسبة العيد"
                                            />
                                            <Bell className="absolute left-3 top-3 text-gray-400 dark:text-gray-500" size={18} />
                                        </div>
                                    </div>

                                    <div>
                                        <label htmlFor="message" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">نص الرسالة</label>
                                        <textarea
                                            id="message"
                                            rows={6}
                                            value={message}
                                            onChange={(e) => setMessage(e.target.value)}
                                            className="w-full p-4 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none bg-white dark:bg-dark-bg text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
                                            placeholder="اكتب محتوى الإشعار هنا..."
                                        />
                                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 text-left">
                                            {message.length} / 500 حرف
                                        </p>
                                    </div>

                                    <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg flex items-start">
                                        <AlertCircle className="text-blue-600 dark:text-blue-400 mt-0.5 ml-3 flex-shrink-0" size={18} />
                                        <p className="text-sm text-blue-800 dark:text-blue-300">
                                            سيتم إرسال هذا الإشعار فوراً إلى جميع المستخدمين في الفئة المحددة. لا يمكن التراجع عن هذا الإجراء.
                                        </p>
                                    </div>

                                    <div className="flex justify-end">
                                        <button
                                            type="submit"
                                            disabled={sending || !title || !message}
                                            className={`flex items-center px-6 py-2.5 rounded-lg text-white font-medium transition-all ${sending || !title || !message
                                                ? 'bg-gray-300 dark:bg-gray-700 cursor-not-allowed'
                                                : 'bg-blue-600 hover:bg-blue-700 shadow-md hover:shadow-lg'
                                                }`}
                                        >
                                            {sending ? (
                                                <>
                                                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white ml-2"></div>
                                                    جاري الإرسال...
                                                </>
                                            ) : (
                                                <>
                                                    <Send size={18} className="ml-2" />
                                                    إرسال الإشعار
                                                </>
                                            )}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    )}
                </div>
            </div>
        </div>
    );
};

export default Notifications;
