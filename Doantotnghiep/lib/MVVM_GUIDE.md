# 📘 HƯỚNG DẪN MVVM PATTERN TRONG DỰ ÁN (Riverpod 2.6.x)

## 🎯 Tổng quan

Dự án sử dụng **MVVM (Model-View-ViewModel)** pattern với **Riverpod 2.6.x** làm state management.
Chuẩn hiện tại là sử dụng **`AsyncNotifier`** (cho async state) và **`Notifier`** (cho sync state).

> [!IMPORTANT]
> `StateNotifier` (cách cũ) được coi là **Legacy**. Hãy ưu tiên sử dụng `AsyncNotifier` cho tất cả các tính năng mới hoặc khi refactor.

## 🏗️ Kiến trúc

```
lib/features/[feature]/
  ├── data/                    # Data layer (Repositories)
  ├── domain/                  # Domain layer (Models, Logic)
  └── presentation/            # Presentation layer
      ├── view_models/         # ViewModels (AsyncNotifier/Notifier)
      │   └── [feature]_view_model.dart
      ├── views/               # Widgets (ConsumerWidget)
      │   └── [feature]_screen.dart
      └── widgets/             # Local widgets
```

## 📋 Components

### 1. ViewModels (AsyncNotifier)

Sử dụng `AsyncNotifier<T>` thay vì `StateNotifier`.

```dart
// lib/features/tutor/presentation/view_models/tutor_view_model.dart

// 1. Define Provider
final tutorViewModelProvider = AsyncNotifierProvider<TutorViewModel, List<Tutor>>(
  () => TutorViewModel(),
);

// 2. Define ViewModel
class TutorViewModel extends AsyncNotifier<List<Tutor>> {
  
  // Initialize State (Loading -> Data/Error handled automatically)
  @override
  FutureOr<List<Tutor>> build() async {
    return await ref.read(tutorRepositoryProvider).getTutors();
  }

  // Actions
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(tutorRepositoryProvider).getTutors();
    });
  }
  
  // Optimistic UI updates / Mutations
  Future<void> toggleFavorite(String tutorId) async {
    // Example logic
  }
}
```

### 2. Views (ConsumerWidget)

Widget lắng nghe state trực tiếp từ Provider.

```dart
// lib/features/tutor/presentation/views/tutor_screen.dart

class TutorScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state
    final asyncTutors = ref.watch(tutorViewModelProvider);

    return Scaffold(
      body: asyncTutors.when(
        data: (tutors) => ListView.builder(itemBuilder: ...),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            // Call ViewModel action
            ref.read(tutorViewModelProvider.notifier).refresh();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

## 🔄 So sánh cũ vs mới

| Feature | Cũ (`StateNotifier`) | Mới (`AsyncNotifier` - Recommended) |
| :--- | :--- | :--- |
| **Base Class** | `extends StateNotifier<AsyncValue<T>>` | `extends AsyncNotifier<T>` |
| **Initial State** | `super(AsyncValue.loading())` sau đó gọi init | `build()` method (Auto loading) |
| **Update State** | `state = AsyncValue.data(val)` | Return value in `build` or simple mutation |
| **Error Handling** | `try-catch` thủ công | `AsyncValue.guard(() => ...)` |

## ✅ Migration Checklist

Khi tạo feature mới hoặc refactor:
- [ ] Dùng `AsyncNotifier` (hoặc `Notifier`).
- [ ] Đặt ViewModel vào folder `presentation/view_models`.
- [ ] Đặt Screen vào folder `presentation/views`.
- [ ] Không dùng `StateNotifier` trừ khi có lý do đặc biệt.
