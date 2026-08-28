import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nav_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/sales/presentation/screens/sales_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/stock_count/presentation/screens/stock_count_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const NavItem({required this.label, required this.icon, required this.screen});
}

// Order here defines the sidebar order AND must match selectedNavIndexProvider indices.
final List<NavItem> navItems = [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, screen: const DashboardScreen()),
  NavItem(label: 'Products', icon: Icons.inventory_2_outlined, screen: const ProductsScreen()),
  NavItem(label: 'Sales', icon: Icons.point_of_sale_outlined, screen: const SalesScreen()),
  NavItem(label: 'Inventory', icon: Icons.warehouse_outlined, screen: const InventoryScreen()),
  NavItem(label: 'Stock Count', icon: Icons.fact_check_outlined, screen: const StockCountScreen()),
  NavItem(label: 'Reports', icon: Icons.bar_chart_outlined, screen: const ReportsScreen()),
  NavItem(label: 'Settings', icon: Icons.settings_outlined, screen: const SettingsScreen()),
];

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedNavIndexProvider);

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(selectedIndex: selectedIndex),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: navItems.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final int selectedIndex;

  const _Sidebar({required this.selectedIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 220,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Mobile Shop',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = index == selectedIndex;

                return ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  selected: isSelected,
                  selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                  onTap: () => ref.read(selectedNavIndexProvider.notifier).state = index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
