import { useState, useEffect } from 'react';
import api from '../api/axios';
import toast from 'react-hot-toast';
import { Star, Trash2, MessageSquare, User } from 'lucide-react';

const Reviews = () => {
    const [reviews, setReviews] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchReviews();
    }, []);

    const fetchReviews = async () => {
        try {
            const { data } = await api.get('/admin/reviews');
            setReviews(data.data);
        } catch (error) {
            console.error('Error fetching reviews:', error);
            // Fallback mock data
            setReviews([]);
        } finally {
            setLoading(false);
        }
    };

    const deleteReview = async (id) => {
        if (!window.confirm('هل أنت متأكد من حذف هذا التقييم؟')) return;

        try {
            await api.delete(`/admin/reviews/${id}`);
            setReviews(reviews.filter(r => r._id !== id));
            toast.success('تم حذف التقييم بنجاح');
        } catch (error) {
            console.error('Error deleting review:', error);
            toast.error('فشل في حذف التقييم');
        }
    };

    const renderStars = (rating) => {
        return [...Array(5)].map((_, index) => (
            <Star
                key={index}
                size={16}
                className={`${index < rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}`}
            />
        ));
    };

    if (loading) return (
        <div className="flex justify-center items-center h-full">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
    );

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">التقييمات والمراجعات</h1>
                <p className="text-gray-500 dark:text-gray-400 mt-1">إدارة تقييمات العملاء للمصورين</p>
            </div>

            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
                {reviews.length === 0 ? (
                    <div className="text-center py-12">
                        <MessageSquare size={48} className="mx-auto text-gray-300 dark:text-gray-600 mb-4" />
                        <p className="text-gray-500 dark:text-gray-400 text-lg">لا توجد تقييمات حتى الآن</p>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full text-right">
                            <thead className="bg-gray-50 dark:bg-gray-700/50 border-b border-gray-100 dark:border-gray-700">
                                <tr>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">العميل</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">المصور</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">التقييم</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">التعليق</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">التاريخ</th>
                                    <th className="px-6 py-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">إجراءات</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
                                {reviews.map((review) => (
                                    <tr key={review._id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center text-sm font-medium text-gray-900 dark:text-white">
                                                <User size={16} className="ml-2 text-gray-400" />
                                                {review.user?.name || 'مستخدم محذوف'}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="text-sm text-gray-600 dark:text-gray-300">
                                                {review.photographer?.name || 'مصور محذوف'}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center space-x-1 space-x-reverse">
                                                {renderStars(review.rating)}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <p className="text-sm text-gray-600 dark:text-gray-300 line-clamp-2 max-w-xs" title={review.comment}>
                                                {review.comment}
                                            </p>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                                            {new Date(review.createdAt).toLocaleDateString('ar-EG')}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                            <button
                                                onClick={() => deleteReview(review._id)}
                                                className="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 hover:bg-red-50 dark:hover:bg-red-900/20 p-2 rounded-lg transition-colors"
                                                title="حذف التقييم"
                                            >
                                                <Trash2 size={18} />
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Reviews;
