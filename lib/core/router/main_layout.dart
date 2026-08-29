import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nav_provider.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
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
  final List<String> allowedRoles; // roles that can see this item

  const NavItem({
    required this.label,
    required this.icon,
    required this.screen,
    this.allowedRoles = const ['admin', 'cashier'],
  });
}

// Full list of possible nav items. Filtered per-user by role in MainLayout —
// do not assume this list's indices match what's shown on screen.
final List<NavItem> navItems = [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, screen: const DashboardScreen()),
  NavItem(
    label: 'Categories',
    icon: Icons.category_outlined,
    screen: const CategoriesScreen(),
    allowedRoles: const ['admin'],
  ),
  NavItem(
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    screen: const ProductsScreen(),
    allowedRoles: const ['admin'],
  ),
  NavItem(label: 'Sales', icon: Icons.point_of_sale_outlined, screen: const SalesScreen()),
  NavItem(
    label: 'Inventory',
    icon: Icons.warehouse_outlined,
    screen: const InventoryScreen(),
    allowedRoles: const ['admin'],
  ),
  NavItem(
    label: 'Stock Count',
    icon: Icons.fact_check_outlined,
    screen: const StockCountScreen(),
    allowedRoles: const ['admin'],
  ),
  NavItem(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    screen: const ReportsScreen(),
    allowedRoles: const ['admin'],
  ),
  NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    screen: const SettingsScreen(),
    allowedRoles: const ['admin'],
  ),
];

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      // Shouldn't happen — MobileShopApp only shows MainLayout when logged in.
      return const SizedBox.shrink();
    }

    final visibleItems =
        navItems.where((item) => item.allowedRoles.contains(user.role)).toList();

    final selectedIndex = ref.watch(selectedNavIndexProvider);
    // Clamp in case the stored index is out of range for this user's role
    // (e.g. a cashier had a higher index selected from a previous admin session).
    final safeIndex = selectedIndex < visibleItems.length ? selectedIndex : 0;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(visibleItems: visibleItems, selectedIndex: safeIndex),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: safeIndex,
              children: visibleItems.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final List<NavItem> visibleItems;
  final int selectedIndex;

  const _Sidebar({required this.visibleItems, required this.selectedIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

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
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.username ?? ''),
            subtitle: Text(user?.role ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              ref.read(selectedNavIndexProvider.notifier).state = 0;
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

