import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nagah/core/network/supabase_config.dart';

class SupabaseRestClient {
  SupabaseRestClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Map<String, String> get _headers => {
    'apikey': SupabaseConfig.anonKey,
    'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
    'Content-Type': 'application/json',
  };

  Future<List<Map<String, dynamic>>> getList(
    String table, {
    Map<String, String>? query,
  }) async {
    final response = await _httpClient.get(
      _buildUri(table, query),
      headers: _headers,
    );

    final decoded = _decodeResponse(response);
    if (decoded is List) {
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    return const [];
  }

  Future<Map<String, dynamic>?> insert(
    String table, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.post(
      _buildUri(table),
      headers: {
        ..._headers,
        'Prefer': 'return=representation',
      },
      body: jsonEncode(body),
    );

    final decoded = _decodeResponse(response);
    if (decoded is List && decoded.isNotEmpty) {
      return Map<String, dynamic>.from(decoded.first);
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> update(
    String table, {
    required Map<String, String> query,
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.patch(
      _buildUri(table, query),
      headers: {
        ..._headers,
        'Prefer': 'return=representation',
      },
      body: jsonEncode(body),
    );

    final decoded = _decodeResponse(response);
    if (decoded is List) {
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    return const [];
  }

  Future<String> uploadPublicFile({
    required String bucket,
    required String objectPath,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    final response = await _httpClient.post(
      Uri.parse(
        '${SupabaseConfig.projectUrl}/storage/v1/object/$bucket/$objectPath',
      ),
      headers: {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'x-upsert': 'true',
        'Content-Type': _contentTypeForPath(file.path),
      },
      body: bytes,
    );

    _decodeResponse(response);
    return '${SupabaseConfig.projectUrl}/storage/v1/object/public/$bucket/$objectPath';
  }

  Uri _buildUri(String table, [Map<String, String>? query]) {
    final uri = Uri.parse('${SupabaseConfig.baseUrl}/$table');
    if (query == null || query.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: {
        for (final entry in query.entries) entry.key: entry.value,
      },
    );
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw Exception(
      'Supabase error ${response.statusCode}: ${response.body}',
    );
  }

  String _contentTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
