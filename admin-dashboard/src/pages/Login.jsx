import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { Lock, Mail, ArrowLeft, Loader2 } from 'lucide-react';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const { login } = useAuth();
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            console.log('Attempting login with:', email);
            await login(email, password);
            toast.success('تم تسجيل الدخول بنجاح');
            navigate('/');
        } catch (error) {
            console.error('Login error:', error);
            const errorMessage = error.response?.data?.message || 'فشل تسجيل الدخول. يرجى التحقق من بيانات الاعتماد.';
            toast.error(errorMessage);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900 p-4 relative overflow-hidden">
            {/* Abstract Background Shapes */}
            <div className="absolute top-0 left-0 w-96 h-96 bg-blue-500/20 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2"></div>
            <div className="absolute bottom-0 right-0 w-96 h-96 bg-purple-500/20 rounded-full blur-3xl translate-x-1/2 translate-y-1/2"></div>

            <div className="bg-white/10 backdrop-blur-xl w-full max-w-md rounded-3xl shadow-2xl border border-white/20 overflow-hidden relative z-10 animate-fade-in">
                <div className="p-8 md:p-10">
                    <div className="text-center mb-10">
                        <h1 className="text-4xl font-black bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent mb-2 tracking-tight">حجزي</h1>
                        <p className="text-gray-300 text-sm font-medium">لوحة تحكم المسؤول</p>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-6">
                        <div className="space-y-2">
                            <label className="block text-sm font-medium text-gray-300 mr-1">البريد الإلكتروني</label>
                            <div className="relative group">
                                <input
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="w-full pl-4 pr-12 py-3.5 bg-gray-800/50 border border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-white placeholder-gray-500 transition-all group-hover:bg-gray-800/70"
                                    placeholder="admin@example.com"
                                    required
                                />
                                <Mail className="absolute left-4 top-3.5 text-gray-500 group-focus-within:text-blue-500 transition-colors" size={20} />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="block text-sm font-medium text-gray-300 mr-1">كلمة المرور</label>
                            <div className="relative group">
                                <input
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="w-full pl-4 pr-12 py-3.5 bg-gray-800/50 border border-gray-700 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-white placeholder-gray-500 transition-all group-hover:bg-gray-800/70"
                                    placeholder="••••••••"
                                    required
                                />
                                <Lock className="absolute left-4 top-3.5 text-gray-500 group-focus-within:text-blue-500 transition-colors" size={20} />
                            </div>
                        </div>

                        <div className="flex items-center justify-between text-sm pt-2">
                            <label className="flex items-center text-gray-400 cursor-pointer hover:text-gray-300 transition-colors">
                                <input type="checkbox" className="form-checkbox h-4 w-4 text-blue-600 rounded border-gray-600 bg-gray-800 focus:ring-blue-500 focus:ring-offset-gray-900" />
                                <span className="mr-2">تذكرني</span>
                            </label>
                            <a href="#" className="text-blue-400 hover:text-blue-300 font-medium transition-colors">نسيت كلمة المرور؟</a>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-bold py-4 px-4 rounded-xl transition-all transform hover:scale-[1.02] active:scale-[0.98] flex items-center justify-center disabled:opacity-70 disabled:cursor-not-allowed disabled:transform-none shadow-lg shadow-blue-900/30 mt-4"
                        >
                            {loading ? (
                                <Loader2 className="animate-spin" size={24} />
                            ) : (
                                <>
                                    تسجيل الدخول
                                    <ArrowLeft size={20} className="mr-2" />
                                </>
                            )}
                        </button>
                    </form>
                </div>
                <div className="bg-gray-900/50 p-4 text-center border-t border-white/5">
                    <p className="text-xs text-gray-500 font-medium">
                        &copy; {new Date().getFullYear()} Hajzy. جميع الحقوق محفوظة.
                    </p>
                </div>
            </div>
        </div>
    );
};

export default Login;
