import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_repository.dart';
import 'dashboard_stats.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    final repo = ref.read(dashboardRepositoryProvider);
    return repo.getStats();
  }

  /// Call after a sale, stock change, or product edit elsewhere in the app
  /// to refresh the dashboard numbers. Also just useful as a manual refresh.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardStats>(
  DashboardNotifier.new,
);
