import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/shared/widgets/inputs/custom_textfield.dart';
import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/core/constants/api_endpoints.dart';
import 'package:hajzy/core/utils/error_handler.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': _emailController.text.trim()},
      );

      if (!mounted) return;

      if (response.data['success']) {
        // الانتقال إلى صفحة إدخال الرمز
        Navigator.pushNamed(
          context,
          '/verify-reset-code',
          arguments: _emailController.text.trim(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = ErrorHandler.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نسيت كلمة المرور'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                // أيقونة
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGradientStart.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 50,
                    color: AppColors.primaryGradientStart,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // العنوان
                Text(
                  'استعادة كلمة المرور',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // الوصف
                Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رمز التحقق',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                
                // حقل البريد الإلكتروني
                CustomTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // زر الإرسال
                CustomButton(
                  text: 'إرسال رمز التحقق',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _sendResetCode,
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // العودة لتسجيل الدخول
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'تذكرت كلمة المرور؟',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تسجيل الدخول'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
