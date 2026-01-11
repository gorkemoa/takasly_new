import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class InAppReviewService {
  static final InAppReviewService _instance = InAppReviewService._internal();
  factory InAppReviewService() => _instance;
  InAppReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;
  final Logger _logger = Logger();

  static const String _keyLastRequestDate = 'in_app_review_last_request_date';
  static const String _keyActionCount = 'in_app_review_action_count';
  static const String _keyFirstOpenDate = 'in_app_review_first_open_date';

  /// Call this when the app starts
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_keyFirstOpenDate) == null) {
      await prefs.setString(
        _keyFirstOpenDate,
        DateTime.now().toIso8601String(),
      );
    }
  }

  /// Increments action count and checks if it's time to show the review dialog
  Future<void> incrementActionAndCheck() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_keyActionCount) ?? 0;
    count++;
    await prefs.setInt(_keyActionCount, count);

    _logger.i('InAppReview: Action count incremented to $count');

    // Conditions:
    // 1. Minimum 1 high-value action (successful trade, offer, or listing)
    // 2. Minimum 1 day since first open
    // 3. Minimum 15 days since last request (native limits apply anyway)

    if (await _shouldRequestReview()) {
      await requestReview();
    }
  }

  Future<bool> _shouldRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Action count check
    int count = prefs.getInt(_keyActionCount) ?? 0;
    if (count < 1) return false;

    // 2. Time since first open check (at least 1 day)
    String? firstOpenStr = prefs.getString(_keyFirstOpenDate);
    if (firstOpenStr != null) {
      DateTime firstOpen = DateTime.parse(firstOpenStr);
      if (DateTime.now().difference(firstOpen).inDays < 1) return false;
    }

    // 3. Time since last request check (at least 15 days)
    String? lastRequestStr = prefs.getString(_keyLastRequestDate);
    if (lastRequestStr != null) {
      DateTime lastRequest = DateTime.parse(lastRequestStr);
      if (DateTime.now().difference(lastRequest).inDays < 15) return false;
    }

    return true;
  }

  Future<void> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        _logger.i('InAppReview: Requesting review');
        await _inAppReview.requestReview();

        // Update last request date
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _keyLastRequestDate,
          DateTime.now().toIso8601String(),
        );
        // Reset action count (optional, but good to reset the cycle)
        await prefs.setInt(_keyActionCount, 0);
      } else {
        _logger.w('InAppReview: Native review dialog not available');
      }
    } catch (e) {
      _logger.e('InAppReview: Error requesting review', error: e);
    }
  }

  /// Force open store for rating (fallback or manual button)
  Future<void> openStoreListing() async {
    await _inAppReview.openStoreListing(
      appStoreId: '6523423714', // Replace with actual App Store ID
    );
  }
}
