import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

import 'package:logger/logger.dart';

class ApiService {
  // Singleton pattern (optional, but good for managing client)
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // Headers
  Map<String, String> get _headers {
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('${ApiConstants.apiUser}:${ApiConstants.apiPassword}'))}';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': basicAuth,
    };
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    _logger.i('POST Request to: $url\nHeaders: $_headers\nBody: $body');

    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      _logger.d(
        'Response Status: ${response.statusCode}\nBody: ${response.body}',
      );
      return _handleResponse(response);
    } catch (e) {
      _logger.e('Network Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    _logger.i('GET Request to: $url\nHeaders: $_headers');

    try {
      final response = await _client.get(url, headers: _headers);

      _logger.d(
        'Response Status: ${response.statusCode}\nBody: ${response.body}',
      );
      return _handleResponse(response);
    } catch (e) {
      _logger.e('Network Error: $e');
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      _logger.w('Empty Response Body');
      throw Exception('Empty response');
    }

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 417) {
      // Business logic error
      _logger.w('Business Error (417): ${body['message']}');
      throw BusinessException(body['message'] ?? 'Bir hata oluştu');
    } else if (response.statusCode == 410) {
      // Resource gone / Last page
      // In the context of pagination, this might be handled by the caller or we can throw specific exception
      _logger.i('End of List (410)');
      throw EndOfListException('Son sayfa');
    } else {
      _logger.e(
        'HTTP Error ${response.statusCode}: ${body['message'] ?? response.reasonPhrase}',
      );
      throw Exception(
        'HTTP Error ${response.statusCode}: ${body['message'] ?? response.reasonPhrase}',
      );
    }
  }
}

class BusinessException implements Exception {
  final String message;
  BusinessException(this.message);
  @override
  String toString() => message;
}

class EndOfListException implements Exception {
  final String message;
  EndOfListException(this.message);
  @override
  String toString() => message;
}
