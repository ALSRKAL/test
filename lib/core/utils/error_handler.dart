import 'package:dio/dio.dart';
import 'dart:io';

class ErrorHandler {
  /// تحويل الأخطاء إلى رسائل عربية احترافية
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    } else if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      return _translateErrorMessage(message);
    } else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  /// معالجة أخطاء Dio
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة إرسال البيانات. يرجى المحاولة مرة أخرى.';

      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة استقبال البيانات. يرجى المحاولة مرة أخرى.';

      case DioExceptionType.badCertificate:
        return 'خطأ في شهادة الأمان. يرجى التواصل مع الدعم الفني.';

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return 'تم إلغاء العملية.';

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
        }
        return 'فشل الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.';

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
        }
        return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  /// معالجة أخطاء الاستجابة من الخادم
  static String _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // محاولة الحصول على رسالة الخطأ من الخادم
    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      serverMessage = responseData['message'] as String?;
    }

    // معالجة خاصة لرسالة "Too many login attempts"
    if (serverMessage != null &&
        serverMessage.toLowerCase().contains('too many login attempts')) {
      return _extractRateLimitMessage(serverMessage);
    }

    switch (statusCode) {
      case 400:
        return _translateErrorMessage(
          serverMessage ??
              'البيانات المدخلة غير صحيحة. يرجى التحقق والمحاولة مرة أخرى.',
        );

      case 401:
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

      case 403:
        return 'ليس لديك صلاحية للوصول إلى هذه الخدمة.';

      case 404:
        return 'الخدمة المطلوبة غير موجودة. يرجى التواصل مع الدعم الفني.';

      case 408:
        return 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.';

      case 429:
        return _translateErrorMessage(
          serverMessage ??
              'تم تجاوز عدد المحاولات المسموح بها. يرجى الانتظار قليلاً والمحاولة مرة أخرى.',
        );

      case 500:
        return 'عذراً، يوجد خلل في الخادم حالياً. نعمل على إصلاحه، يرجى المحاولة لاحقاً.';

      case 502:
        return 'الخادم غير متاح حالياً. يرجى المحاولة بعد قليل.';

      case 503:
        return 'الخدمة غير متاحة حالياً بسبب صيانة. يرجى المحاولة لاحقاً.';

      case 504:
        return 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.';

      default:
        if (statusCode != null && statusCode >= 500) {
          return 'عذراً، يوجد خلل في الخادم حالياً. نعمل على إصلاحه، يرجى المحاولة لاحقاً.';
        }
        return _translateErrorMessage(
          serverMessage ?? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
        );
    }
  }

  /// استخراج وترجمة رسالة تجاوز عدد المحاولات مع الوقت المتبقي
  static String _extractRateLimitMessage(String message) {
    // البحث عن الوقت في الرسالة
    // مثال: "Too many login attempts, please try again after 15 minutes"

    final minutesMatch = RegExp(r'(\d+)\s*minute').firstMatch(message);
    final hoursMatch = RegExp(r'(\d+)\s*hour').firstMatch(message);
    final secondsMatch = RegExp(r'(\d+)\s*second').firstMatch(message);

    if (minutesMatch != null) {
      final minutes = minutesMatch.group(1);
      return 'تم تجاوز عدد المحاولات المسموح بها.\nيرجى المحاولة مرة أخرى بعد $minutes دقيقة.';
    } else if (hoursMatch != null) {
      final hours = hoursMatch.group(1);
      return 'تم تجاوز عدد المحاولات المسموح بها.\nيرجى المحاولة مرة أخرى بعد $hours ساعة.';
    } else if (secondsMatch != null) {
      final seconds = secondsMatch.group(1);
      return 'تم تجاوز عدد المحاولات المسموح بها.\nيرجى المحاولة مرة أخرى بعد $seconds ثانية.';
    }

    // إذا لم نجد وقت محدد
    return 'تم تجاوز عدد المحاولات المسموح بها.\nيرجى الانتظار قليلاً والمحاولة مرة أخرى.';
  }

  /// ترجمة رسائل الأخطاء الشائعة من الإنجليزية إلى العربية
  static String _translateErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    // أخطاء تجاوز عدد المحاولات
    if (lowerMessage.contains('too many') &&
        (lowerMessage.contains('attempt') ||
            lowerMessage.contains('request'))) {
      return _extractRateLimitMessage(message);
    }

    // أخطاء الشبكة
    if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection') ||
        lowerMessage.contains('internet')) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    }

    // أخطاء رموز التحقق
    if (lowerMessage.contains('invalid code') ||
        lowerMessage.contains('invalid verification code') ||
        lowerMessage.contains('wrong code') ||
        lowerMessage.contains('incorrect code')) {
      return 'رمز التحقق غير صحيح. يرجى التحقق من الرمز والمحاولة مرة أخرى.';
    }

    if (lowerMessage.contains('code expired') ||
        lowerMessage.contains('verification code expired') ||
        lowerMessage.contains('expired code')) {
      return 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.';
    }

    if (lowerMessage.contains('code not found') ||
        lowerMessage.contains('no verification code')) {
      return 'لم يتم العثور على رمز التحقق. يرجى طلب رمز جديد.';
    }

    if (lowerMessage.contains('invalid or expired')) {
      if (lowerMessage.contains('reset code') || lowerMessage.contains('code')) {
        return 'رمز التحقق غير صحيح أو منتهي الصلاحية. يرجى طلب رمز جديد.';
      }
    }

    if (lowerMessage.contains('reset code') && lowerMessage.contains('invalid')) {
      return 'رمز إعادة تعيين كلمة المرور غير صحيح.';
    }

    if (lowerMessage.contains('reset code') && lowerMessage.contains('expired')) {
      return 'انتهت صلاحية رمز إعادة تعيين كلمة المرور. يرجى طلب رمز جديد.';
    }

    if (lowerMessage.contains('please provide email and code')) {
      return 'الرجاء إدخال البريد الإلكتروني ورمز التحقق.';
    }

    if (lowerMessage.contains('no user found with this email')) {
      return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
    }

    if (lowerMessage.contains('your account has been blocked')) {
      return 'تم حظر حسابك. يرجى التواصل مع الدعم الفني.';
    }

    if (lowerMessage.contains('password reset code sent')) {
      return 'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.';
    }

    // أخطاء المصادقة
    if (lowerMessage.contains('invalid credentials') ||
        lowerMessage.contains('wrong password') ||
        lowerMessage.contains('incorrect password')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }

    if (lowerMessage.contains('user not found') ||
        lowerMessage.contains('no user found') ||
        lowerMessage.contains('account not found')) {
      return 'لا يوجد حساب بهذا البريد الإلكتروني.';
    }

    if (lowerMessage.contains('email already exists') ||
        lowerMessage.contains('email is already registered')) {
      return 'البريد الإلكتروني مسجل مسبقاً. يرجى استخدام بريد آخر أو تسجيل الدخول.';
    }

    if (lowerMessage.contains('account blocked') ||
        lowerMessage.contains('account disabled')) {
      return 'تم حظر حسابك. يرجى التواصل مع الدعم الفني.';
    }

    // أخطاء التحقق من البيانات
    if (lowerMessage.contains('invalid email') ||
        lowerMessage.contains('valid email') ||
        lowerMessage.contains('provide a valid email')) {
      return 'الرجاء إدخال بريد إلكتروني صحيح.';
    }

    if (lowerMessage.contains('password too short') ||
        lowerMessage.contains('password must be') ||
        lowerMessage.contains('password is required')) {
      return 'كلمة المرور قصيرة جداً. يجب أن تكون 6 أحرف على الأقل.';
    }

    if (lowerMessage.contains('invalid phone') ||
        lowerMessage.contains('valid phone number') ||
        lowerMessage.contains('provide a valid phone')) {
      return 'الرجاء إدخال رقم هاتف صحيح.';
    }

    if (lowerMessage.contains('name is required') ||
        lowerMessage.contains('provide a name') ||
        lowerMessage.contains('name cannot be empty')) {
      return 'الرجاء إدخال الاسم.';
    }

    if (lowerMessage.contains('email is required') ||
        lowerMessage.contains('provide an email')) {
      return 'الرجاء إدخال البريد الإلكتروني.';
    }

    if (lowerMessage.contains('phone is required') ||
        lowerMessage.contains('provide a phone')) {
      return 'الرجاء إدخال رقم الهاتف.';
    }

    if (lowerMessage.contains('all fields are required') ||
        lowerMessage.contains('required fields')) {
      return 'الرجاء ملء جميع الحقول المطلوبة.';
    }

    // أخطاء الخادم
    if (lowerMessage.contains('server error') ||
        lowerMessage.contains('internal server') ||
        lowerMessage.contains('500')) {
      return 'عذراً، يوجد خلل في الخادم حالياً. نعمل على إصلاحه، يرجى المحاولة لاحقاً.';
    }

    if (lowerMessage.contains('service unavailable') ||
        lowerMessage.contains('503')) {
      return 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.';
    }

    if (lowerMessage.contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';
    }

    // إذا لم يتم التعرف على الخطأ، نعيد الرسالة الأصلية إذا كانت مفهومة
    // أو رسالة عامة إذا كانت تقنية
    if (message.length < 100 &&
        !message.contains('Exception') &&
        !message.contains('Error')) {
      return message;
    }

    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }

  /// التحقق من وجود اتصال بالإنترنت
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
