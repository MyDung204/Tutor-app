import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Legacy BaseViewModel - Giữ lại để tương thích ngược (nếu còn code cũ dùng nó).
/// Khuyến nghị: Các ViewModel mới nên extends trực tiếp `AsyncNotifier<T>` hoặc `Notifier<T>`.
abstract class BaseViewModel<T> extends StateNotifier<AsyncValue<T>> {
  BaseViewModel() : super(const AsyncValue.loading());

  Future<T> initialize() async {
    throw UnimplementedError('initialize() must be implemented by subclass');
  }

  Future<void> execute(Future<T> Function() action) async {
    state = const AsyncValue.loading();
    try {
      final result = await action();
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

/// Legacy BaseStateNotifier - Supports synchronous state management (legacy)
abstract class BaseStateNotifier<T> extends StateNotifier<T> {
  final Ref ref;
  BaseStateNotifier(this.ref, T state) : super(state);
}
