import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takasly/services/cache_service.dart';
import 'package:takasly/viewmodels/auth_viewmodel.dart';
import 'package:takasly/views/home/home_view.dart';
import 'package:takasly/views/onboarding/onboarding_view.dart';
import 'package:takasly/views/splash/splash_view.dart';

class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  bool? _isOnboardingShown;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // Check onboarding status
    final shown = await CacheService().isOnboardingShown();

    // Minimum delay for splash visibility (remove after testing if desired)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isOnboardingShown = shown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (_isOnboardingShown == null || !authViewModel.isAuthCheckComplete) {
          return const SplashView();
        }

        if (!_isOnboardingShown!) {
          return const OnboardingView();
        }

        return const HomeView();
      },
    );
  }
}
