import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/tickets/ticket_model.dart';
import '../services/ticket_service.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';
import '../services/account_service.dart';
import '../models/user/report_user_model.dart';
import '../models/account/blocked_user_model.dart';

class TicketViewModel extends ChangeNotifier {
  final TicketService _ticketService = TicketService();
  final ProductService _productService = ProductService();
  final AccountService _accountService = AccountService();
  final Logger _logger = Logger();

  List<Ticket> tickets = [];
  bool isLoading = false;
  bool isLoadMoreRunning = false;
  bool isLastPage = false;
  int currentPage = 1;
  String? errorMessage;
  String? emptyMessage;

  // Chat/Messages State
  List<TicketMessage> messages = [];
  bool isMessageLoading = false;
  bool isMessageLastPage = false;
  int currentMessagePage = 1;
  String? messageErrorMessage;

  // Ticket Detail State (For Chat Banner Context)
  TicketDetailData? currentTicketDetail;
  bool isDetailLoading = false;
  String? detailErrorMessage;

  Future<void> fetchTickets(String userToken, {bool isRefresh = false}) async {
    if (isLoading) return;
    if (isLoadMoreRunning) return;
    if (isLastPage && !isRefresh) return;

    if (isRefresh) {
      isLoading = true;
      isLastPage = false;
      currentPage = 1;
      errorMessage = null;
      tickets.clear();
      notifyListeners();
    } else {
      isLoadMoreRunning = true;
      notifyListeners();
    }

    try {
      final response = await _ticketService.getUserTickets(
        currentPage,
        userToken,
      );

      if (response.success == true && response.data != null) {
        final newTickets = response.data!.tickets ?? [];

        if (isRefresh) {
          tickets = newTickets;
          emptyMessage = response.data!.emptyMessage;
        } else {
          tickets.addAll(newTickets);
        }

        // Pagination Logic
        if (newTickets.isEmpty) {
          isLastPage = true;
        } else {
          // If totalPages is available, use it. Otherwise rely on 410 or empty list.
          if (response.data!.totalPages != null) {
            if (currentPage >= response.data!.totalPages!) {
              isLastPage = true;
            } else {
              currentPage++;
            }
          } else {
            // Fallback if totalPages is not reliable or missing
            if (response.data!.hasNextPage == false) {
              isLastPage = true;
            } else {
              currentPage++;
            }
          }
        }
      } else {
        errorMessage = response.message ?? "Mesajlar yüklenemedi.";
      }
    } catch (e) {
      if (e is EndOfListException) {
        _logger.i("Ticket listesi sonuna gelindi (410).");
        isLastPage = true;
      } else {
        errorMessage = "Bir hata oluştu: $e";
        _logger.e("Hata oluştu", error: e);
      }
    } finally {
      isLoading = false;
      isLoadMoreRunning = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(
    int ticketID,
    String userToken, {
    bool isRefresh = false,
    bool isSilent = false,
  }) async {
    if (isMessageLoading) return;
    if (isMessageLastPage && !isRefresh) return;

    if (isRefresh) {
      if (!isSilent) {
        isMessageLoading = true;
        notifyListeners();
      }
      isMessageLastPage = false;
      currentMessagePage = 1;
      messageErrorMessage = null;
      // Do not clear messages immediately if silent, to avoid flicker
      if (!isSilent) {
        messages.clear();
      }
    } else {
      isMessageLoading = true;
      notifyListeners();
    }

    try {
      final response = await _ticketService.getTicketMessages(
        ticketID,
        currentMessagePage,
        userToken,
      );

      if (response.success == true && response.data != null) {
        final newMessages = response.data!.messages ?? [];

        if (isRefresh) {
          messages = newMessages;
        } else {
          messages.addAll(newMessages);
        }

        if (newMessages.isEmpty) {
          isMessageLastPage = true;
        } else {
          if (response.data!.totalPages != null) {
            if (currentMessagePage >= response.data!.totalPages!) {
              isMessageLastPage = true;
            } else {
              currentMessagePage++;
            }
          } else {
            if (response.data!.hasNextPage == false) {
              isMessageLastPage = true;
            } else {
              currentMessagePage++;
            }
          }
        }
      } else {
        messageErrorMessage = response.message ?? "Mesajlar yüklenemedi.";
      }
    } catch (e) {
      if (e is EndOfListException) {
        _logger.i("Mesaj listesi sonuna gelindi (410).");
        isMessageLastPage = true;
      } else {
        messageErrorMessage = "Bir hata oluştu: $e";
        _logger.e("Mesaj Hata", error: e);
      }
    } finally {
      if (!isSilent) {
        isMessageLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchTicketDetail(int ticketID, String userToken) async {
    isDetailLoading = true;
    detailErrorMessage = null;
    notifyListeners();

    try {
      final response = await _ticketService.getTicketDetail(
        ticketID,
        userToken,
      );
      if (response.success == true && response.data != null) {
        currentTicketDetail = response.data;
      } else {
        detailErrorMessage = response.message ?? "Detay yüklenemedi";
      }
    } catch (e) {
      detailErrorMessage = "Bir hata oluştu: $e";
      _logger.e("Ticket Detail Hata", error: e);
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  // Send Message State
  bool isSendingMessage = false;

  Future<bool> sendMessage(
    int ticketID,
    String userToken,
    String message,
  ) async {
    if (isSendingMessage) return false;

    isSendingMessage = true;
    notifyListeners();

    try {
      final success = await _ticketService.sendMessage(
        userToken,
        ticketID,
        message,
      );
      if (success) {
        // Option A: Refresh messages list
        await fetchMessages(ticketID, userToken, isRefresh: true);

        // Option B: Optimistically append message (Requires creating a TicketMessage object)
        // For now, refreshing is safer to ensure we get the full server-side object (like ID, timestamp)
        return true;
      } else {
        messageErrorMessage = "Mesaj gönderilemedi.";
        return false;
      }
    } catch (e) {
      messageErrorMessage = "Mesaj gönderilirken hata: $e";
      _logger.e("Send Message Error", error: e);
      return false;
    } finally {
      isSendingMessage = false;
      notifyListeners();
    }
  }

  Future<int?> createTicket(
    String userToken,
    int targetProductID,
    int offeredProductID,
    String message,
  ) async {
    isSendingMessage = true;
    notifyListeners();

    try {
      final response = await _ticketService.createTicket(
        userToken,
        targetProductID,
        offeredProductID,
        message,
      );

      if (response['success'] == true) {
        // Assuming the response data contains the new ticketID or we can just return true/false
        // Typical structure: data: { ticketID: 123 }
        // Let's print response to be sure in dev, but code safely
        if (response['data'] != null && response['data']['ticketID'] != null) {
          return int.tryParse(response['data']['ticketID'].toString());
        }
        return 1; // Return a dummy success if ID is missing but success is true (fallback)
      } else {
        messageErrorMessage = response['message'] ?? "Teklif oluşturulamadı.";
        return null;
      }
    } catch (e) {
      messageErrorMessage = "Teklif oluşturulurken hata: $e";
      _logger.e("Create Ticket Error", error: e);
      return null;
    } finally {
      isSendingMessage = false;
      notifyListeners();
    }
  }

  Future<bool> reportUser({
    required String userToken,
    required int reportedUserID,
    required String reason,
    required String step,
    int? productID,
    int? offerID,
  }) async {
    try {
      final request = ReportUserRequest(
        userToken: userToken,
        reportedUserID: reportedUserID,
        reason: reason,
        step: step,
        productID: productID,
        offerID: offerID,
      );
      await _productService.reportUser(request);
      return true;
    } catch (e) {
      _logger.e("Report User Hata", error: e);
      return false;
    }
  }

  Future<bool> blockUser({
    required String userToken,
    required int blockedUserID,
    String? reason,
  }) async {
    try {
      final request = BlockedUserRequest(
        userToken: userToken,
        blockedUserID: blockedUserID,
        reason: reason,
      );
      await _accountService.blockUser(request);
      return true;
    } catch (e) {
      _logger.e("Block User Hata", error: e);
      return false;
    }
  }
}
