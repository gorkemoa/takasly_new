import 'package:flutter/material.dart';
import '../models/events/event_model.dart';
import '../services/event_service.dart';
import 'package:logger/logger.dart';

class EventViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();
  final Logger _logger = Logger();

  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  EventModel? _selectedEvent;
  EventModel? get selectedEvent => _selectedEvent;

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventService.getEvents();
    } catch (e) {
      _logger.e('Error fetching events: $e');
      _errorMessage = 'Etkinlikler yüklenirken bir hata oluştu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEventDetail(int eventId) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedEvent = null; // Clear previous selection
    notifyListeners();

    try {
      _selectedEvent = await _eventService.getEventDetail(eventId);
    } catch (e) {
      _logger.e('Error fetching event detail: $e');
      _errorMessage = 'Etkinlik detayı yüklenirken bir hata oluştu.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
