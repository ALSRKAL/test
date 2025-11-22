import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/core/constants/api_endpoints.dart';
import '../models/package_model.dart';

class PackageRepository {
  final ApiClient _apiClient;

  PackageRepository(this._apiClient);

  Future<List<PackageModel>> getMyPackages() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myPhotographerProfile);

      if (response.data['success'] == true) {
        final photographer = response.data['data'];
        final packagesJson = photographer['packages'] as List<dynamic>;
        return packagesJson.map((json) => PackageModel.fromJson(json)).toList();
      }

      throw Exception('Failed to load packages');
    } catch (e) {
      throw Exception('خطأ في تحميل الباقات: $e');
    }
  }

  Future<PackageModel> addPackage(PackageModel package) async {
    try {
      // Get photographer ID first
      final profileResponse = await _apiClient.get(
        ApiEndpoints.myPhotographerProfile,
      );
      final photographerId = profileResponse.data['data']['_id'];

      final response = await _apiClient.post(
        '${ApiEndpoints.photographers}/$photographerId/packages',
        data: package.toJson(),
      );

      if (response.data['success'] == true) {
        final packages = response.data['data'] as List<dynamic>;
        return PackageModel.fromJson(packages.last);
      }

      throw Exception('Failed to add package');
    } catch (e) {
      throw Exception('خطأ في إضافة الباقة: $e');
    }
  }

  Future<void> updatePackage(String packageId, PackageModel package) async {
    try {
      // Get photographer ID first
      final profileResponse = await _apiClient.get(
        ApiEndpoints.myPhotographerProfile,
      );
      final photographerId = profileResponse.data['data']['_id'];

      final response = await _apiClient.put(
        '${ApiEndpoints.photographers}/$photographerId/packages/$packageId',
        data: package.toJson(),
      );

      if (response.data['success'] != true) {
        throw Exception('Failed to update package');
      }
    } catch (e) {
      throw Exception('خطأ في تحديث الباقة: $e');
    }
  }

  Future<void> deletePackage(String packageId) async {
    try {
      // Get photographer ID first
      final profileResponse = await _apiClient.get(
        ApiEndpoints.myPhotographerProfile,
      );
      final photographerId = profileResponse.data['data']['_id'];

      final response = await _apiClient.delete(
        '${ApiEndpoints.photographers}/$photographerId/packages/$packageId',
      );

      if (response.data['success'] != true) {
        throw Exception('Failed to delete package');
      }
    } catch (e) {
      throw Exception('خطأ في حذف الباقة: $e');
    }
  }

  Future<void> togglePackageStatus(String packageId, bool isActive) async {
    try {
      // Get photographer ID first
      final profileResponse = await _apiClient.get(
        ApiEndpoints.myPhotographerProfile,
      );
      final photographerId = profileResponse.data['data']['_id'];

      final response = await _apiClient.put(
        '${ApiEndpoints.photographers}/$photographerId/packages/$packageId',
        data: {'isActive': isActive},
      );

      if (response.data['success'] != true) {
        throw Exception('Failed to toggle package status');
      }
    } catch (e) {
      throw Exception('خطأ في تغيير حالة الباقة: $e');
    }
  }
}
