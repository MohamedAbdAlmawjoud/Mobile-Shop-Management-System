// Example AsyncNotifier pattern; see riverpod_conventions.md.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ExampleItem {
  final int id;
  final String name;
  const _ExampleItem(this.id, this.name);
}

class _ExampleRepository {
  Future<List<_ExampleItem>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [const _ExampleItem(1, 'Sample')];
  }

  Future<void> insert(String name) async {
  }

  Future<void> delete(int id) async {
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
    ref.invalidateSelf();
    await future;
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
