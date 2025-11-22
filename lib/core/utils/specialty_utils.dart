class SpecialtyUtils {
  static String format(List<String> specialties) {
    if (specialties.isEmpty) return 'مصورة';

    final first = translate(specialties.first);
    if (specialties.length > 1) {
      return '$first +${specialties.length - 1}';
    }
    return first;
  }

  static String translate(String specialty) {
    // Mappings from complete_profile_page.dart (Backend -> Arabic)
    final Map<String, String> backendMappings = {
      'weddings': 'تصوير الأعراس',
      'events': 'تصوير المناسبات',
      'children': 'تصوير الأطفال',
      'portraits': 'تصوير العائلات', // Backend maps 'portraits' to Family!
      'products': 'تصوير المنتجات',
      'fashion': 'تصوير الأزياء',
    };

    // Check exact backend match first (case-insensitive)
    for (final key in backendMappings.keys) {
      if (key.toLowerCase() == specialty.toLowerCase()) {
        return backendMappings[key]!;
      }
    }

    // Fallback / Extended mappings for other potential values
    final Map<String, String> extendedMappings = {
      'Wedding': 'تصوير الأعراس',
      'Portrait': 'بورتريه',
      'Family': 'تصوير العائلات',
      'Food': 'تصوير الأطعمة',
      'Foods': 'تصوير الأطعمة',
      'Baby': 'تصوير الأطفال',
      'Babies': 'تصوير الأطفال',
      'Travel': 'تصوير السفر',
      'Nature': 'تصوير الطبيعة',
      'Architecture': 'تصوير معماري',
      'Sports': 'تصوير رياضي',
      'Sport': 'تصوير رياضي',
      'Art': 'تصوير فني',
      'Arts': 'تصوير فني',
      'Commercial': 'تصوير تجاري',
      'Studio': 'تصوير ستوديو',
      'Lifestyle': 'لايف ستايل',
      'Maternity': 'تصوير حوامل',
      'Newborn': 'تصوير مواليد',
      'Graduation': 'تصوير تخرج',
      'Interior': 'ديكور داخلي',
      'Aerial': 'تصوير جوي',
      'Videography': 'فيديو',
    };

    // Check extended mappings
    for (final key in extendedMappings.keys) {
      if (key.toLowerCase() == specialty.toLowerCase()) {
        return extendedMappings[key]!;
      }
    }

    // Try removing 's' at the end if not found
    if (specialty.toLowerCase().endsWith('s')) {
      final singular = specialty.substring(0, specialty.length - 1);
      // Check backend mappings again with singular
      for (final key in backendMappings.keys) {
        if (key.toLowerCase() == singular.toLowerCase()) {
          return backendMappings[key]!;
        }
      }
      // Check extended mappings again with singular
      for (final key in extendedMappings.keys) {
        if (key.toLowerCase() == singular.toLowerCase()) {
          return extendedMappings[key]!;
        }
      }
    }

    return specialty;
  }
}
