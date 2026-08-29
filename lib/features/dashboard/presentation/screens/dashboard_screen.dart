import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/dashboard_provider.dart';
import '../../data/dashboard_stats.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _DashboardBody(stats: stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading dashboard: $error')),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardStats stats;

  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary cards row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                icon: Icons.point_of_sale_outlined,
                label: "Today's Sales",
                value: currency.format(stats.todaySalesTotal),
                subtitle: '${stats.todaySalesCount} sale(s)',
                color: Colors.green,
              ),
              _StatCard(
                icon: Icons.inventory_2_outlined,
                label: 'Total Products',
                value: '${stats.totalProducts}',
                color: Colors.indigo,
              ),
              _StatCard(
                icon: Icons.warning_amber_rounded,
                label: 'Low Stock Items',
                value: '${stats.lowStockProducts.length}',
                color: stats.lowStockProducts.isEmpty ? Colors.grey : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Low stock list
          Text('Low Stock Products', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: stats.lowStockProducts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No low-stock products.'),
                  )
                : Column(
                    children: stats.lowStockProducts
                        .map((p) => ListTile(
                              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              title: Text(p.name),
                              trailing: Text('Qty: ${p.quantity}'),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),

          // Recent sales list
          Text('Recent Sales', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: stats.recentSales.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No sales yet.'),
                  )
                : Column(
                    children: stats.recentSales
                        .map((s) => ListTile(
                              leading: const Icon(Icons.receipt_long_outlined),
                              title: Text('${currency.format(s.total)} · ${s.paymentMethod}'),
                              subtitle: Text(
                                '${s.cashierUsername} · ${DateFormat.yMd().add_jm().format(s.createdAt)}',
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
