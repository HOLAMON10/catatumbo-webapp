// lib/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'session.dart';

class Api {
  static final String baseUrl = dotenv.env['API_URL'] ?? '';

  /// Universal request function
  static Future<http.Response> send(
    String method,
    String endpoint, {
    Map<String, dynamic>? payload,
    Map<String, String>? headers,
    bool requireAuth = true, 
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    // Base headers
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    // If this request needs auth, attach the JWT from Session
    if (requireAuth) {
      if (!Session.hasToken || Session.isExpired) {
        // Here you can throw, or handle it differently
        throw Exception('Token missing or expired — user must log in again.');
      }

      mergedHeaders['Authorization'] = '${Session.jwt}';
    }

    final body = payload != null ? jsonEncode(payload) : null;

    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(uri, headers: mergedHeaders, body: body);
      case 'PUT':
        return await http.put(uri, headers: mergedHeaders, body: body);
      case 'DELETE':
        return await http.delete(uri, headers: mergedHeaders);
      default: // GET
        return await http.get(uri, headers: mergedHeaders);
    }
  }
}
