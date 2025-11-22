import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetUserStatisticsUseCase {
  final ProfileRepository repository;

  GetUserStatisticsUseCase(this.repository);

  Future<UserStatistics> call() async {
    return await repository.getUserStatistics();
  }
}

// Export for convenience
typedef GetUserStatisticsUseCaseCall = Future<UserStatistics> Function();
