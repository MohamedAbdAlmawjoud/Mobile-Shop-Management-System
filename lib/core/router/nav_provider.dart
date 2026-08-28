import 'package:flutter_riverpod/legacy.dart';

/// Index of the currently selected sidebar item.
/// Order must match NavItem list in main_layout.dart.
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);
