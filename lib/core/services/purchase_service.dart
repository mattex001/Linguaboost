import 'dart:async';
import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

// ── RevenueCat keys — replace with your dashboard values ─────────────────────
//   iOS key:     App Settings → API Keys → Public app-specific key (App Store)
//   Android key: App Settings → API Keys → Public app-specific key (Play Store)
//   Entitlement: the entitlement ID you created, e.g. "premium"

const _rcApiKeyIos = 'appl_REPLACE_WITH_YOUR_IOS_KEY';
const _rcApiKeyAndroid = 'goog_REPLACE_WITH_YOUR_ANDROID_KEY';
const _entitlementId = 'premium';

// ── PurchaseService ───────────────────────────────────────────────────────────

class PurchaseService {
  // Singleton
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Stream of CustomerInfo updates (wraps RC's listener callback).
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  // ── Configuration ──────────────────────────────────────────────────────────

  /// Call once after Supabase init, before runApp.
  /// [userId] is optional — pass the Supabase user id if already signed in.
  Future<void> configure({String? userId}) async {
    final apiKey = Platform.isIOS ? _rcApiKeyIos : _rcApiKeyAndroid;
    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config);

    // Forward RC listener updates into our broadcast stream.
    Purchases.addCustomerInfoUpdateListener((info) {
      _customerInfoController.add(info);
    });
  }

  // ── Identity ───────────────────────────────────────────────────────────────

  /// Link purchases to the signed-in app user after sign-in.
  Future<void> logIn(String uid) async {
    await Purchases.logIn(uid);
  }

  /// Reset to anonymous RC user on sign-out.
  Future<void> logOut() async {
    await Purchases.logOut();
  }

  // ── Offerings ──────────────────────────────────────────────────────────────

  /// Fetches current offerings. Returns null on error.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // ── Purchase ───────────────────────────────────────────────────────────────

  /// Purchase a [package]. Throws [PurchasesErrorCode] on failure/cancellation.
  Future<CustomerInfo> purchasePackage(Package package) async {
    return await Purchases.purchasePackage(package);
  }

  /// Restore previous purchases (e.g. after reinstall).
  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  // ── Customer info ──────────────────────────────────────────────────────────

  /// Fetch latest CustomerInfo from cache or network.
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// True if [info] contains an active premium entitlement.
  bool hasActivePremium(CustomerInfo info) {
    return info.entitlements.active.containsKey(_entitlementId);
  }
}
