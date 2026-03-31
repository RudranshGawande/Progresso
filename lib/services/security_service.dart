import 'package:progresso/models/security_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const String _sessionKey = 'current_session_id';

  Future<void> createSession(String userId) async {
    // Session management is now primarily handled by JWT on the backend.
    // This stub exists to maintain compatibility with existing UI.
    developer.log('🔐 SECURITY: Session created for $userId (Stub)');
  }

  Future<void> updateLastActive() async {
    // Stub
  }

  // Use 127.0.0.1 instead of localhost to avoid IPv6/IPv4 resolution issues on some machines
  static const String _apiBase = 'http://127.0.0.1:5000/api';

  // --- 2FA Methods ---

  Future<Map<String, String>> setup2fa() async {
    final token = AuthService().token;
    if (token == null) throw Exception('Not logged in');

    final response = await http.post(
      Uri.parse('$_apiBase/auth/2fa/setup'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return {
          'secret': data['secret'] as String,
          'qrData': data['otpauthUrl'] as String,
        };
      } catch (e) {
        developer.log('❌ JSON Parse Error in setup2fa: ${response.body}');
        throw Exception('Server returned invalid data format');
      }
    } else {
      String errorMessage = 'Failed to setup 2FA';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['error'] ?? errorMessage;
      } catch (_) {
        // Fallback if body is not JSON (e.g. HTML error page)
        developer.log('❌ Server Error (Status ${response.statusCode}): ${response.body}');
        errorMessage = 'Server error (${response.statusCode})';
      }
      throw Exception(errorMessage);
    }
  }

  // Deprecated: URL is now provided by backend
  String getQrCodeData(String email, String secret) {
    return 'otpauth://totp/Progresso:$email?secret=$secret&issuer=Progresso';
  }

  Future<bool> verifySetupStep(String otpCode) async {
    final token = AuthService().token;
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$_apiBase/auth/2fa/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({'token': otpCode}),
    );

    if (response.statusCode == 200) {
      developer.log('🔐 SECURITY: 2FA setup verified and enabled.');
      // Refresh current user to update the UI
      await AuthService().refreshUser();
      return true;
    }
    return false;
  }

  Future<bool> disable2fa(String otpCode) async {
    final token = AuthService().token;
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$_apiBase/auth/2fa/disable'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({'token': otpCode}),
    );

    if (response.statusCode == 200) {
      developer.log('🔐 SECURITY: 2FA disabled successfully.');
      // Refresh current user to update the UI
      await AuthService().refreshUser();
      return true;
    }
    return false;
  }

  // --- Session Management ---

  Future<List<UserSession>> getActiveSessions() async {
    final token = AuthService().token;
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_apiBase/auth/sessions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final currentSessionId = AuthService().currentUser?['sessionId']; // If we start tracking this locally
        
        return data.map((s) => UserSession.fromMap(s as Map<String, dynamic>, currentSessionId: currentSessionId)).toList();
      }
    } catch (e) {
      developer.log('❌ SECURITY: Failed to get active sessions: $e');
    }
    return [];
  }

  Future<void> revokeSession(String sessionId) async {
    final token = AuthService().token;
    if (token == null) return;

    try {
      await http.delete(
        Uri.parse('$_apiBase/auth/sessions/$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      developer.log('❌ SECURITY: Failed to revoke session: $sessionId');
    }
  }

  Future<void> revokeAllOtherSessions() async {
    final token = AuthService().token;
    if (token == null) return;

    try {
      await http.delete(
        Uri.parse('$_apiBase/auth/sessions'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      developer.log('❌ SECURITY: Failed to revoke other sessions');
    }
  }

  Future<bool> verifyOTP(String email, String code) async {
    return code.length == 6;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    // In a real implementation, this would call the Node.js API
    developer.log('🔐 SECURITY: Password change requested (Stub)');
  }
}
