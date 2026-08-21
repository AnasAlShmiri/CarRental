import 'dart:convert';

import 'dart:async';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'session_store.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (authenticated) {
      final token = await SessionStore.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool authenticated = false}) async {
    final response = await _client.get(
      Uri.parse(ApiConfig.resolveUrl(path)),
      headers: await _headers(authenticated: authenticated),
    );
    return _decode(response);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async {
    final response = await _client.post(
      Uri.parse(ApiConfig.resolveUrl(path)),
      headers: await _headers(authenticated: authenticated),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    bool authenticated = false,
  }) async {
    final response = await _client.put(
      Uri.parse(ApiConfig.resolveUrl(path)),
      headers: await _headers(authenticated: authenticated),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = response.bodyBytes.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response.statusCode, decoded),
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  String _errorMessage(int statusCode, Object? decoded) {
    if (statusCode == 401) {
      unawaited(SessionStore.clear());
      return 'انتهت جلسة الدخول. سجّل الدخول مرة أخرى.';
    }
    if (statusCode == 403) return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
    if (statusCode == 404) return 'العنصر المطلوب غير موجود.';
    if (statusCode == 408) return 'انتهت مهلة الاتصال بالخادم.';
    if (statusCode == 429) {
      return 'تم تجاوز عدد المحاولات المسموح بها. انتظر قليلًا ثم حاول مرة أخرى.';
    }

    if (decoded is Map<String, dynamic>) {
      final errors = decoded['errors'];
      if (errors is Map) {
        final messages = <String>[];
        for (final value in errors.values) {
          if (value is Iterable) {
            messages.addAll(value.map((item) => item.toString()));
          } else if (value != null) {
            messages.add(value.toString());
          }
        }
        if (messages.isNotEmpty) return messages.toSet().join('\n');
      }

      for (final key in ['detail', 'message']) {
        final value = decoded[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }

    return 'تعذر تنفيذ الطلب (${statusCode.toString()}). تحقق من البيانات وحاول مرة أخرى.';
  }
}
