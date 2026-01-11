import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'navigation_service.dart';
import '../views/home/home_view.dart';
import '../views/search/search_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/search_viewmodel.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();

  factory DeepLinkService() {
    return _instance;
  }

  DeepLinkService._internal();

  final _appLinks = AppLinks();

  /// Initialize Deep Link Service
  Future<void> init() async {
    // Check initial link (when app is closed)
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Initial Link Error: $e');
    }

    // Listen for new links (when app is in background/foreground)
    _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleLink(uri);
        }
      },
      onError: (err) {
        debugPrint('DeepLinkService: Stream Error: $err');
      },
    );
  }

  Future<void> _handleLink(Uri uri) async {
    debugPrint('=========== DEEP LINK DETECTED ===========');
    debugPrint('Full URI: $uri');
    debugPrint('Path Segments: ${uri.pathSegments}');
    debugPrint('==========================================');

    final pathSegments = uri.pathSegments;

    if (pathSegments.isEmpty) {
      _navigateToHome();
      return;
    }

    // Handle /ilan/... or /product/...
    bool isIlan = pathSegments.contains('ilan');
    bool isProduct = pathSegments.contains('product');

    if (isIlan || isProduct) {
      final lastSegment = pathSegments.last;
      String? potentialCode;

      // Extract the potential code part
      if (isProduct) {
        // Pattern: /product/123
        int productIndex = pathSegments.indexOf('product');
        if (productIndex + 1 < pathSegments.length) {
          potentialCode = pathSegments[productIndex + 1];
        } else {
          potentialCode = lastSegment;
        }
      } else {
        // Pattern: /ilan/slug-code
        final parts = lastSegment.split('-');
        if (parts.isNotEmpty) {
          // Try last part
          potentialCode = parts.last;
        }
      }

      if (potentialCode != null) {
        // User requested strategy:
        // Instead of fetching detail or ID, prepent "TKS-" and search.
        // Example: 49655458 -> Search "TKS-49655458"
        final String searchCode = 'TKS-$potentialCode';
        _navigateToSearch(searchCode);
        return;
      }

      // If we are here, we couldn't resolve a Code.
      // Fallback to Search
      _fallbackToSearch(pathSegments);
    } else {
      // Treat as search query
      final query = pathSegments.join(' ');
      if (query.isNotEmpty) {
        _navigateToSearch(query);
      } else {
        _navigateToHome();
      }
    }
  }

  void _fallbackToSearch(List<String> pathSegments) {
    final searchParts = List<String>.from(pathSegments)
      ..removeWhere((s) => s == 'ilan' || s == 'product');
    final query = searchParts.join(' ').replaceAll('-', ' ');

    if (query.isNotEmpty) {
      _navigateToSearch(query);
    } else {
      _navigateToHome();
    }
  }

  void _navigateToSearch(String query) {
    final context = NavigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => SearchViewModel(),
            child: SearchView(initialQuery: query),
          ),
        ),
      );
    }
  }

  void _navigateToHome() {
    final context = NavigationService.navigatorKey?.currentContext;
    if (context != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
        (route) => false,
      );
    }
  }
}
