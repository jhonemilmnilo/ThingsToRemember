import 'dart:convert';
import 'package:http/http.dart' as http;

class NeonSyncService {
  // 🌐 Live 24/7 Cloudflare Edge Worker connected to Neon Postgres
  static const String _baseUrl =
      'https://passkeep-api.nilojhonemil1.workers.dev';

  // 🛡️ In-memory Cryptographic Session Token (Bearer Auth)
  static String? _sessionToken;

  /// Current session token getter
  static String? get sessionToken => _sessionToken;

  /// Clear token on logout
  static void clearSession() {
    _sessionToken = null;
  }

  /// Helper to generate authenticated headers
  static Map<String, String> _getAuthHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_sessionToken';
    }
    return headers;
  }

  /// Upsert Google user into Neon Postgres 'users' table
  static Future<Map<String, dynamic>?> syncUser({
    required String email,
    String? name,
    String provider = 'google',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name ?? 'User',
          'provider': provider,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['user'] != null) {
          return decoded['user'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Register/Set user's Master Vault Password / PIN & receive Bearer Token
  static Future<bool> setMasterPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/set-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          if (decoded['sessionToken'] != null) {
            _sessionToken = decoded['sessionToken'];
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verify user's Master Vault Password / PIN & receive Bearer Token
  static Future<bool> verifyMasterPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/verify-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['verified'] == true) {
          if (decoded['sessionToken'] != null) {
            _sessionToken = decoded['sessionToken'];
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all real vault records for user (Protected by Bearer Token)
  static Future<Map<String, dynamic>?> fetchVaultItems({
    required String email,
    String? userId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/vault/items?email=$email${userId != null ? '&userId=$userId' : ''}');
      final response = await http.get(uri, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return decoded;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create an item in Neon DB (Protected by Bearer Token)
  static Future<bool> createVaultItem({
    required String userId,
    required String type, // 'password' | 'secret' | 'contact' | 'birthday' | 'wifi'
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/vault/items'),
        headers: _getAuthHeaders(),
        body: jsonEncode({
          'type': type,
          'userId': userId,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Update an item in Neon DB (Protected by Bearer Token)
  static Future<bool> updateVaultItem({
    required String userId,
    required String itemId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/vault/items'),
        headers: _getAuthHeaders(),
        body: jsonEncode({
          'type': type,
          'userId': userId,
          'itemId': itemId,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Delete an item from Neon DB (Protected by Bearer Token)
  static Future<bool> deleteVaultItem({
    required String userId,
    required String itemId,
    required String type,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/vault/items'),
        headers: _getAuthHeaders(),
        body: jsonEncode({
          'type': type,
          'userId': userId,
          'itemId': itemId,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
