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
    _logger.i('POST İsteği: $url\nBaşlıklar: $_headers\nGövde: $body');

    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      _logger.d(
        'Yanıt Durumu: ${response.statusCode}\nGövde: ${response.body}',
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      _logger.e('Ağ Hatası (Bağlantı Hatası): $e');
      throw Exception('Ağ hatası: Lütfen bağlantınızı kontrol edin. $e');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    _logger.i('GET İsteği: $url\nBaşlıklar: $_headers');

    try {
      final response = await _client.get(url, headers: _headers);

      _logger.d(
        'Yanıt Durumu: ${response.statusCode}\nGövde: ${response.body}',
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      _logger.e('Ağ Hatası (Bağlantı Hatası): $e');
      throw Exception('Ağ hatası: Lütfen bağlantınızı kontrol edin. $e');
    } catch (e) {
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      _logger.w('Boş Yanıt Gövdesi');
      throw Exception('Empty response');
    }

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 417) {
      // İş mantığı hatası
      _logger.w('İş Mantığı Hatası (417): ${body['message']}');
      throw BusinessException(body['message'] ?? 'Bir hata oluştu');
    } else if (response.statusCode == 410) {
      // Listenin sonu / Kaynak artık yok
      // Eğer body içerisinde data varsa, bunu son sayfa olarak kabul edip veriyi döndürmeliyiz
      if (body['success'] == true && body['data'] != null) {
        _logger.i('Listenin Sonu (410) - Son verilerle birlikte.');
        return body;
      }
      _logger.i('Listenin Sonu (410)');
      throw EndOfListException('Son sayfa');
    } else {
      _logger.e(
        'HTTP Hatası ${response.statusCode}: ${body['message'] ?? response.reasonPhrase}',
      );
      throw Exception(
        'HTTP Error ${response.statusCode}: ${body['message'] ?? response.reasonPhrase}',
      );
    }
  }

  Future<Map<String, dynamic>> getLogos() async {
    try {
      final response = await get('service/general/general/logos');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await get('service/general/general/categories/0');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNotifications(int userId) async {
    try {
      final response = await get('service/user/account/$userId/notifications');
      return response;
    } catch (e) {
      rethrow;
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
