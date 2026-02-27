import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  PurchaseService._internal();

  static final PurchaseService instance = PurchaseService._internal();

  static const String coffeeProductId = 'coffee_week';
  static const Duration coffeeDuration = Duration(days: 7);
  static const String _premiumUntilKey = 'premium_until_ms';

  final InAppPurchase _iap = InAppPurchase.instance;
  final ValueNotifier<bool> premiumActive = ValueNotifier(false);

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _coffeeProduct;
  bool _available = false;

  Future<void> init() async {
    _available = await _iap.isAvailable();
    await _refreshPremiumStatus();
    if (!_available) return;
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {},
    );
    await _queryProducts();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  Future<void> _queryProducts() async {
    final response = await _iap.queryProductDetails({coffeeProductId});
    if (response.productDetails.isNotEmpty) {
      _coffeeProduct = response.productDetails.first;
    }
  }

  Future<ProductDetails?> getCoffeeProduct() async {
    if (_coffeeProduct != null) return _coffeeProduct;
    if (!_available) return null;
    await _queryProducts();
    return _coffeeProduct;
  }

  Future<DateTime?> getPremiumUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(_premiumUntilKey) ?? 0;
    if (untilMs <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(untilMs);
  }

  Future<void> _refreshPremiumStatus() async {
    final until = await getPremiumUntil();
    if (until == null) {
      premiumActive.value = false;
      return;
    }
    premiumActive.value = until.isAfter(DateTime.now());
  }

  Future<void> buyCoffee() async {
    if (!_available) return;
    final product = await getCoffeeProduct();
    if (product == null) return;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true,
    );
  }

  Future<void> _grantCoffeeWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final existing = prefs.getInt(_premiumUntilKey) ?? 0;
    final base = existing > nowMs ? existing : nowMs;
    final updated = base + coffeeDuration.inMilliseconds;
    await prefs.setInt(_premiumUntilKey, updated);
    premiumActive.value = true;
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _grantCoffeeWeek();
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    await _refreshPremiumStatus();
  }
}
