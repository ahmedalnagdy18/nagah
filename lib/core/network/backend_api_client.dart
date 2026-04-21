import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nagah/core/network/backend_config.dart';

class BackendApiClient {
  BackendApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 12);

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final response = await _client.get(
      _buildUri(path, queryParameters),
      headers: _headers(token: token),
    ).timeout(_requestTimeout, onTimeout: _onTimeout);

    final data = _decodeResponse(response);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const [];
  }

  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final response = await _client.get(
      _buildUri(path, queryParameters),
      headers: _headers(token: token),
    ).timeout(_requestTimeout, onTimeout: _onTimeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) {
      return data;
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _headers(token: token),
      body: jsonEncode(body),
    ).timeout(_requestTimeout, onTimeout: _onTimeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) {
      return data;
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await _client.patch(
      _buildUri(path),
      headers: _headers(token: token),
      body: jsonEncode(body),
    ).timeout(_requestTimeout, onTimeout: _onTimeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) {
      return data;
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> uploadImage(
    String path, {
    required String filePath,
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path));
    request.headers.addAll(_multipartHeaders(token: token));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send().timeout(
      _requestTimeout,
      onTimeout: () => throw Exception(_connectionHelpMessage()),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decodeResponse(response);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return <String, dynamic>{};
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '${BackendConfig.baseUrl}$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers({String? token}) {
    return {
      HttpHeaders.contentTypeHeader: 'application/json',
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Map<String, String> _multipartHeaders({String? token}) {
    return {
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  dynamic _decodeResponse(http.Response response) {
    try {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_extractError(response));
      }

      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    } on SocketException {
      throw Exception(_connectionHelpMessage());
    } on http.ClientException {
      throw Exception(_connectionHelpMessage());
    }
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail']?.toString();
        final message = decoded['message']?.toString();
        if (detail != null && detail.isNotEmpty) {
          return detail;
        }
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Keep the fallback below when the server does not return JSON.
    }

    return 'Request failed with status ${response.statusCode}.';
  }

  http.Response _onTimeout() {
    throw Exception(
      'Connection timed out. Make sure the backend is running on ${BackendConfig.baseUrl}.',
    );
  }

  String _connectionHelpMessage() {
    return 'Could not connect to the backend. Make sure the server is running and reachable at ${BackendConfig.baseUrl}. If you are using a real phone, localhost will not work directly.';
  }
}
