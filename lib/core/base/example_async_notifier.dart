// REFERENCE ONLY — not wired into the app. This shows the pattern described in
// riverpod_conventions.md. Delete this file once Step 7 (Categories CRUD) is done
// and you've written a real one following the same shape.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pretend model + repository for illustration:
class _ExampleItem {
  final int id;
  final String name;
  const _ExampleItem(this.id, this.name);
}

class _ExampleRepository {
  Future<List<_ExampleItem>> getAll() async {
    // In a real feature, this queries SQLite via DatabaseService.
    await Future.delayed(const Duration(milliseconds: 200));
    return [const _ExampleItem(1, 'Sample')];
  }

  Future<void> insert(String name) async {
    // In a real feature: INSERT INTO ... via DatabaseService.
  }

  Future<void> delete(int id) async {
    // In a real feature: DELETE FROM ... via DatabaseService.
  }
}

final _exampleRepositoryProvider = Provider((ref) => _ExampleRepository());

class ExampleNotifier extends AsyncNotifier<List<_ExampleItem>> {
  @override
  Future<List<_ExampleItem>> build() async {
    final repo = ref.read(_exampleRepositoryProvider);
    return repo.getAll();
  }

  Future<void> addItem(String name) async {
    final repo = ref.read(_exampleRepositoryProvider);
    await repo.insert(name);
    ref.invalidateSelf();       // triggers build() again -> refetches list
    await future;                // wait for the refetch to complete
  }

  Future<void> removeItem(int id) async {
    final repo = ref.read(_exampleRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final exampleProvider = AsyncNotifierProvider<ExampleNotifier, List<_ExampleItem>>(
  ExampleNotifier.new,
);

// Widget usage would look like:
//
// final itemsAsync = ref.watch(exampleProvider);
// itemsAsync.when(
//   data: (items) => ListView(children: items.map((i) => Text(i.name)).toList()),
//   loading: () => const CircularProgressIndicator(),
//   error: (e, st) => Text('Error: $e'),
// );
