import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/shared/widgets/inputs/custom_textfield.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/shared/widgets/dialogs/auth_error_dialog.dart';
import 'package:hajzy/core/errors/auth_error_type.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'client';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleError(BuildContext context, AuthErrorInfo errorInfo) {
    AuthErrorDialog.show(
      context,
      errorInfo,
      onActionPressed: () {
        // معالجة الإجراءات المختلفة
        switch (errorInfo.type) {
          case AuthErrorType.userAlreadyExists:
            // الانتقال إلى صفحة تسجيل الدخول
            Navigator.pop(context); // العودة إلى صفحة تسجيل الدخول
            break;
          default:
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Logo
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'انضم إلينا الآن',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Name Field
                CustomTextField(
                  label: 'الاسم الكامل',
                  hint: 'أدخل اسمك الكامل',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Email Field
                CustomTextField(
                  label: AppStrings.email,
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
                const SizedBox(height: AppSpacing.lg),
                // Phone Field with Yemen Country Code
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم الجوال',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country Code
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              children: [
                                const Text('🇾🇪', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  '+967',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Phone Number
                        Expanded(
                          child: CustomTextField(
                            hint: '7xxxxxxxx',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال رقم الجوال';
                              }

                              // إزالة المسافات والرموز
                              final cleanNumber = value.replaceAll(
                                RegExp(r'[^\d]'),
                                '',
                              );

                              // التحقق من أن الرقم يبدأ بـ 7
                              if (!cleanNumber.startsWith('7')) {
                                return 'الرقم يجب أن يبدأ بـ 7';
                              }

                              // التحقق من طول الرقم (9 أرقام)
                              if (cleanNumber.length != 9) {
                                return 'الرقم يجب أن يكون 9 أرقام';
                              }

                              // التحقق من أن الرقم يبدأ بأحد البادئات اليمنية الصحيحة
                              final validPrefixes = [
                                '70',
                                '71',
                                '73',
                                '77',
                                '78',
                              ];
                              final prefix = cleanNumber.substring(0, 2);

                              if (!validPrefixes.contains(prefix)) {
                                return 'رقم الجوال غير صحيح';
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'مثال: 771234567 أو 733456789',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Role Selection
                Text(
                  'نوع الحساب',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('عميل'),
                        value: 'client',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('مصورة'),
                        value: 'photographer',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Password Field
                CustomTextField(
                  label: AppStrings.password,
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
                // Confirm Password Field
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
                // Register Button
                Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);

                    return CustomButton(
                      text: AppStrings.register,
                      isLoading: authState.isLoading,
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                // تنظيف رقم الهاتف وإضافة كود الدولة
                                final cleanPhone = _phoneController.text
                                    .trim()
                                    .replaceAll(RegExp(r'[^\d]'), '');
                                final fullPhone = '+967$cleanPhone';

                                // Call register
                                await ref
                                    .read(authProvider.notifier)
                                    .register(
                                      name: _nameController.text.trim(),
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                      phone: fullPhone,
                                      role: _selectedRole,
                                    );

                                // Check if registered successfully
                                if (!mounted) return;
                                
                                final state = ref.read(authProvider);
                                if (state.isAuthenticated) {
                                  // Navigate based on role
                                  if (state.user?.role == 'photographer') {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/photographer-dashboard',
                                      (route) => false,
                                    );
                                  } else {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/home',
                                      (route) => false,
                                    );
                                  }
                                } else if (state.errorInfo != null) {
                                  _handleError(context, state.errorInfo!);
                                }
                              }
                            },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل؟',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(AppStrings.login),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
