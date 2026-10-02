import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'report_models.dart';
import 'reports_repository.dart';

final reportsRepositoryProvider = Provider((ref) => ReportsRepository());

/// Selected date range for the Sales Report. Defaults to the last 7 days.
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange({required this.start, required this.end});
}

final salesReportDateRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  return DateRange(start: now.subtract(const Duration(days: 6)), end: now);
});

/// null = all cashiers. Otherwise restricts the Sales Report to one user.
final salesReportCashierFilterProvider = StateProvider<int?>((ref) => null);

final salesReportProvider = FutureProvider<SalesReportData>((ref) async {
  final range = ref.watch(salesReportDateRangeProvider);
  final cashierId = ref.watch(salesReportCashierFilterProvider);
  final repo = ref.read(reportsRepositoryProvider);
  return repo.getSalesReport(start: range.start, end: range.end, userId: cashierId);
});

final inventoryReportProvider = FutureProvider<InventoryReportData>((ref) async {
  final repo = ref.read(reportsRepositoryProvider);
  return repo.getInventoryReport();
});

final lowStockReportProvider = FutureProvider((ref) async {
  final repo = ref.read(reportsRepositoryProvider);
  return repo.getLowStockReport();
});

final adjustmentReportProvider = FutureProvider<List<AdjustmentReportRow>>((ref) async {
  final repo = ref.read(reportsRepositoryProvider);
  return repo.getAdjustmentReport();
});
