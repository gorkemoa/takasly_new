import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../views/messages/chat_view.dart';
import '../views/products/product_detail_view.dart';
import '../views/profile/trade_detail_view.dart';
import '../models/tickets/ticket_model.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ticket_viewmodel.dart';

/// Navigation Service - Push bildirimi ve deep link navigasyonları için
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Global Navigator Key - main.dart'tan set edilir
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Deep link navigasyonunu handle eder
  ///
  /// Desteklenen tipler:
  /// - new_ticket_message: Mesaj detayına yönlendirir
  /// - sponsor_expired: İlan detayına yönlendirir
  /// - trade_offer_approved: Takas detayına yönlendirir
  /// - new_trade_offer: Takas detayına yönlendirir
  ///
  /// typeId -1 veya 0 ise ve url varsa, url'e yönlendirir
  void handleDeepLink({
    required String type,
    required int typeId,
    String? url,
    String? title,
  }) {
    debugPrint('🚀 NavigationService: type=$type, typeId=$typeId, url=$url');

    // typeId -1 veya 0 ise ve url varsa, harici URL'e yönlendir
    if ((typeId == -1 || typeId == 0) && url != null && url.isNotEmpty) {
      _launchUrl(url);
      return;
    }

    final context = navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('❌ NavigationService: Navigator context bulunamadı');
      return;
    }

    debugPrint('🚀 NavigationService: Navigating to $type with ID: $typeId');

    switch (type) {
      case 'new_ticket_message':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => TicketViewModel(),
              child: ChatView(
                ticket: Ticket(ticketID: typeId, otherFullname: title),
              ),
            ),
          ),
        );
        break;
      case 'sponsor_expired':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(productId: typeId),
          ),
        );
        break;
      case 'trade_offer_approved':
      case 'new_trade_offer':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TradeDetailView(offerId: typeId),
          ),
        );
        break;
      default:
        // Bilinmeyen tip ama url varsa, url'e yönlendir
        if (url != null && url.isNotEmpty) {
          _launchUrl(url);
        } else {
          debugPrint('⚠️ NavigationService: Bilinmeyen tip: $type');
        }
        break;
    }
  }

  static void pushAndRemoveUntil(Widget page) {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );
    }
  }

  /// Harici URL'i aç
  Future<void> _launchUrl(String url) async {
    debugPrint('🌐 NavigationService: Opening URL: $url');
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('❌ NavigationService: URL açılamadı: $url');
      }
    } catch (e) {
      debugPrint('❌ NavigationService: URL açılırken hata: $e');
    }
  }
}
