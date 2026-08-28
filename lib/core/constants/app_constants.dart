// Shared constants — table names, user roles, stock movement types, etc.

class AppConstants {
  // Table names
  static const String tableUsers = 'users';
  static const String tableCategories = 'categories';
  static const String tableProducts = 'products';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';
  static const String tableStockMovements = 'stock_movements';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleCashier = 'cashier';

  // Stock movement types
  static const String movementStockIn = 'STOCK_IN';
  static const String movementSale = 'SALE';
  static const String movementAdjustment = 'ADJUSTMENT';
}
