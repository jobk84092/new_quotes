import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:new_quotes/services/purchase_service.dart';

class SupportCard extends StatefulWidget {
  const SupportCard({super.key});

  @override
  State<SupportCard> createState() => _SupportCardState();
}

class _SupportCardState extends State<SupportCard> {
  late Future<ProductDetails?> _productFuture;
  late Future<DateTime?> _untilFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = PurchaseService.instance.getCoffeeProduct();
    _untilFuture = PurchaseService.instance.getPremiumUntil();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PurchaseService.instance.premiumActive,
      builder: (context, premiumActive, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support the developer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  premiumActive
                      ? 'Thanks! Ads are off for 7 days.'
                      : 'Buy a coffee to remove ads for 7 days.',
                ),
                const SizedBox(height: 10),
                FutureBuilder<ProductDetails?>(
                  future: _productFuture,
                  builder: (context, snapshot) {
                    final product = snapshot.data;
                    final priceLabel = product?.price ?? 'Buy coffee';
                    return ElevatedButton(
                      onPressed: product == null
                          ? null
                          : () async {
                              await PurchaseService.instance.buyCoffee();
                              if (!mounted) return;
                              setState(() {
                                _untilFuture = PurchaseService.instance.getPremiumUntil();
                              });
                            },
                      child: Text(product == null ? 'Store unavailable' : priceLabel),
                    );
                  },
                ),
                if (premiumActive)
                  FutureBuilder<DateTime?>(
                    future: _untilFuture,
                    builder: (context, snapshot) {
                      final until = snapshot.data;
                      if (until == null) return const SizedBox.shrink();
                      final date = until.toLocal().toString().split(' ').first;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text('Ads resume on $date'),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
