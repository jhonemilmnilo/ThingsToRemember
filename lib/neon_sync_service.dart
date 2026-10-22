import 'dart:convert';
import 'package:http/http.dart' as http;

class NeonSyncService {
  // 🌐 Permanent 24/7 Cloudflare Edge Worker connected to Neon Postgres
  static const String _syncApiUrl =
      'https://passkeep-api.nilojhonemil1.workers.dev/api/users/sync';

  /// Upsert Google user into Neon Postgres 'users' table
  static Future<Map<String, dynamic>?> syncUser({
    required String email,
    String? name,
    String provider = 'google',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_syncApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
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
    } catch (e) {
      return null;
    }
  }
}
