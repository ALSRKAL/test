import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/shared/widgets/inputs/custom_textfield.dart';
import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/core/constants/api_endpoints.dart';
import 'package:hajzy/core/utils/error_handler.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': widget.email,
          'code': widget.code,
          'newPassword': _passwordController.text,
        },
      );

      if (!mounted) return;

      if (response.data['success']) {
        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // الانتقال إلى صفحة تسجيل الدخول
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
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
        title: const Text('كلمة مرور جديدة'),
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
                    Icons.lock_open_rounded,
                    size: 50,
                    color: AppColors.primaryGradientStart,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // العنوان
                Text(
                  'إنشاء كلمة مرور جديدة',
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
                  'أدخل كلمة المرور الجديدة الخاصة بك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                
                // حقل كلمة المرور
                CustomTextField(
                  label: 'كلمة المرور الجديدة',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // حقل تأكيد كلمة المرور
                CustomTextField(
                  label: 'تأكيد كلمة المرور',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // زر التأكيد
                CustomButton(
                  text: 'تأكيد',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _resetPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
