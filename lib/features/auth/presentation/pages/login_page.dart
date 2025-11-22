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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true; // Default to true

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleError(BuildContext context, AuthErrorInfo errorInfo) {
    AuthErrorDialog.show(
      context,
      errorInfo,
      onActionPressed: () {
        // معالجة الإجراءات المختلفة
        switch (errorInfo.type) {
          case AuthErrorType.userNotFound:
            // الانتقال إلى صفحة التسجيل
            Navigator.pushNamed(context, '/register');
            break;
          case AuthErrorType.wrongPassword:
            // الانتقال إلى صفحة نسيان كلمة المرور
            Navigator.pushNamed(context, '/forgot-password');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                // Logo
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'مرحباً بك مرة أخرى',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
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
                    return null;
                  },
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
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? true;
                            });
                          },
                          activeColor: AppColors.primaryGradientStart,
                        ),
                        Text(
                          'تذكرني',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Login Button
                Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);

                    return CustomButton(
                      text: AppStrings.login,
                      isLoading: authState.isLoading,
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                // Call login with remember me option
                                await ref
                                    .read(authProvider.notifier)
                                    .login(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                      rememberMe: _rememberMe,
                                    );

                                // Check if logged in successfully
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
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(AppStrings.register),
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
