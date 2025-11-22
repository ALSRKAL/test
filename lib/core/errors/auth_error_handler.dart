import 'dart:io';
import 'package:dio/dio.dart';
import 'auth_error_type.dart';
import '../utils/error_handler.dart';

/// معالج الأخطاء الذكي للمصادقة
/// يستخدم ErrorHandler العام ويضيف معلومات إضافية للمصادقة
class AuthErrorHandler {
  /// تحليل الخطأ وتحويله إلى معلومات مفهومة
  static AuthErrorInfo handleError(dynamic error) {
    // الحصول على رسالة الخطأ من ErrorHandler العام
    final errorMessage = ErrorHandler.getErrorMessage(error);
    
    // تحديد نوع الخطأ وإضافة معلومات إضافية
    return _parseErrorMessage(errorMessage, error);
  }

  /// تحليل رسالة الخطأ وتحديد النوع والإجراءات
  static AuthErrorInfo _parseErrorMessage(String message, dynamic originalError) {
    final lowerMessage = message.toLowerCase();

    // التحقق من نوع الخطأ الأصلي
    AuthErrorType errorType = AuthErrorType.unknown;
    
    // أخطاء الشبكة
    if (originalError is SocketException ||
        (originalError is DioException && 
         originalError.type == DioExceptionType.connectionError)) {
      errorType = AuthErrorType.noInternet;
    } else if (originalError is DioException) {
      final statusCode = originalError.response?.statusCode;
      
      // تحديد نوع الخطأ بناءً على كود الحالة
      if (statusCode != null) {
        if (statusCode >= 500) {
          errorType = AuthErrorType.serverError;
        } else if (statusCode == 408 || 
                   originalError.type == DioExceptionType.connectionTimeout ||
                   originalError.type == DioExceptionType.sendTimeout ||
                   originalError.type == DioExceptionType.receiveTimeout) {
          errorType = AuthErrorType.timeout;
        }
      }
    }



    // تحليل محتوى الرسالة لتحديد النوع والإجراءات
    
    // المستخدم موجود بالفعل (من الباك اند: "Email already registered")
    if (lowerMessage.contains('مسجل مسبقاً') ||
        lowerMessage.contains('استخدام بريد آخر')) {
      return AuthErrorInfo(
        type: AuthErrorType.userAlreadyExists,
        title: 'الحساب موجود بالفعل',
        message: 'هذا البريد الإلكتروني مسجل مسبقاً. هل تريد تسجيل الدخول؟',
        actionText: 'تسجيل الدخول',
      );
    }

    // بيانات الدخول غير صحيحة (من الباك اند: "Invalid credentials")
    if (lowerMessage.contains('البريد الإلكتروني أو كلمة المرور غير صحيحة')) {
      return AuthErrorInfo(
        type: AuthErrorType.wrongPassword,
        title: 'بيانات الدخول غير صحيحة',
        message: message,
        actionText: 'نسيت كلمة المرور',
      );
    }

    // المستخدم غير موجود
    if (lowerMessage.contains('لا يوجد حساب')) {
      return AuthErrorInfo(
        type: AuthErrorType.userNotFound,
        title: 'الحساب غير موجود',
        message: message,
        actionText: 'إنشاء حساب',
      );
    }

    // الحساب محظور (من الباك اند: "Your account has been blocked")
    if (lowerMessage.contains('تم حظر حسابك') ||
        lowerMessage.contains('محظور')) {
      return AuthErrorInfo(
        type: AuthErrorType.accountBlocked,
        title: 'الحساب محظور',
        message: message,
      );
    }

    // لا يوجد اتصال بالإنترنت
    if (errorType == AuthErrorType.noInternet ||
        lowerMessage.contains('لا يوجد اتصال بالإنترنت')) {
      return AuthErrorInfo(
        type: AuthErrorType.noInternet,
        title: 'لا يوجد اتصال بالإنترنت',
        message: message,
      );
    }

    // اتصال ضعيف
    if (lowerMessage.contains('فشل الاتصال')) {
      return AuthErrorInfo(
        type: AuthErrorType.poorConnection,
        title: 'مشكلة في الاتصال',
        message: message,
      );
    }

    // انتهت مهلة الاتصال
    if (errorType == AuthErrorType.timeout ||
        lowerMessage.contains('انتهت مهلة')) {
      return AuthErrorInfo(
        type: AuthErrorType.timeout,
        title: 'انتهت مهلة الاتصال',
        message: message,
      );
    }

    // خطأ في الخادم
    if (errorType == AuthErrorType.serverError ||
        lowerMessage.contains('خلل في الخادم') ||
        lowerMessage.contains('غير متاحة حالياً')) {
      return AuthErrorInfo(
        type: AuthErrorType.serverError,
        title: 'الخادم قيد الصيانة',
        message: message,
      );
    }

    // البريد الإلكتروني غير صحيح
    if (lowerMessage.contains('بريد إلكتروني صحيح')) {
      return AuthErrorInfo(
        type: AuthErrorType.invalidEmail,
        title: 'البريد الإلكتروني غير صحيح',
        message: message,
      );
    }

    // كلمة المرور ضعيفة
    if (lowerMessage.contains('كلمة المرور قصيرة') ||
        lowerMessage.contains('6 أحرف على الأقل')) {
      return AuthErrorInfo(
        type: AuthErrorType.weakPassword,
        title: 'كلمة المرور ضعيفة',
        message: message,
      );
    }

    // خطأ غير معروف - عرض الرسالة من ErrorHandler
    return AuthErrorInfo(
      type: errorType,
      title: 'حدث خطأ',
      message: message,
    );
  }
}
