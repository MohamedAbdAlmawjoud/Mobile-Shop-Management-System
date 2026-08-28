# Riverpod State Conventions (v3)

Every feature that loads data from the database follows this pattern. Do not invent
a different shape per feature — consistency here makes every screen predictable.

## 1. List/data providers → AsyncNotifier

For "load a list of X from the database, allow create/update/delete", use
`AsyncNotifier<List<T>>`. Example shape (see example_async_notifier.dart):

- State is `AsyncValue<List<T>>` — Riverpod gives you loading/error/data for free.
- `build()` does the initial load.
- Mutating methods (add/update/delete) call the repository, then either:
  - optimistically update local state, or
  - simply call `ref.invalidateSelf()` / re-run `build()` to refetch (simplest, safest —
    prefer this until performance says otherwise).

## 2. UI consumption

```dart
final categoriesAsync = ref.watch(categoriesProvider);

categoriesAsync.when(
  data: (categories) => ListView(...),
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

Never manually track `isLoading` / `errorMessage` booleans in a feature — that's what
AsyncValue already does. Don't reinvent it per feature.

## 3. Single-item / form state

For a form (e.g. "editing this Product"), use a plain `Notifier<T>` or
`Notifier<T?>` — no async needed unless the form itself loads existing data.

## 4. Repository layer

Providers should NOT talk to `DatabaseService` directly. Each feature's `data/`
folder holds a `XxxRepository` class with plain methods (`getAll()`, `insert()`,
`update()`, `delete()`). The AsyncNotifier calls the repository. This keeps SQL
out of providers and out of widgets — matches the Golden Rule from the plan.

## 5. Naming

- Repository: `lib/features/<feature>/data/<feature>_repository.dart`
- Provider: `lib/features/<feature>/data/<feature>_provider.dart`
- Notifier class: `<Feature>Notifier`
- Provider instance: `<feature>Provider` (e.g. `categoriesProvider`)
