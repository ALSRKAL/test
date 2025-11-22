/// أنواع الأخطاء المختلفة في المصادقة
enum AuthErrorType {
  /// المستخدم موجود بالفعل
  userAlreadyExists,

  /// المستخدم غير موجود
  userNotFound,

  /// كلمة المرور خاطئة
  wrongPassword,

  /// البريد الإلكتروني غير صحيح
  invalidEmail,

  /// كلمة المرور ضعيفة
  weakPassword,

  /// لا يوجد اتصال بالإنترنت
  noInternet,

  /// اتصال ضعيف بالإنترنت
  poorConnection,

  /// خطأ في الخادم (صيانة)
  serverError,

  /// انتهت مهلة الطلب
  timeout,

  /// الحساب محظور
  accountBlocked,

  /// الحساب غير مفعل
  accountNotVerified,

  /// خطأ غير معروف
  unknown,
}

/// معلومات الخطأ
class AuthErrorInfo {
  final AuthErrorType type;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? action;

  const AuthErrorInfo({
    required this.type,
    required this.title,
    required this.message,
    this.actionText,
    this.action,
  });
}

typedef VoidCallback = void Function();
