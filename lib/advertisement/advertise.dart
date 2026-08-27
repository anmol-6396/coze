import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Services/theme_manager.dart';

class AdvertiseManager {
  static final AdvertiseManager _instance = AdvertiseManager._internal();
  factory AdvertiseManager() => _instance;
  AdvertiseManager._internal();

  // ✅ Ad Unit IDs
  static const String _interstitialAdUnitId = "ca-app-pub-5339763406474020/9846004344";
  static const String _nativeAdUnitId = "ca-app-pub-5339763406474020/9657775429";

  // ✅ Interstitial Ad Logic
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _detailOpenCount = 0;
  DateTime _lastAdTime = DateTime.now(); // ✅ Track last ad time

  // ✅ Preload Interstitial
  void preloadInterstitial() {
    if (_interstitialAd != null || _isInterstitialLoading) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('Interstitial Ad Preloaded.');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('Interstitial Ad Load Failed: $error');
        },
      ),
    );
  }

  // ✅ Show Interstitial Ad (Every 5th Time OR after 30 seconds)
  void showInterstitialAd(VoidCallback onAdDismissed) {
    _detailOpenCount++;
    final now = DateTime.now();
    final secondsSinceLastAd = now.difference(_lastAdTime).inSeconds;
    
    debugPrint("Click Count: $_detailOpenCount, Secs since last ad: $secondsSinceLastAd");

    // ✅ Rule 1: Every 5th click
    // ✅ Rule 2: If 30 seconds passed, show ad on next click
    if (_detailOpenCount >= 5 || secondsSinceLastAd >= 30) {
      if (_interstitialAd != null) {
        _showReadyAd(onAdDismissed);
      } else {
        _loadAndShowInterstitial(onAdDismissed);
      }
    } else {
      onAdDismissed();
    }
  }

  void _showReadyAd(VoidCallback onAdDismissed) {
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _resetAdTracker(); // ✅ Reset both rules
        preloadInterstitial();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _resetAdTracker();
        preloadInterstitial();
        onAdDismissed();
      },
    );
    _interstitialAd!.show();
  }

  void _loadAndShowInterstitial(VoidCallback onAdDismissed) {
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialLoading = false;
          _interstitialAd = ad;
          _showReadyAd(onAdDismissed);
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('Interstitial fallback failed: $error');
          _resetAdTracker(); // Reset even if failed so timer starts fresh
          onAdDismissed();
        },
      ),
    );
  }

  // ✅ Reset logic helper
  void _resetAdTracker() {
    _detailOpenCount = 0;
    _lastAdTime = DateTime.now();
  }

  // ✅ Native Ad Helper for Grid/Lists
  NativeAd createNativeAd({
    required Function(NativeAd) onAdLoaded,
    required Function(NativeAd, LoadAdError) onAdFailed,
    bool isDark = false, // Pass current theme state
  }) {
    return NativeAd(
      adUnitId: _nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) => onAdLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailed(ad as NativeAd, error);
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        cornerRadius: 12.0.r,
      ),
    )..load();
  }
}

/// ✅ Reusable Native Ad Widget
class NativeAdBanner extends StatefulWidget {
  final double? height;
  const NativeAdBanner({super.key, this.height});

  @override
  State<NativeAdBanner> createState() => _NativeAdBannerState();
}

class _NativeAdBannerState extends State<NativeAdBanner> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool? _lastIsDark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ✅ Re-load ad if theme changed to match background
    if (_lastIsDark != null && _lastIsDark != isDark) {
      _nativeAd?.dispose();
      _isLoaded = false;
      _loadAd(isDark);
    }
    _lastIsDark = isDark;
  }

  @override
  void initState() {
    super.initState();
    // Ad loading will be triggered by didChangeDependencies
  }

  void _loadAd(bool isDark) {
    _nativeAd = AdvertiseManager().createNativeAd(
      isDark: isDark,
      onAdLoaded: (ad) {
        if (mounted) setState(() => _isLoaded = true);
      },
      onAdFailed: (ad, error) {
        if (mounted) setState(() => _isLoaded = false);
      },
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();

    final isDark = ThemeManager.instance.isDarkMode;

    return Container(
      width: double.infinity,
      height: widget.height?.h ?? 100.h,
      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: isDark ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 4.r,
          )
        ],
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
