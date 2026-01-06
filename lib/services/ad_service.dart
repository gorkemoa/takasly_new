import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Unit IDs for Android
  static const String androidBannerId =
      'ca-app-pub-3600325889588673/7805712447';
  static const String androidRewardedId =
      'ca-app-pub-3600325889588673/4220640906';
  static const String androidNativeId =
      'ca-app-pub-3600325889588673/5822213790';

  // Unit IDs for iOS
  static const String iosBannerId = 'ca-app-pub-3600325889588673/3365147820';
  static const String iosRewardedId = 'ca-app-pub-3600325889588673/1633441360';
  static const String iosNativeId = 'ca-app-pub-3600325889588673/1202018911';

  static String get bannerAdUnitId =>
      Platform.isAndroid ? androidBannerId : iosBannerId;
  static String get rewardedAdUnitId =>
      Platform.isAndroid ? androidRewardedId : iosRewardedId;
  static String get nativeAdUnitId =>
      Platform.isAndroid ? androidNativeId : iosNativeId;

  Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
  }

  void loadRewardedAd({
    required Function() onAdLoaded,
    required Function(RewardedAd ad) onAdShown,
    required Function() onUserEarnedReward,
    required Function(AdError error) onAdFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          onAdShown(ad);
        },
        onAdFailedToLoad: (error) {
          onAdFailedToLoad(error);
        },
      ),
    );
  }
}
