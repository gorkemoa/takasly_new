import '../core/constants/api_constants.dart';
import '../models/events/event_model.dart';
import 'api_service.dart';

class EventService {
  final ApiService _apiService = ApiService();

  Future<List<EventModel>> getEvents() async {
    try {
      final response = await _apiService.get(ApiConstants.events);
      if (response['success'] == true &&
          response['data'] != null &&
          response['data']['events'] != null) {
        return (response['data']['events'] as List)
            .map((e) => EventModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<EventModel> getEventDetail(int eventId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.eventDetail}$eventId/detail',
      );
      if (response['success'] == true &&
          response['data'] != null &&
          response['data']['event'] != null) {
        return EventModel.fromJson(response['data']['event']);
      }
      throw Exception('Event detail not found');
    } catch (e) {
      rethrow;
    }
  }
}
