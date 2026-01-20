import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/services/cache_service.dart';
import 'package:takasly/viewmodels/home_viewmodel.dart';
import 'package:takasly/viewmodels/product_viewmodel.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/views/home/home_view.dart';
import 'package:takasly/views/onboarding/onboarding_view.dart';
import 'package:takasly/views/products/add_product_view.dart';
import 'package:takasly/views/splash/splash_view.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:takasly/services/ad_service.dart';

import 'package:upgrader/upgrader.dart';

import 'package:takasly/services/navigation_service.dart';
import 'package:takasly/widgets/custom_upgrade_dialog.dart';

class TakaslyUpgradeAlert extends UpgradeAlert {
  TakaslyUpgradeAlert({
    super.key,
    required super.upgrader,
    super.child,
    super.showIgnore = true,
    super.showLater = true,
    super.barrierDismissible = true,
  });

  @override
  UpgradeAlertState createState() => _TakaslyUpgradeAlertState();
}

class _TakaslyUpgradeAlertState extends UpgradeAlertState {
  @override
  void showTheDialog({
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool barrierDismissible,
    required UpgraderMessages messages,
    Key? key,
  }) {
    // If showIgnore or showLater is false, we treat it as mandatory
    final bool isMandatory = !widget.showIgnore || !widget.showLater;

    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomUpgradeDialog(
        upgrader: widget.upgrader,
        isMandatory: isMandatory,
      ),
    );
  }
}

class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  bool? _isOnboardingShown;
  bool _isDataLoaded = false;
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAppData();
    _initSharingIntent();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _initSharingIntent() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            if (value.isNotEmpty) {
              _handleSharedFiles(value);
            }
          },
          onError: (err) {
            debugPrint("getIntentDataStream error: $err");
          },
        );

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    final List<File> imageFiles = files
        .where((f) => f.type == SharedMediaType.image)
        .map((f) => File(f.path))
        .toList();

    if (imageFiles.isEmpty) return;

    // Navigate to AddProductView with these images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = NavigationService.navigatorKey?.currentState;
      if (state != null) {
        state.push(
          MaterialPageRoute(
            builder: (context) => AddProductView(initialImages: imageFiles),
          ),
        );
      }
    });
  }

  Future<void> _initializeAppData() async {
    // 0. Request App Tracking Transparency (ATT)
    try {
      // iPadOS/iOS requires the app to be in the 'active' state to show the ATT prompt.
      // If called too early (e.g., during Splash screen), the OS may ignore the request.
      await Future.delayed(const Duration(milliseconds: 2000));

      var status = await AppTrackingTransparency.trackingAuthorizationStatus;

      if (status == TrackingStatus.notDetermined) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }

      debugPrint("ATT Status after request: $status");
    } catch (e) {
      debugPrint("ATT Error: $e");
    }

    // Initialize AdService after ATT check
    await AdService().init();

    // 1. Check onboarding status
    final shown = await CacheService().isOnboardingShown();

    // 2. Wait for Auth Check
    final authVM = context.read<AuthViewModel>();
    while (!authVM.isAuthCheckComplete) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 3. Start pre-loading Home and Product data
    if (mounted) {
      final homeVM = context.read<HomeViewModel>();
      final productVM = context.read<ProductViewModel>();

      // Setup token first if authenticated
      if (authVM.user != null) {
        productVM.setUserToken(authVM.user?.token, refresh: false);
      }

      // Initialize Home Data (Categories, Logos, Popups) & Products in parallel
      await Future.wait([
        homeVM.init(isRefresh: true),
        productVM.fetchProducts(isRefresh: true),
      ]);

      // 4. Pre-cache popup images
      if (mounted) {
        for (final popup in homeVM.popups) {
          if (popup.popupImage != null && popup.popupImage!.isNotEmpty) {
            precacheImage(NetworkImage(popup.popupImage!), context);
          }
        }
      }
    }

    // Minimum delay for splash visibility (optional, keep it for smooth transition)
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isOnboardingShown = shown;
        _isDataLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (_isOnboardingShown == null ||
            !authViewModel.isAuthCheckComplete ||
            !_isDataLoaded) {
          return const SplashView();
        }

        if (!_isOnboardingShown!) {
          return const OnboardingView();
        }

        // Use our custom TakaslyUpgradeAlert to show a beautiful dialog
        return TakaslyUpgradeAlert(
          upgrader: Upgrader(
            languageCode: 'tr',
            messages: UpgraderMessages(code: 'tr'),
            durationUntilAlertAgain: const Duration(days: 3),
            debugLogging: true,
            debugDisplayAlways: false,
            minAppVersion: '2.0.0',
          ),
          showIgnore: false, // İptal etme butonunu kaldırır
          showLater: false, // Sonra hatırlat butonunu kaldırır
          barrierDismissible:
              false, // Dialog dışına tıklayarak kapatmayı engeller
          child: const HomeView(),
        );
      },
    );
  }
}
