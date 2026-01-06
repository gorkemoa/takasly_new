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
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
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

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    _logger.i('PUT İsteği: $url\nBaşlıklar: $_headers\nGövde: $body');

    try {
      final response = await _client.put(
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

  // Callback for 403 errors
  Function? onForbidden;

  dynamic _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      _logger.w('Boş Yanıt Gövdesi');
      throw Exception('Empty response');
    }

    final body = jsonDecode(response.body);

    // Helper to extract error message
    String? getErrorMessage() {
      return body['error_message'] ?? body['message'];
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Check if the response body itself indicates an error despite 200 OK
      if (body is Map && body['error'] == true) {
        final errorMsg = getErrorMessage() ?? 'Bir hata oluştu';
        _logger.w('İş Mantığı Hatası (Success False): $errorMsg');
        throw BusinessException(errorMsg);
      }
      return body;
    } else if (response.statusCode == 403) {
      _logger.w('Erişim Reddedildi (403). Oturum sonlandırılıyor.');
      onForbidden?.call();
      throw Exception('Oturum süresi doldu veya yetkisiz erişim.');
    } else if (response.statusCode == 400 || response.statusCode == 417) {
      // İş mantığı / Valide hatası
      final errorMsg = getErrorMessage() ?? 'İstek hatası oluştu';
      _logger.w('İş Mantığı Hatası (${response.statusCode}): $errorMsg');
      throw BusinessException(errorMsg);
    } else if (response.statusCode == 410) {
      // Listenin sonu / Kaynak artık yok
      if (body['success'] == true && body['data'] != null) {
        _logger.i('Listenin Sonu (410) - Son verilerle birlikte.');
        return body;
      }
      _logger.i('Listenin Sonu (410)');
      throw EndOfListException('Son sayfa');
    } else {
      final errorMsg = getErrorMessage() ?? response.reasonPhrase;
      _logger.e('HTTP Hatası ${response.statusCode}: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  Future<dynamic> delete(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    _logger.i('DELETE İsteği: $url\nBaşlıklar: $_headers\nGövde: $body');

    try {
      final request = http.Request('DELETE', url);
      request.headers.addAll(_headers);
      request.body = jsonEncode(body);

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

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

  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    _logger.i(
      'POST Multipart İsteği: $url\nFields: $fields\nFiles: ${files?.map((e) => e.filename).toList()}',
    );

    try {
      final request = http.MultipartRequest('POST', url);

      // Add headers (excluding Content-Type as MultipartRequest sets it automatically)
      final headers = _headers;
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

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
