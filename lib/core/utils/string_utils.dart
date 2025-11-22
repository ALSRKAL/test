class StringUtils {
  /// Normalizes Arabic city names to handle common variations and misspellings.
  /// This helps in deduplicating cities in lists.
  static String normalizeArabicCity(String city) {
    if (city.isEmpty) return city;

    String normalized = city.trim();

    // Remove common prefixes/suffixes if needed (optional, but keeping it simple for now)

    // Normalize Alef variations (أ, إ, آ -> ا)
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا');

    // Normalize Taa Marbuta (ة -> ه) - often interchangeable in search/display
    // actually, for display we might want to keep it, but for grouping we need a standard.
    // Let's standardise to 'ة' if it ends with 'ه' and looks like a city,
    // but safer is to just treat them as same for comparison.
    // However, the requirement is to display one version.
    // Let's try to map common variations to a canonical form.

    // Common City Mappings
    if (_isSimilar(normalized, 'صنعاء')) return 'صنعاء';
    if (_isSimilar(normalized, 'عدن')) return 'عدن';
    if (_isSimilar(normalized, 'تعز')) return 'تعز';
    if (_isSimilar(normalized, 'المكلا')) return 'المكلا';
    if (_isSimilar(normalized, 'الحديدة')) return 'الحديدة';
    if (_isSimilar(normalized, 'إب') || _isSimilar(normalized, 'اب'))
      return 'إب';
    if (_isSimilar(normalized, 'ذمار')) return 'ذمار';
    if (_isSimilar(normalized, 'حجة')) return 'حجة';
    if (_isSimilar(normalized, 'سيئون')) return 'سيئون';
    if (_isSimilar(normalized, 'عمران')) return 'عمران';
    if (_isSimilar(normalized, 'صعدة')) return 'صعدة';
    if (_isSimilar(normalized, 'الضالع')) return 'الضالع';
    if (_isSimilar(normalized, 'المحويت')) return 'المحويت';
    if (_isSimilar(normalized, 'المهرة')) return 'المهرة';
    if (_isSimilar(normalized, 'حضرموت')) return 'حضرموت';
    if (_isSimilar(normalized, 'مأرب') || _isSimilar(normalized, 'مارب'))
      return 'مأرب';
    if (_isSimilar(normalized, 'البيضاء')) return 'البيضاء';
    if (_isSimilar(normalized, 'ريمة')) return 'ريمة';
    if (_isSimilar(normalized, 'سقطرى')) return 'سقطرى';
    if (_isSimilar(normalized, 'لحج')) return 'لحج';
    if (_isSimilar(normalized, 'أبين') || _isSimilar(normalized, 'ابين'))
      return 'أبين';
    if (_isSimilar(normalized, 'الجوف')) return 'الجوف';
    if (_isSimilar(normalized, 'شبوة')) return 'شبوة';

    // Saudi Cities (if applicable)
    if (_isSimilar(normalized, 'الرياض')) return 'الرياض';
    if (_isSimilar(normalized, 'جدة')) return 'جدة';
    if (_isSimilar(normalized, 'مكة') || _isSimilar(normalized, 'مكه'))
      return 'مكة';
    if (_isSimilar(normalized, 'المدينة')) return 'المدينة المنورة';
    if (_isSimilar(normalized, 'الدمام')) return 'الدمام';

    return city; // Return original if no match found, but maybe cleaned up a bit?
  }

  static bool _isSimilar(String input, String target) {
    // Normalize both for comparison
    String normInput = _basicNormalize(input);
    String normTarget = _basicNormalize(target);

    if (normInput == normTarget) return true;

    // Check for common typos
    // e.g. صنعا vs صنعاء
    if (normTarget.endsWith('اء') &&
        normInput == normTarget.substring(0, normTarget.length - 1))
      return true; // صنعا -> صنعاء
    if (normTarget.endsWith('اء') &&
        normInput == normTarget.substring(0, normTarget.length - 1) + 'ى')
      return true; // صنعاى -> صنعاء
    if (normTarget.endsWith('ة') &&
        normInput == normTarget.replaceAll('ة', 'ه'))
      return true; // مكه -> مكة

    return false;
  }

  static String _basicNormalize(String text) {
    return text
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }
}
