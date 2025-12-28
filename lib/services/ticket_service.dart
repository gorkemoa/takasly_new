import '../core/constants/api_constants.dart';
import '../models/tickets/ticket_model.dart';
import 'api_service.dart';

class TicketService {
  final ApiService _apiService = ApiService();

  Future<TicketListResponse> getUserTickets(int page, String userToken) async {
    try {
      final String url =
          '${ApiConstants.userTickets}?userToken=$userToken&page=$page';
      final response = await _apiService.get(url);
      return TicketListResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TicketMessagesResponse> getTicketMessages(
    int ticketID,
    int page,
    String userToken,
  ) async {
    try {
      final String url =
          '${ApiConstants.ticketMessages}?userToken=$userToken&ticketID=$ticketID&page=$page';
      final response = await _apiService.get(url);
      return TicketMessagesResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TicketDetailResponse> getTicketDetail(
    int ticketID,
    String userToken,
  ) async {
    try {
      final String url =
          '${ApiConstants.ticketDetail}?userToken=$userToken&ticketID=$ticketID';
      final response = await _apiService.get(url);
      return TicketDetailResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sendMessage(
    String userToken,
    int ticketID,
    String message,
  ) async {
    try {
      final response = await _apiService.post(ApiConstants.addMessage, {
        'userToken': userToken,
        'ticketID': ticketID,
        'message': message,
      });

      print('Send Message Response: $response'); // Debug logging
      final success = response['success'];
      return success == 1 || success == '1' || success == true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createTicket(
    String userToken,
    int targetProductID,
    int offeredProductID,
    String message,
  ) async {
    try {
      final response = await _apiService
          .post('service/user/account/tickets/create', {
            'userToken': userToken,
            'targetProductID': targetProductID,
            'offeredProductID': offeredProductID,
            'message': message,
          });
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
