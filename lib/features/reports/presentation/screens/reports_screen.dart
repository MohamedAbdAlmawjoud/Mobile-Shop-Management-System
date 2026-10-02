import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../sales/data/sales_provider.dart';
import '../../../users/data/users_provider.dart';
import '../../data/report_models.dart';
import '../../data/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Inventory'),
            Tab(text: 'Low Stock'),
            Tab(text: 'Adjustments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SalesReportTab(),
          _InventoryReportTab(),
          _LowStockReportTab(),
          _AdjustmentReportTab(),
        ],
      ),
    );
  }
}

// ---------------- Sales Report ----------------

class _SalesReportTab extends ConsumerWidget {
  const _SalesReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(salesReportDateRangeProvider);
    final cashierId = ref.watch(salesReportCashierFilterProvider);
    final usersAsync = ref.watch(usersProvider);
    final reportAsync = ref.watch(salesReportProvider);
    final dateFormat = DateFormat.yMd();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${dateFormat.format(range.start)} – ${dateFormat.format(range.end)}',
                ),
                onPressed: () => _pickRange(context, ref, range),
              ),
              const SizedBox(width: 12),
              usersAsync.when(
                data: (users) => DropdownButton<int?>(
                  value: cashierId,
                  hint: const Text('All cashiers'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All cashiers')),
                    ...users.map(
                      (u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.username)),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(salesReportCashierFilterProvider.notifier).state = value,
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ref.invalidate(salesReportProvider),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: reportAsync.when(
            data: (report) {
              if (report.sales.isEmpty) {
                return const Center(child: Text('No sales in this date range.'));
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _SummaryChip(label: 'Revenue', value: '\$${report.totalRevenue.toStringAsFixed(2)}'),
                        const SizedBox(width: 12),
                        _SummaryChip(label: 'Sales', value: '${report.totalSalesCount}'),
                        const SizedBox(width: 12),
                        _SummaryChip(label: 'Items sold', value: '${report.totalItemsSold}'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: report.sales.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sale = report.sales[index];
                        return ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text('Sale #${sale.saleId} · \$${sale.total.toStringAsFixed(2)}'),
                          subtitle: Text(
                            '${sale.cashierUsername} · ${sale.paymentMethod} · '
                            '${DateFormat.yMd().add_jm().format(sale.createdAt)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${sale.itemCount} item(s)'),
                              IconButton(
                                icon: const Icon(Icons.print_outlined, size: 20),
                                tooltip: 'Print invoice',
                                onPressed: () => _printInvoice(context, ref, sale.saleId),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref, DateRange current) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: current.start, end: current.end),
    );
    if (picked != null) {
      ref.read(salesReportDateRangeProvider.notifier).state =
          DateRange(start: picked.start, end: picked.end);
    }
  }

  Future<void> _printInvoice(BuildContext context, WidgetRef ref, int saleId) async {
    final repo = ref.read(salesRepositoryProvider);
    final sale = await repo.getSaleDetail(saleId);
    if (sale == null) return;

    final invoiceService = ref.read(invoiceServiceProvider);
    await invoiceService.printInvoice(sale);
  }
}

// ---------------- Inventory Report ----------------

class _InventoryReportTab extends ConsumerWidget {
  const _InventoryReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(inventoryReportProvider);

    return reportAsync.when(
      data: (report) {
        if (report.rows.isEmpty) {
          return const Center(child: Text('No products yet.'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _SummaryChip(label: 'Total stock value', value: '\$${report.totalStockValue.toStringAsFixed(2)}'),
                  const SizedBox(width: 12),
                  _SummaryChip(label: 'Total units', value: '${report.totalUnits}'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: report.rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = report.rows[index];
                  return ListTile(
                    title: Text(row.product.name),
                    subtitle: Text('${row.categoryName} · Qty: ${row.product.quantity}'),
                    trailing: Text('\$${row.stockValue.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

// ---------------- Low Stock Report ----------------

class _LowStockReportTab extends ConsumerWidget {
  const _LowStockReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(lowStockReportProvider);

    return reportAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('No low-stock products. 🎉'));
        }
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = products[index];
            return ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: Text(p.name),
              trailing: Text('Qty: ${p.quantity}', style: const TextStyle(color: Colors.orange)),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

// ---------------- Adjustment Report ----------------

class _AdjustmentReportTab extends ConsumerWidget {
  const _AdjustmentReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(adjustmentReportProvider);
    final dateFormat = DateFormat.yMd().add_jm();

    return reportAsync.when(
      data: (adjustments) {
        if (adjustments.isEmpty) {
          return const Center(child: Text('No stock count adjustments yet.'));
        }
        return ListView.separated(
          itemCount: adjustments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final a = adjustments[index];
            final isPositive = a.quantityChange > 0;
            return ListTile(
              leading: Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.red,
              ),
              title: Text(a.productName),
              subtitle: Text(
                '${a.username} · ${dateFormat.format(a.createdAt)}'
                '${a.reason != null ? ' · ${a.reason}' : ''}',
              ),
              trailing: Text(
                '${isPositive ? '+' : ''}${a.quantityChange}',
                style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
