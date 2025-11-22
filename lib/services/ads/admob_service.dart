import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for managing Google AdMob ads
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // Test Ad Unit IDs (replace with real IDs in production)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // Production Ad Unit IDs (replace with your actual IDs)
  static const String _androidBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _iosBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  /// Initialize AdMob
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Get banner ad unit ID
  String get bannerAdUnitId {
    // Use test ads for development
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      return _testBannerAdUnitId;
    }

    // Use production ads
    if (Platform.isAndroid) {
      return _androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _iosBannerAdUnitId;
    }
    return _testBannerAdUnitId;
  }

  /// Get interstitial ad unit ID
  String get interstitialAdUnitId {
    // Use test ads for development
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      return _testInterstitialAdUnitId;
    }

    // Use production ads
    if (Platform.isAndroid) {
      return _androidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _iosInterstitialAdUnitId;
    }
    return _testInterstitialAdUnitId;
  }

  /// Create banner ad
  BannerAd createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
    return _bannerAd!;
  }

  /// Load interstitial ad
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('Interstitial ad loaded');

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Load next ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      print('Interstitial ad not ready');
      await loadInterstitialAd();
    }
  }

  /// Dispose banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  /// Dispose interstitial ad
  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }

  /// Dispose all ads
  void disposeAll() {
    disposeBannerAd();
    disposeInterstitialAd();
  }
}
