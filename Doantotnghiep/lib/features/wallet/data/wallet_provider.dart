import 'package:doantotnghiep/features/wallet/data/wallet_repository.dart';
import 'package:doantotnghiep/features/wallet/domain/models/wallet_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

class WalletNotifier extends AsyncNotifier<WalletState> {
  @override
  Future<WalletState> build() async {
    return ref.read(walletRepositoryProvider).getWalletInfo();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(walletRepositoryProvider).getWalletInfo());
  }
  
  Future<void> deposit(double amount) async {
      final success = await ref.read(walletRepositoryProvider).deposit(amount);
      if (success) refresh();
  }

  Future<void> withdraw(double amount, String bankName, String accountNumber) async {
      final success = await ref.read(walletRepositoryProvider).withdraw(amount, bankName, accountNumber);
      if (success) refresh();
  }

  Future<void> simulateDeposit(double amount, int userId) async {
      final success = await ref.read(walletRepositoryProvider).simulateDeposit(amount, userId);
      if (success) refresh();
  }

  // --- PIN METHODS ---
  Future<void> setupPin(String pin) async {
      await ref.read(walletRepositoryProvider).setupPin(pin);
      refresh(); // Refresh to update hasPaymentPin
  }

  Future<void> changePin(String oldPin, String newPin) async {
      await ref.read(walletRepositoryProvider).changePin(oldPin, newPin);
      // No need to refresh, status remains hasPaymentPin=true
  }

  Future<bool> verifyPin(String pin) async {
      return ref.read(walletRepositoryProvider).verifyPin(pin);
  }
}
