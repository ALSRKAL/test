# نظام التنقل الرئيسي (Main Navigation)

## كيفية التنقل بين الصفحات

### 1. التنقل التلقائي (عبر Bottom Navigation Bar)
فقط اضغط على الأيقونات في الشريط السفلي:
- 🏠 الرئيسية
- 📅 حجوزاتي
- 💬 المحادثات
- 👤 الملف الشخصي

### 2. التنقل البرمجي (من داخل الكود)

#### استخدام الـ Provider:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/features/main/presentation/providers/navigation_provider.dart';

// في أي ConsumerWidget أو ConsumerStatefulWidget:

// التنقل إلى صفحة معينة بالرقم (0-3)
ref.read(navigationProvider.notifier).navigateTo(1);

// أو استخدام الدوال المخصصة:
ref.read(navigationProvider.notifier).goToHome();      // الصفحة الرئيسية
ref.read(navigationProvider.notifier).goToBookings();  // الحجوزات
ref.read(navigationProvider.notifier).goToChats();     // المحادثات
ref.read(navigationProvider.notifier).goToProfile();   // الملف الشخصي
```

#### مثال عملي:

```dart
// في أي صفحة، بعد إتمام عملية معينة:
ElevatedButton(
  onPressed: () {
    // بعد إنشاء حجز، انتقل لصفحة الحجوزات
    ref.read(navigationProvider.notifier).goToBookings();
  },
  child: const Text('عرض حجوزاتي'),
)
```

### 3. الحصول على الصفحة الحالية

```dart
// للحصول على رقم الصفحة الحالية:
final currentPage = ref.watch(navigationProvider);

// للتحقق من صفحة معينة:
if (currentPage == 0) {
  // نحن في الصفحة الرئيسية
}
```

## الصفحات المتاحة

| الرقم | الصفحة | الوصف |
|------|--------|-------|
| 0 | HomePage | الصفحة الرئيسية - عرض المصورات |
| 1 | MyBookingsPage | صفحة الحجوزات |
| 2 | ConversationsListPage | صفحة المحادثات |
| 3 | UserProfilePage | صفحة الملف الشخصي |

## ملاحظات مهمة

- ✅ التنقل سلس مع animation
- ✅ الصفحات تبقى محملة (لا يتم إعادة تحميلها)
- ✅ التحديد الصحيح للصفحة النشطة
- ✅ لا يتأثر بـ hot reload
- ✅ يدعم الـ badge للإشعارات (المحادثات)
