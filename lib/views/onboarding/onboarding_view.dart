import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:takasly/models/onboarding/source_models.dart';
import 'package:takasly/services/cache_service.dart';
import 'package:takasly/services/general_service.dart';
import 'package:takasly/services/navigation_service.dart';
import 'package:takasly/theme/app_theme.dart';
import 'package:takasly/views/home/home_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _images = [
    'assets/onboarding/1.png',
    'assets/onboarding/2.png',
    'assets/onboarding/3.png',
  ];

  List<OnboardingSource> _sources = [];
  bool _isLoadingSources = true;
  int? _selectedSourceId;

  @override
  void initState() {
    super.initState();
    _fetchSources();
  }

  Future<void> _fetchSources() async {
    final sources = await GeneralService().getSourcesTypes();
    if (mounted) {
      setState(() {
        _sources = sources;
        _isLoadingSources = false;
      });
    }
  }

  void _onFinish() async {
    if (_selectedSourceId != null) {
      await _submitSource();
    }
    await CacheService().setOnboardingShown();
    if (mounted) {
      NavigationService.pushAndRemoveUntil(const HomeView());
    }
  }

  Future<void> _submitSource() async {
    final selected = _sources.firstWhere(
      (s) => s.sourceID == _selectedSourceId,
    );
    final deviceInfo = DeviceInfoPlugin();
    String userAgent = "Unknown Device";
    String platform = Platform.isAndroid ? "android" : "ios";

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        userAgent = "${androidInfo.brand} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        userAgent = iosInfo.name;
      }
    } catch (_) {}

    await GeneralService().addSource(
      AddSourceRequestModel(
        sourceTypeID: selected.sourceID,
        sourceType: selected.sourceTitle,
        platform: platform,
        userAgent: userAgent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length + 1,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              if (index < _images.length) {
                return SizedBox.expand(
                  child: Image.asset(_images[index], fit: BoxFit.cover),
                );
              } else {
                return _buildSourceSelectionPage();
              }
            },
          ),
          // Subtle Indicators
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _images.length + 1,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: _currentPage == index ? 20 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == _images.length
                            ? AppTheme.primary.withOpacity(0.8)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_currentPage == _images.length)
                  const SizedBox.shrink() // Button is inside selection page
                else if (_currentPage == _images.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Devam Et',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Text(
                            'İleri',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSelectionPage() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.stars_rounded, size: 64, color: AppTheme.primary),
          const SizedBox(height: 24),
          const Text(
            'Sizinle Büyüyoruz ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Takasly topluluğuna nasıl ulaştığınızı merak ediyoruz. Bu küçük bilgiyle bize en büyük desteği vermiş olacaksınız.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: _isLoadingSources
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _sources.map((source) {
                        final isSelected = _selectedSourceId == source.sourceID;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSourceId = source.sourceID;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              source.sourceTitle,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: ElevatedButton(
              onPressed: _onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _selectedSourceId == null ? 'Atla ve Başla' : 'Kaydet ve Başla',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
