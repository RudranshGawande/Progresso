import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/services/session_manager.dart';
import 'package:progresso/services/workspace_service.dart';
import 'dart:developer' as developer;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userKey = 'logged_in_user';
  static const String _tokenKey = 'auth_token';
  static const String _apiBase = 'http://127.0.0.1:5000/api';

  Future<Map<String, String>> _getDeviceHeaders() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown';
    String deviceType = kIsWeb ? 'Desktop' : (Platform.isAndroid || Platform.isIOS ? 'Mobile' : 'Desktop');
    String osInfo = kIsWeb ? 'Web' : Platform.operatingSystem;

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceName = webInfo.browserName.name;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model;
        osInfo = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        osInfo = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        deviceName = winInfo.computerName;
        osInfo = 'Windows ${winInfo.displayVersion}';
      }
    } catch (e) {
      developer.log('⚠️ AUTH: Failed to get device info: $e');
    }

    return {
      'X-Device-Name': deviceName,
      'X-Device-Type': deviceType,
      'X-OS-Info': osInfo,
    };
  }

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? _token;
  String? get token => _token;
  
  bool get is2faEnabled {
    final security = _currentUser?['security'];
    if (security == null) return false;
    return security['twoFactorEnabled'] == true;
  }

  bool get _isDemoUser {
    final user = AuthService().currentUser;
    return user?['email'] == 'demo@progressor.com' || 
           user?['userId'] == 'demo_user_id_123';
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final emailClean = email.toLowerCase().trim();
    
    // DEMO BYPASS: Local-only mode for competition
    if (emailClean == 'demo@progressor.com' && password == 'pass123') {
      developer.log('🚀 DEMO MODE: Local login bypass for $emailClean');
      final Map<String, dynamic> demoUser = {
        'userId': 'demo_user_id_123',
        'email': emailClean,
        'name': 'Demo User',
        'defaultPersonalWorkspaceId': 'personal_demo_ws',
      };
      // Use a mock JWT for demo to satisfy decoders
      _token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImRlbW9fdXNlcl9pZF8xMjMifQ.mock_signature';
      await _saveSession(demoUser, _token!);
      
      // Force refresh data locally
      await GoalService().init(forceReset: true);
      
      return demoUser;
    }

    try {
      developer.log('🔐 AUTH API: Attempting login for $emailClean');

      final deviceHeaders = await _getDeviceHeaders();
      final response = await http.post(
        Uri.parse('$_apiBase/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          ...deviceHeaders,
        },
        body: jsonEncode({
          'email': emailClean,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        
        // Structure the user object for local session
        final user = data['user'];
        final Map<String, dynamic> userMap = _processUserResponse(data, user);

        await _saveSession(userMap, _token!);
        developer.log('✅ AUTH API: Login successful for $emailClean');
        return userMap;
      } else if (response.statusCode == 202) {
        // MFA Required
        final data = jsonDecode(response.body);
        developer.log('🔐 AUTH API: MFA required for $emailClean');
        return {'mfaRequired': true, 'email': emailClean};
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Login failed';
        developer.log('❌ AUTH API: Login failed: $error');
        return null;
      }
    } catch (e) {
      developer.log('❌ AUTH API ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verifyLogin2fa(String email, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/auth/2fa/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': otpCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        final user = data['user'];
        final Map<String, dynamic> userMap = _processUserResponse(data, user);

        await _saveSession(userMap, _token!);
        return userMap;
      } else {
        return null;
      }
    } catch (e) {
      developer.log('❌ 2FA Login Error: $e');
      return null;
    }
  }

  Map<String, dynamic> _processUserResponse(Map<String, dynamic> data, dynamic user) {
    return {
      'userId': data['userId'] ?? user['_id'],
      'email': data['email'] ?? user['email'],
      'name': user?['name'] ?? _deriveNameFromEmail(data['email'] ?? user['email']),
      'defaultPersonalWorkspaceId': data['defaultPersonalWorkspaceId'] ?? user['defaultPersonalWorkspaceId'],
      'bio': user?['bio'] ?? '',
      'imageUrl': user?['imageUrl'],
      'rotation': user?['rotation'] ?? 0.0,
      'localImagePath': user?['localImagePath'],
      'avatarBase64': user?['avatarBase64'],
      'security': user?['security'] ?? {'twoFactorEnabled': false},
    };
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final emailClean = email.toLowerCase().trim();
      developer.log('📝 AUTH API: Registering $emailClean');

      final deviceHeaders = await _getDeviceHeaders();
      final response = await http.post(
        Uri.parse('$_apiBase/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          ...deviceHeaders,
        },
        body: jsonEncode({
          'name': name,
          'email': emailClean,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        
        final user = data['user'];
        final Map<String, dynamic> userMap = _processUserResponse(data, user);

        await _saveSession(userMap, _token!);
        developer.log('✅ AUTH API: Registration successful for $emailClean');
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
        developer.log('❌ AUTH API: Registration failed: $error');
        throw Exception(error);
      }
    } catch (e) {
      developer.log('❌ AUTH API ERROR: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? imageUrl,
    double? rotation,
    String? localImagePath,
    String? avatarBase64,
  }) async {
    if (_token == null) return;
    try {
      final response = await http.put(
        Uri.parse('$_apiBase/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (bio != null) 'bio': bio,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (rotation != null) 'rotation': rotation,
          if (localImagePath != null) 'localImagePath': localImagePath,
          if (avatarBase64 != null) 'avatarBase64': avatarBase64,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final Map<String, dynamic> userMap = _processUserResponse(data, user);
        await _saveSession(userMap, _token!);
        developer.log('✅ AUTH API: Profile updated successfully');
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Profile update failed');
      }
    } catch (e) {
      developer.log('❌ AUTH API UPDATE PROFILE ERROR: $e');
      rethrow;
    }
  }

  Future<bool> deleteAccount() async {
    if (_token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$_apiBase/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        developer.log('🗑️ AUTH API: Account deleted successfully');
        await logout();
        return true;
      }
      return false;
    } catch (e) {
      developer.log('❌ AUTH API DELETE ERROR: $e');
      return false;
    }
  }

  Future<void> complete2faLogin(Map<String, dynamic> attributes) async {
    // Stub for compiler compatibility
    developer.log('⚠️ 2FA not yet implemented on backend API');
    return;
  }

  Future<void> _saveSession(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    _currentUser = Map<String, dynamic>.from(user);
    final jsonString = jsonEncode(_currentUser);
    
    await prefs.setString(_userKey, jsonString);
    _token = token;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('$_apiBase/auth/logout'),
          headers: {'Authorization': 'Bearer $_token'},
        );
      }
    } catch (e) {
      developer.log('⚠️ AUTH: Failed to notify backend of logout');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    _currentUser = null;
    _token = null;
    
    // Clear state in all services when user logs out
    GoalService().reset();
    SessionManager().reset();
    WorkspaceService().reset();
    
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    final String? cachedToken = prefs.getString(_tokenKey);
    final String? userJson = prefs.getString(_userKey);

    if (cachedToken != null && userJson != null) {
      try {
        // Only check expiry for real JWTs
        if (cachedToken.contains('.')) {
          if (JwtDecoder.isExpired(cachedToken)) {
            developer.log('⚠️ Session expired, logging out');
            await logout();
            return false;
          }
        }
      } catch (e) {
        developer.log('⚠️ Token validation failed: $e');
        // If it's the demo token or something else, we let it pass if user data exists
        if (!cachedToken.startsWith('eyJ')) {
           // If not a JWT, we don't treat as expired
        } else {
           await logout();
           return false;
        }
      }

      _token = cachedToken;
      _currentUser = jsonDecode(userJson);
      notifyListeners();
      return true;
    }
    return false;
  }

  String _deriveNameFromEmail(String email) {
    if (email.isEmpty) return 'User';
    final namePart = email.split('@')[0];
    return namePart
        .split(RegExp(r'[._\-]'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _getGravatarUrl(String email) {
    final hash = md5.convert(utf8.encode(email.toLowerCase().trim())).toString();
    return 'https://www.gravatar.com/avatar/$hash?s=400&d=mp';
  }

  Future<void> refreshUser() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final Map<String, dynamic> userMap = _processUserResponse(data, user);
        await _saveSession(userMap, _token!);
      }
    } catch (e) {
      developer.log('❌ AUTH API REFRESH ERROR: $e');
    }
  }
}
