import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/network/api_client.dart';
import '../../data/models/package_model.dart';
import '../../data/repositories/package_repository.dart';

// State
class PackageState {
  final bool isLoading;
  final String? error;
  final List<PackageModel> packages;

  const PackageState({
    this.isLoading = false,
    this.error,
    this.packages = const [],
  });

  PackageState copyWith({
    bool? isLoading,
    String? error,
    List<PackageModel>? packages,
  }) {
    return PackageState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      packages: packages ?? this.packages,
    );
  }
}

// Notifier
class PackageNotifier extends StateNotifier<PackageState> {
  final PackageRepository _repository;

  PackageNotifier(this._repository) : super(const PackageState());

  Future<void> loadPackages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final packages = await _repository.getMyPackages();
      state = state.copyWith(isLoading: false, packages: packages);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addPackage(PackageModel package) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newPackage = await _repository.addPackage(package);
      state = state.copyWith(
        isLoading: false,
        packages: [...state.packages, newPackage],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updatePackage(String packageId, PackageModel package) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.updatePackage(packageId, package);

      final updatedPackages = state.packages.map((p) {
        if (p.id == packageId) {
          return package.copyWith(id: packageId);
        }
        return p;
      }).toList();

      state = state.copyWith(isLoading: false, packages: updatedPackages);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deletePackage(String packageId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.deletePackage(packageId);

      final updatedPackages = state.packages
          .where((p) => p.id != packageId)
          .toList();

      state = state.copyWith(isLoading: false, packages: updatedPackages);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> togglePackageStatus(String packageId, bool isActive) async {
    try {
      await _repository.togglePackageStatus(packageId, isActive);

      final updatedPackages = state.packages.map((p) {
        if (p.id == packageId) {
          return p.copyWith(isActive: isActive);
        }
        return p;
      }).toList();

      state = state.copyWith(packages: updatedPackages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  return PackageRepository(ApiClient());
});

final packageProvider = StateNotifierProvider<PackageNotifier, PackageState>((
  ref,
) {
  return PackageNotifier(ref.watch(packageRepositoryProvider));
});
