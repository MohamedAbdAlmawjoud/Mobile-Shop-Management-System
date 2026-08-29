import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_service.dart';
import 'core/router/main_layout.dart';
import 'features/auth/data/auth_provider.dart';
import 'features/auth/presentation/screens/create_admin_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await DatabaseService.instance.database;
  debugPrint('Database opened at: ${db.path}');

  runApp(const ProviderScope(child: MobileShopApp()));
}

class MobileShopApp extends ConsumerWidget {
  const MobileShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Mobile Shop Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const _RootGate(),
    );
  }
}

/// Decides which screen to show at startup:
/// - No users in the DB yet -> first-run admin setup
/// - Users exist but nobody logged in -> login screen
/// - Logged in -> the main app
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user != null) {
      return const MainLayout();
    }

    final hasUsersAsync = ref.watch(hasAnyUsersProvider);
    return hasUsersAsync.when(
      data: (hasUsers) => hasUsers ? const LoginScreen() : const CreateAdminScreen(),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Startup error: $e'))),
    );
  }
}
