import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  final Logger _logger = Logger();

  AnalyticsService._internal() {
    if (kDebugMode) {
      _logger.i('AnalyticsService initialized');
      logEvent('debug_init', parameters: {'status': 'active'});
    }
  }

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      final Map<String, Object> finalParams = Map.from(parameters ?? {});
      finalParams['screen_name'] = _currentScreenName;
      finalParams['timestamp'] = DateTime.now().toIso8601String();
      // user_id is automatically attached by Firebase if setUserId was called,
      // but we can't easily add it here without dependency injection which might break singleton pattern or cause circular deps.

      await _analytics.logEvent(name: name, parameters: finalParams);
      if (kDebugMode) {
        _logger.d('Analytics Event Logged: $name, params: $finalParams');
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Failed to log analytics event: $e');
      }
    }
  }

  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setCurrentScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // --- STANDARD EVENTS ---

  String _currentScreenName = 'Unknown';

  String get currentScreenName => _currentScreenName;

  Future<void> logScreenView(String screenName) async {
    _currentScreenName = screenName;
    try {
      await _analytics.logScreenView(screenName: screenName);
      if (kDebugMode) {
        _logger.d('Analytics Screen View: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Failed to log screen view: $e');
      }
    }
  }

  Future<void> logLogin(String method) async {
    await logEvent('login', parameters: {'method': method});
  }

  Future<void> logSignUp(String method) async {
    await logEvent('sign_up', parameters: {'method': method});
  }

  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    required String itemCategory,
  }) async {
    await _analytics.logViewItem(
      currency: 'TRY',
      value: 0,
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: itemCategory,
        ),
      ],
    );
    if (kDebugMode) {
      _logger.d('Analytics View Item: $itemName ($itemId)');
    }
  }

  Future<void> logAddToWishlist({
    required String itemId,
    required String itemCategory,
  }) async {
    await _analytics.logAddToWishlist(
      currency: 'TRY',
      value: 0,
      items: [AnalyticsEventItem(itemId: itemId, itemCategory: itemCategory)],
    );
    if (kDebugMode) {
      _logger.d('Analytics Add to Wishlist: $itemId');
    }
  }

  Future<void> logSearch({
    required String searchTerm,
    String? category,
    int? resultCount,
    String? origin,
  }) async {
    // manual logEvent to include custom parameters like category and result_count
    // which are not available in the standard logSearch helper for non-travel apps.
    await logEvent(
      'search',
      parameters: {
        'search_term': searchTerm,
        if (category != null) 'category_name': category,
        if (resultCount != null) 'result_count': resultCount,
        if (origin != null) 'origin': origin,
      },
    );
  }

  // --- GRANULAR INTERACTION EVENTS ---

  Future<void> logTap({
    required String screenName,
    required double x,
    required double y,
  }) async {
    // We use a custom event for taps
    await logEvent(
      'interaction_tap',
      parameters: {
        'screen_name': screenName,
        'x': x,
        'y': y,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logScroll({
    required String screenName,
    required String direction,
  }) async {
    // We use a custom event for scrolls
    await logEvent(
      'interaction_scroll',
      parameters: {
        'screen_name': screenName,
        'direction': direction,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
