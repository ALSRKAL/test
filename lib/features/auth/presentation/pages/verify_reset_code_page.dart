import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/core/constants/api_endpoints.dart';
import 'package:hajzy/core/utils/error_handler.dart';

class VerifyResetCodePage extends StatefulWidget {
  final String email;

  const VerifyResetCodePage({super.key, required this.email});

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _pinController.text;
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال الرمز كاملاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiEndpoints.verifyResetCode,
        data: {
          'email': widget.email,
          'code': code,
        },
      );

      if (!mounted) return;

      if (response.data['success']) {
        Navigator.pushReplacementNamed(
          context,
          '/reset-password',
          arguments: {
            'email': widget.email,
            'code': code,
          },
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

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      await apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': widget.email},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رمز جديد'),
          backgroundColor: Colors.green,
        ),
      );
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
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryGradientStart, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryGradientStart, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryGradientStart.withValues(alpha: 0.05),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الرمز'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // أيقونة
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGradientStart.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 50,
                  color: AppColors.primaryGradientStart,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // العنوان
              Text(
                'أدخل رمز التحقق',
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
                'تم إرسال رمز مكون من 6 أرقام إلى\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              
              // حقل الرمز باستخدام Pinput
              Directionality(
                textDirection: TextDirection.ltr,
                child: Pinput(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  length: 6,
                  autofocus: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  errorPinTheme: errorPinTheme,
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  showCursor: true,
                  cursor: Container(
                    width: 2,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGradientStart,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  onCompleted: (pin) {
                    // Auto verify when complete
                    _verifyCode();
                  },
                  keyboardType: TextInputType.number,
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                  closeKeyboardWhenCompleted: false,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // زر التحقق
              CustomButton(
                text: 'تحقق من الرمز',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _verifyCode,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // إعادة إرسال الرمز
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'لم يصلك الرمز؟',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _resendCode,
                    child: const Text('إعادة الإرسال'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
