import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/photographer.dart';
import '../../domain/usecases/get_photographers_usecase.dart';
import '../../domain/usecases/get_photographer_details_usecase.dart';
import '../../domain/usecases/search_photographers_usecase.dart';
import '../../data/repositories/photographer_repository_impl.dart';
import '../../data/datasources/photographer_remote_datasource.dart';
import '../../data/datasources/photographer_local_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/string_utils.dart';

// Photographers State
class PhotographersState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<Photographer> photographers;
  final Photographer? selectedPhotographer;
  final int currentPage;
  final bool hasMore;

  const PhotographersState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.photographers = const [],
    this.selectedPhotographer,
    this.currentPage = 1,
    this.hasMore = true,
  });

  PhotographersState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<Photographer>? photographers,
    Photographer? selectedPhotographer,
    int? currentPage,
    bool? hasMore,
  }) {
    return PhotographersState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      photographers: photographers ?? this.photographers,
      selectedPhotographer: selectedPhotographer ?? this.selectedPhotographer,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Photographers Notifier
class PhotographersNotifier extends StateNotifier<PhotographersState> {
  final GetPhotographersUseCase getPhotographersUseCase;
  final GetPhotographerDetailsUseCase getPhotographerDetailsUseCase;
  final SearchPhotographersUseCase searchPhotographersUseCase;

  PhotographersNotifier({
    required this.getPhotographersUseCase,
    required this.getPhotographerDetailsUseCase,
    required this.searchPhotographersUseCase,
  }) : super(const PhotographersState());

  Future<void> getPhotographers({
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    bool refresh = false,
  }) async {
    print('📸 DEBUG PhotographersProvider: getPhotographers called');
    print('  - refresh: $refresh');
    print('  - location: $location');
    print('  - minPrice: $minPrice');
    print('  - maxPrice: $maxPrice');

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        photographers: [],
      );
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      print('📸 DEBUG: Calling getPhotographersUseCase...');
      final photographers = await getPhotographersUseCase.call(
        page: state.currentPage,
        limit: 10,
        city: location,
        minRating: minPrice,
        featured: false,
      );

      print('📸 DEBUG: Received ${photographers.length} photographers');

      final updatedList = refresh
          ? photographers
          : [...state.photographers, ...photographers];

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        photographers: updatedList,
        currentPage: state.currentPage + 1,
        hasMore: photographers.length >= 10,
      );

      print('📸 DEBUG: State updated successfully');
      print('  - Total photographers: ${state.photographers.length}');
      print('  - hasMore: ${state.hasMore}');
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error getting photographers: $e');
      print('StackTrace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> getPhotographerDetails(
    String id, {
    bool forceRefresh = false,
  }) async {
    // إذا كانت البيانات موجودة ولم يطلب تحديث قسري، لا نحمل مرة أخرى
    if (!forceRefresh &&
        state.selectedPhotographer != null &&
        state.selectedPhotographer!.id == id) {
      print('📸 DEBUG: Using cached photographer details for $id');
      return;
    }

    // مسح البيانات القديمة إذا كان المصور مختلف
    if (state.selectedPhotographer != null &&
        state.selectedPhotographer!.id != id) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        selectedPhotographer: null, // مسح البيانات القديمة
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final photographer = await getPhotographerDetailsUseCase.call(id);
      state = state.copyWith(
        isLoading: false,
        selectedPhotographer: photographer,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getMyPhotographerProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use a special endpoint to get current photographer profile
      final photographer = await getPhotographerDetailsUseCase.call(
        'me/profile',
      );
      state = state.copyWith(
        isLoading: false,
        selectedPhotographer: photographer,
      );
    } on PhotographerProfileNotFoundException {
      // If profile not found, set photographer to null without error
      // This is expected for new photographers who haven't created profile yet
      state = state.copyWith(
        isLoading: false,
        selectedPhotographer: null,
        error: null, // Don't show error for profile not found
      );
    } catch (e) {
      // For other errors, show the error message
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBlockedDates(List<DateTime> blockedDates) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call repository to update blocked dates
      final photographer = state.selectedPhotographer;
      if (photographer == null) {
        throw Exception('No photographer profile found');
      }

      // Update via API
      await getPhotographerDetailsUseCase.repository.updateBlockedDates(
        blockedDates,
      );

      // Update local state
      final updatedPhotographer = Photographer(
        id: photographer.id,
        userId: photographer.userId,
        name: photographer.name,
        email: photographer.email,
        avatar: photographer.avatar,
        bio: photographer.bio,
        specialties: photographer.specialties,
        location: photographer.location,
        portfolio: photographer.portfolio,
        packages: photographer.packages,
        rating: photographer.rating,
        subscription: photographer.subscription,
        featured: photographer.featured,
        verification: photographer.verification,
        availability: Availability(blockedDates: blockedDates),
        isVerified: photographer.isVerified,
        stats: photographer.stats,
      );

      state = state.copyWith(
        isLoading: false,
        selectedPhotographer: updatedPhotographer,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> submitVerification({
    required String idCardUrl,
    required List<String> portfolioSamples,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final photographer = state.selectedPhotographer;
      if (photographer == null) {
        throw Exception('No photographer profile found');
      }

      await getPhotographerDetailsUseCase.repository.submitVerification(
        photographerId: photographer.id,
        idCardUrl: idCardUrl,
        portfolioSamples: portfolioSamples,
      );

      // Reload profile to get updated verification status
      await getMyPhotographerProfile();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? bio,
    List<String>? specialties,
    String? city,
    String? area,
    double? startingPrice,
    String? currency,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await getPhotographerDetailsUseCase.repository.updateProfile(
        bio: bio,
        specialties: specialties,
        city: city,
        area: area,
        startingPrice: startingPrice,
        currency: currency,
      );

      // Reload profile
      await getMyPhotographerProfile();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> searchPhotographers(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final photographers = await searchPhotographersUseCase.call(query);
      state = state.copyWith(
        isLoading: false,
        photographers: photographers,
        currentPage: 1,
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Photographer?> getPhotographerById(String id) async {
    try {
      return await getPhotographerDetailsUseCase.call(id);
    } catch (e) {
      print('❌ Error getting photographer $id: $e');
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSelectedPhotographer() {
    state = state.copyWith(selectedPhotographer: null);
  }

  List<String> get availableCities {
    final cities = <String>{};
    for (final photographer in state.photographers) {
      if (photographer.location.city.isNotEmpty) {
        cities.add(StringUtils.normalizeArabicCity(photographer.location.city));
      }
    }
    return cities.toList()..sort();
  }
}

// Providers
final photographerRepositoryProvider = Provider((ref) {
  return PhotographerRepositoryImpl(
    remoteDataSource: PhotographerRemoteDataSourceImpl(ApiClient()),
    localDataSource: PhotographerLocalDataSource(OfflineService()),
  );
});

final getPhotographersUseCaseProvider = Provider((ref) {
  return GetPhotographersUseCase(ref.watch(photographerRepositoryProvider));
});

final getPhotographerDetailsUseCaseProvider = Provider((ref) {
  return GetPhotographerDetailsUseCase(
    ref.watch(photographerRepositoryProvider),
  );
});

final searchPhotographersUseCaseProvider = Provider((ref) {
  return SearchPhotographersUseCase(ref.watch(photographerRepositoryProvider));
});

final photographersProvider =
    StateNotifierProvider<PhotographersNotifier, PhotographersState>((ref) {
      return PhotographersNotifier(
        getPhotographersUseCase: ref.read(getPhotographersUseCaseProvider),
        getPhotographerDetailsUseCase: ref.read(
          getPhotographerDetailsUseCaseProvider,
        ),
        searchPhotographersUseCase: ref.read(
          searchPhotographersUseCaseProvider,
        ),
      );
    });
