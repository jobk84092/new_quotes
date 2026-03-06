import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:new_quotes/services/purchase_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  // Replace /0000000001 with your Banner Ad Unit ID from AdMob > Apps > Ad units
  static const String _androidAdUnitId =
      'ca-app-pub-2518115915091022/0000000001';

  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;
    final ad = BannerAd(
      adUnitId: _androidAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
        },
      ),
    );
    ad.load();
    _banner = ad;
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: PurchaseService.instance.premiumActive,
      builder: (context, premiumActive, child) {
        if (premiumActive || !_loaded || _banner == null) {
          return const SizedBox.shrink();
        }
        final ad = _banner!;
        return SizedBox(
          height: ad.size.height.toDouble(),
          width: ad.size.width.toDouble(),
          child: AdWidget(ad: ad),
        );
      },
    );
  }
}
