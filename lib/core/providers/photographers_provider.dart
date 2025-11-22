import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/data/mock_data.dart';

// Provider للمصورات
final photographersProvider = StateNotifierProvider<PhotographersNotifier, PhotographersState>((ref) {
  return PhotographersNotifier();
});

// State للمصورات
class PhotographersState {
  final List<Map<String, dynamic>> photographers;
  final List<Map<String, dynamic>> filteredPhotographers;
  final bool isLoading;
  final String? error;
  final String selectedCategory;
  final String searchQuery;
  final String sortBy; // rating, price_low, price_high, reviews
  final double? minPrice;
  final double? maxPrice;
  final String? selectedCity;

  PhotographersState({
    required this.photographers,
    required this.filteredPhotographers,
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'الكل',
    this.searchQuery = '',
    this.sortBy = 'rating',
    this.minPrice,
    this.maxPrice,
    this.selectedCity,
  });

  PhotographersState copyWith({
    List<Map<String, dynamic>>? photographers,
    List<Map<String, dynamic>>? filteredPhotographers,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    String? selectedCity,
  }) {
    return PhotographersState(
      photographers: photographers ?? this.photographers,
      filteredPhotographers: filteredPhotographers ?? this.filteredPhotographers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedCity: selectedCity ?? this.selectedCity,
    );
  }
}

// Notifier للمصورات
class PhotographersNotifier extends StateNotifier<PhotographersState> {
  PhotographersNotifier()
      : super(PhotographersState(
          photographers: [],
          filteredPhotographers: [],
        )) {
    loadPhotographers();
  }

  // تحميل المصورات
  Future<void> loadPhotographers() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(milliseconds: 500));
      
      final photographers = List<Map<String, dynamic>>.from(MockData.photographers);
      
      state = state.copyWith(
        photographers: photographers,
        filteredPhotographers: photographers,
        isLoading: false,
      );
      
      // تطبيق الفلاتر
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ في تحميل البيانات',
      );
    }
  }

  // البحث
  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  // تغيير الفئة
  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  // تغيير الترتيب
  void sortBy(String sortType) {
    state = state.copyWith(sortBy: sortType);
    _applyFilters();
  }

  // فلتر السعر
  void filterByPrice(double? min, double? max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
    _applyFilters();
  }

  // فلتر المدينة
  void filterByCity(String? city) {
    state = state.copyWith(selectedCity: city);
    _applyFilters();
  }

  // إعادة تعيين الفلاتر
  void resetFilters() {
    state = state.copyWith(
      selectedCategory: 'الكل',
      searchQuery: '',
      sortBy: 'rating',
      minPrice: null,
      maxPrice: null,
      selectedCity: null,
    );
    _applyFilters();
  }

  // تطبيق الفلاتر
  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(state.photographers);

    // فلتر البحث
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = p['name'].toString().toLowerCase();
        final specialty = p['specialty'].toString().toLowerCase();
        final query = state.searchQuery.toLowerCase();
        return name.contains(query) || specialty.contains(query);
      }).toList();
    }

    // فلتر الفئة
    if (state.selectedCategory != 'الكل') {
      filtered = filtered.where((p) {
        final categories = p['categories'] as List<dynamic>;
        return categories.any((c) => c.toString().contains(state.selectedCategory));
      }).toList();
    }

    // فلتر السعر
    if (state.minPrice != null) {
      filtered = filtered.where((p) {
        return p['minPrice'] >= state.minPrice!;
      }).toList();
    }
    if (state.maxPrice != null) {
      filtered = filtered.where((p) {
        return p['maxPrice'] <= state.maxPrice!;
      }).toList();
    }

    // فلتر المدينة
    if (state.selectedCity != null && state.selectedCity!.isNotEmpty) {
      filtered = filtered.where((p) {
        return p['city'] == state.selectedCity;
      }).toList();
    }

    // الترتيب
    switch (state.sortBy) {
      case 'rating':
        filtered.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'price_low':
        filtered.sort((a, b) => (a['minPrice'] as int).compareTo(b['minPrice'] as int));
        break;
      case 'price_high':
        filtered.sort((a, b) => (b['maxPrice'] as int).compareTo(a['maxPrice'] as int));
        break;
      case 'reviews':
        filtered.sort((a, b) => (b['reviewCount'] as int).compareTo(a['reviewCount'] as int));
        break;
    }

    state = state.copyWith(filteredPhotographers: filtered);
  }

  // الحصول على مصورة بالـ ID
  Map<String, dynamic>? getPhotographerById(String id) {
    try {
      return state.photographers.firstWhere((p) => p['id'] == id);
    } catch (e) {
      return null;
    }
  }
}

// Provider للمصورات المميزة
final featuredPhotographersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final state = ref.watch(photographersProvider);
  return state.photographers.where((p) => p['isFeatured'] == true).toList();
});

// Provider للفئات
final categoriesProvider = Provider<List<Map<String, String>>>((ref) {
  return MockData.categories;
});
