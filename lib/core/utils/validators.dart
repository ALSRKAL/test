import 'package:hajzy/core/constants/app_constants.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'كلمة المرور يجب أن تكون ${AppConstants.minPasswordLength} أحرف على الأقل';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'كلمة المرور يجب أن تكون ${AppConstants.maxPasswordLength} حرف كحد أقصى';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل';
    }

    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال الاسم';
    }

    if (value.length < AppConstants.minNameLength) {
      return 'الاسم يجب أن يكون ${AppConstants.minNameLength} أحرف على الأقل';
    }

    if (value.length > AppConstants.maxNameLength) {
      return 'الاسم يجب أن يكون ${AppConstants.maxNameLength} حرف كحد أقصى';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }

    final phoneRegex = RegExp(r'^(05|5)[0-9]{8}$');

    if (!phoneRegex.hasMatch(value)) {
      return 'رقم الهاتف غير صحيح';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال $fieldName';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'الرجاء تأكيد كلمة المرور';
    }

    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }

    return null;
  }
}
