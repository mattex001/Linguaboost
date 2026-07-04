import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/purchase_service.dart';

// ── Service singleton ─────────────────────────────────────────────────────────

final purchaseServiceProvider = Provider<PurchaseService>(
  (_) => PurchaseService.instance,
);

// ── Offerings ─────────────────────────────────────────────────────────────────

/// Fetches RevenueCat offerings once. Refresh with ref.invalidate(offeringsProvider).
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return ref.watch(purchaseServiceProvider).getOfferings();
});

// ── Live CustomerInfo stream ──────────────────────────────────────────────────

/// Real-time CustomerInfo updates from RevenueCat.
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  return ref.watch(purchaseServiceProvider).customerInfoStream;
});

// ── Premium status ────────────────────────────────────────────────────────────

/// True when the user has an active premium entitlement.
final isPremiumProvider = Provider<bool>((ref) {
  final svc = ref.watch(purchaseServiceProvider);
  return ref.watch(customerInfoProvider).maybeWhen(
        data: (info) => svc.hasActivePremium(info),
        orElse: () => false,
      );
});

// ── Purchase state ────────────────────────────────────────────────────────────

enum PurchaseStatus { idle, loading, success, error }

class PurchaseState {
  const PurchaseState({
    this.status = PurchaseStatus.idle,
    this.errorMessage,
  });

  final PurchaseStatus status;
  final String? errorMessage;

  PurchaseState copyWith({PurchaseStatus? status, String? errorMessage}) =>
      PurchaseState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

// ── Purchase notifier (Riverpod 3.x) ─────────────────────────────────────────

class PurchaseNotifier extends Notifier<PurchaseState> {
  @override
  PurchaseState build() => const PurchaseState();

  // ── Purchase ────────────────────────────────────────────────────────────────

  Future<bool> purchase(Package package) async {
    state = state.copyWith(status: PurchaseStatus.loading);

    try {
      final svc = ref.read(purchaseServiceProvider);
      final info = await svc.purchasePackage(package);

      if (svc.hasActivePremium(info)) {
        await _syncFirestore(isTrial: true);
        state = state.copyWith(status: PurchaseStatus.success);
        return true;
      }

      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: 'Purchase completed but entitlement not found.',
      );
      return false;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        state = state.copyWith(status: PurchaseStatus.idle);
      } else {
        state = state.copyWith(
          status: PurchaseStatus.error,
          errorMessage: _message(e),
        );
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ── Restore ─────────────────────────────────────────────────────────────────

  Future<bool> restore() async {
    state = state.copyWith(status: PurchaseStatus.loading);

    try {
      final svc = ref.read(purchaseServiceProvider);
      final info = await svc.restorePurchases();

      if (svc.hasActivePremium(info)) {
        await _syncFirestore(isTrial: false);
        state = state.copyWith(status: PurchaseStatus.success);
        return true;
      }

      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: 'No active subscription found to restore.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: PurchaseStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearError() => state = const PurchaseState();

  // ── Profile sync ────────────────────────────────────────────────────────────

  Future<void> _syncFirestore({required bool isTrial}) async {
    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid == null) return;
    final repo = ref.read(userRepositoryProvider);
    if (isTrial) {
      await repo.activateTrial(uid);
    } else {
      await repo.activatePremium(uid);
    }
  }

  // ── Error messages ──────────────────────────────────────────────────────────

  String _message(PurchasesErrorCode code) {
    return switch (code) {
      PurchasesErrorCode.networkError => 'Network error. Check your connection.',
      PurchasesErrorCode.paymentPendingError => 'Payment is pending. Check back soon.',
      PurchasesErrorCode.productAlreadyPurchasedError => 'You already own this subscription.',
      PurchasesErrorCode.purchaseNotAllowedError => 'Purchases are not allowed on this device.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}

final purchaseNotifierProvider = NotifierProvider<PurchaseNotifier, PurchaseState>(
  PurchaseNotifier.new,
);
