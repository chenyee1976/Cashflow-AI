import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_colors.dart';

class FinancialServicesAdBanner extends StatefulWidget {
  const FinancialServicesAdBanner({super.key});

  @override
  State<FinancialServicesAdBanner> createState() => _FinancialServicesAdBannerState();
}

class _FinancialServicesAdBannerState extends State<FinancialServicesAdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Real AdMob Production ID
  static const String _productionAdUnitId = 'ca-app-pub-7965815052651159/5636366798';
  
  // Google Official Test Banner ID (used in debug builds or until AdMob approval propagates)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAdMobBanner();
    }
  }

  void _loadAdMobBanner() {
    const adUnitId = kDebugMode ? _testBannerAdUnitId : _productionAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        color: AppColors.surface,
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Elegant clean fallback card for Web or while AdMob initializes
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: AppColors.divider.withOpacity(0.5)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Text(
              'SPONSORED',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Explore Singapore high-yield savings accounts & rewards cards',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
