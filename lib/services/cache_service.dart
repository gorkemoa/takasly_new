import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/products/product_models.dart';

class CacheService {
  static const String _categoriesKey = 'cached_categories';
  static const String _categoriesTimeKey = 'cached_categories_time';

  // Cache duration: 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);

  Future<void> saveCategories(List<Category> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        categories.map((c) => c.toJson()).toList(),
      );
      await prefs.setString(_categoriesKey, encoded);
      await prefs.setInt(
        _categoriesTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Ignore cache saving errors
    }
  }

  Future<List<Category>?> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encoded = prefs.getString(_categoriesKey);
      final int? time = prefs.getInt(_categoriesTimeKey);

      if (encoded == null || time == null) return null;

      // Check if expired (Optional: if we want strict expiration)
      final DateTime savedTime = DateTime.fromMillisecondsSinceEpoch(time);
      if (DateTime.now().difference(savedTime) > _cacheDuration) {
        // We can still return it but maybe mark as stale?
        // For now let's just return it and let ViewModel decide.
      }

      final List decoded = jsonDecode(encoded);
      return decoded.map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<int?> getCategoriesTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_categoriesTimeKey);
  }

  static const String _hiddenPopupsKey = 'hidden_popups';

  Future<void> saveHiddenPopup(int popupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> hidden = prefs.getStringList(_hiddenPopupsKey) ?? [];
      if (!hidden.contains(popupId.toString())) {
        hidden.add(popupId.toString());
        await prefs.setStringList(_hiddenPopupsKey, hidden);
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<List<int>> getHiddenPopups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> hidden = prefs.getStringList(_hiddenPopupsKey) ?? [];
      return hidden.map((e) => int.parse(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static const String _onboardingKey = 'onboarding_shown';

  Future<bool> isOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static const String _notificationPromptKey = 'notification_prompt_shown';

  Future<bool> isNotificationPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationPromptKey) ?? false;
  }

  Future<void> setNotificationPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPromptKey, true);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_categoriesKey);
    await prefs.remove(_categoriesTimeKey);
    // Don't clear hidden popups on general cache clear usually
  }
}
