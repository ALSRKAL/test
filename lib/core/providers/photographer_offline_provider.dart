import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_service.dart';
import '../../features/photographer/data/datasources/photographer_local_datasource.dart';

final photographerLocalDataSourceProvider = Provider<PhotographerLocalDataSource>((ref) {
  return PhotographerLocalDataSource(OfflineService());
});

final localPhotographersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final localDataSource = ref.watch(photographerLocalDataSourceProvider);
  return await localDataSource.getPhotographers();
});

final localFavoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final localDataSource = ref.watch(photographerLocalDataSourceProvider);
  return await localDataSource.getFavorites();
});
