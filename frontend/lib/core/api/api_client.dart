import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final dynamic details;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => message;
}

/// One place for backend URLs, auth headers, timeouts, and API error parsing.
class ApiClient {
  final http.Client _client;
  String? _authToken;
  Future<void> Function()? onUnauthorized;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  String get effectiveBaseUrl {
    final configured = AppConfig.apiBaseUrl;
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        configured.contains('localhost')) {
      return configured.replaceFirst('localhost', '10.0.2.2');
    }
    return configured.replaceFirst(RegExp(r'/$'), '');
  }

  String? get authToken => _authToken;
  void setAuthToken(String token) => _authToken = token;
  void clearAuthToken() => _authToken = null;
  void dispose() => _client.close();

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (_authToken != null && _authToken!.isNotEmpty)
      'Authorization': 'Bearer $_authToken',
  };

  Future<Map<String, dynamic>> login(
    String phoneNumber, {
    required String password,
  }) async {
    final result = await _post('/auth/login', {
      'phone_number': phoneNumber,
      'password': password,
    });
    final token = result['access_token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        statusCode: 502,
        message: 'The server returned an invalid session.',
      );
    }
    setAuthToken(token);
    return result;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> profileData) =>
      _post('/auth/register', profileData);

  Future<Map<String, dynamic>> getMe() => _getMap('/auth/me');

  Future<Map<String, dynamic>> getProfile(String phoneNumber) =>
      _getMap('/auth/profile/${Uri.encodeComponent(phoneNumber)}');

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      _put('/farm-profiles/me', data);

  Future<List<dynamic>> getFarms([String? unusedFarmerId]) =>
      _getList('/farms');

  Future<Map<String, dynamic>> createFarm(Map<String, dynamic> farmData) =>
      _post('/farms', farmData);

  Future<Map<String, dynamic>> updateFarm(
    String farmId,
    Map<String, dynamic> farmData,
  ) => _put('/farms/${Uri.encodeComponent(farmId)}', farmData);

  Future<void> deleteFarm(String farmId) async =>
      _delete('/farms/${Uri.encodeComponent(farmId)}');

  Future<List<dynamic>> getCropCycles(
    String farmId, {
    int skip = 0,
    int limit = 50,
  }) => _getList(
    '/crop-cycles/farm/${Uri.encodeComponent(farmId)}?skip=$skip&limit=$limit',
  );

  Future<Map<String, dynamic>> createCropCycle(Map<String, dynamic> data) =>
      _post('/crop-cycles', data);

  Future<Map<String, dynamic>> updateCropCycle(
    String cycleId,
    Map<String, dynamic> data,
  ) => _patch('/crop-cycles/${Uri.encodeComponent(cycleId)}', data);

  Future<void> deleteCropCycle(String cycleId) async =>
      _delete('/crop-cycles/${Uri.encodeComponent(cycleId)}');

  Future<List<dynamic>> getFarmObservations(
    String cycleId, {
    int skip = 0,
    int limit = 50,
  }) => _getList(
    '/farm-observations/crop-cycle/${Uri.encodeComponent(cycleId)}?skip=$skip&limit=$limit',
  );

  Future<Map<String, dynamic>> createFarmObservation(
    String cycleId,
    Map<String, dynamic> data,
  ) => _post(
    '/farm-observations/crop-cycle/${Uri.encodeComponent(cycleId)}',
    data,
  );

  Future<Map<String, dynamic>> updateFarmObservation(
    String observationId,
    Map<String, dynamic> data,
  ) => _patch('/farm-observations/${Uri.encodeComponent(observationId)}', data);

  Future<void> deleteFarmObservation(String observationId) async =>
      _delete('/farm-observations/${Uri.encodeComponent(observationId)}');

  Future<Map<String, dynamic>> getWeather(String district) =>
      _getMap('/weather/${Uri.encodeComponent(district)}');

  Future<List<dynamic>> getCropRecommendations(String farmId) =>
      _getList('/crop-recommendations/${Uri.encodeComponent(farmId)}');

  Future<List<dynamic>> evaluateCropRecommendations(
    Map<String, dynamic> payload,
  ) => _postList('/crop-recommendations/evaluate', payload);

  Future<Map<String, dynamic>> calculateYield(Map<String, dynamic> payload) =>
      _post('/yield-estimates/calculate', payload);

  Future<List<dynamic>> getYieldHistory({int skip = 0, int limit = 20}) =>
      _getList('/yield-estimates/history?skip=$skip&limit=$limit');

  Future<Map<String, dynamic>> diagnoseCrop({
    required List<int> imageBytes,
    required String fileName,
    required String mimeType,
    required String cropName,
  }) async {
    final uri = Uri.parse('$effectiveBaseUrl/crop-health/diagnose-image');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['crop_name'] = cropName
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      await _throwIfError(response);
      return _asMap(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        statusCode: 0,
        message:
            'Could not reach the AgriVerse backend. Check your connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> queryAssistant(
    String query,
    String lang,
    bool simpleMode, {
    String? conversationId,
  }) => _post('/farm-assistant/query', {
    'query': query,
    'language': lang,
    'simple_mode': simpleMode,
    'conversation_id': ?conversationId,
  });

  Future<List<dynamic>> getAssistantConversations({
    int skip = 0,
    int limit = 20,
  }) => _getList('/farm-assistant/conversations?skip=$skip&limit=$limit');

  Future<Map<String, dynamic>> getAssistantConversation(String id) =>
      _getMap('/farm-assistant/conversations/${Uri.encodeComponent(id)}');

  Future<List<dynamic>> getDiagnosisHistory({int skip = 0, int limit = 20}) =>
      _getList('/crop-health/history?skip=$skip&limit=$limit');

  Future<Map<String, dynamic>> scheduleIrrigation(
    Map<String, dynamic> payload,
  ) => _post('/irrigation/schedule', payload);

  Future<Map<String, dynamic>> _getMap(String path) async =>
      _asMap(await _request('GET', path));

  Future<List<dynamic>> _getList(String path) async =>
      _asList(await _request('GET', path));

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async => _asMap(await _request('POST', path, body: body));

  Future<List<dynamic>> _postList(
    String path,
    Map<String, dynamic> body,
  ) async => _asList(await _request('POST', path, body: body));

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async => _asMap(await _request('PUT', path, body: body));

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async => _asMap(await _request('PATCH', path, body: body));

  Future<void> _delete(String path) async {
    await _request('DELETE', path, expectJson: false);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool expectJson = true,
  }) async {
    final uri = Uri.parse('$effectiveBaseUrl$path');
    try {
      late http.Response response;
      final headers = <String, String>{
        ..._headers,
        if (body != null) 'Content-Type': 'application/json',
      };
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(Duration(seconds: AppConfig.requestTimeoutSeconds));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(Duration(seconds: AppConfig.requestTimeoutSeconds));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(Duration(seconds: AppConfig.requestTimeoutSeconds));
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(Duration(seconds: AppConfig.requestTimeoutSeconds));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(Duration(seconds: AppConfig.requestTimeoutSeconds));
          break;
        default:
          throw StateError('Unsupported HTTP method');
      }
      await _throwIfError(response);
      if (!expectJson || response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw const ApiException(
          statusCode: 502,
          message: 'The server returned an unreadable response.',
        );
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        statusCode: 0,
        message:
            'Could not reach the AgriVerse backend. Check your connection and try again.',
      );
    }
  }

  Future<void> _throwIfError(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = _parseErrorBody(response.body);
    if (response.statusCode == 401 && _authToken != null) {
      clearAuthToken();
      await onUnauthorized?.call();
    }
    final detail = body['detail'];
    throw ApiException(
      statusCode: response.statusCode,
      message: detail is String
          ? detail
          : 'The server returned an error (${response.statusCode}).',
      errorCode: body['error_code'] is String
          ? body['error_code'] as String
          : null,
      details: body['details'] ?? body['validation_errors'],
    );
  }

  Map<String, dynamic> _parseErrorBody(String body) {
    try {
      return _asMap(jsonDecode(body));
    } catch (_) {
      return const {};
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException(
      statusCode: 502,
      message: 'The server returned an invalid response.',
    );
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    throw const ApiException(
      statusCode: 502,
      message: 'The server returned an invalid response.',
    );
  }
}
