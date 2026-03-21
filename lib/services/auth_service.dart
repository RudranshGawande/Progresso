import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:progresso/services/mongodb_service.dart';
import 'package:progresso/config/db_collections.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsi;
import 'package:progresso/config/secrets.dart';
import 'package:progresso/services/security_service.dart';
import 'dart:developer' as developer;

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initGoogleSignIn();
  }

  static const String _userKey = 'logged_in_user';

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;

  late final gsi.GoogleSignIn _googleSignIn;

  void _initGoogleSignIn() {
    _googleSignIn = gsi.GoogleSignIn(
      params: gsi.GoogleSignInParams(
        clientId: Secrets.googleClientId,
        clientSecret: Secrets.googleClientSecret,
        scopes: ['email', 'profile', 'openid'],
      ),
    );
  }

  gsi.GoogleSignIn get googleSignIn => _googleSignIn;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final db = MongoDBService().db;
      if (db == null) throw Exception('Database not connected');

      final usersCol = db.collection(DB.users);
      final profilesCol = db.collection(DB.userProfiles);
      
      final hashedPassword = _hashPassword(password);
      final emailClean = email.toLowerCase().trim();

      developer.log('🔐 AUTH: Attempting login for $emailClean');

      // Check both nested (new schema) and flat (old schema) structures for compatibility
      var userDoc = await usersCol.findOne(
        where.eq('auth.email', emailClean).eq('auth.passwordHash', hashedPassword)
      );
      
      // Fallback for flat structure if any exist
      userDoc ??= await usersCol.findOne(
        where.eq('email', emailClean).eq('passwordHash', hashedPassword).eq('isActive', true)
      );

      if (userDoc != null) {
        final userId = userDoc['auth']?['userId'] ?? userDoc['userId'] ?? emailClean;
        developer.log('👤 AUTH: User found. userId: $userId');

        // Extract data based on structure
        final Map<String, dynamic> authData = userDoc['auth'] ?? {
          'email': userDoc['email'],
          'name': userDoc['name'],
        };
        
        // Ensure we fetch the absolute latest profile data
        var profile = await profilesCol.findOne(where.eq('userId', emailClean)) ?? {};
        developer.log('📄 AUTH: Database profile fetched for $emailClean');
        
        await usersCol.update(
          userDoc['auth'] != null ? where.eq('auth.email', emailClean) : where.eq('email', emailClean),
          modify.set('lastLoginAt', DateTime.now()),
        );

        final security = profile['security'] ?? {};
        if (security['twoFactorEnabled'] == true) {
          final secret = security['twoFactorSecret'] ?? '';
          developer.log('⚠️ AUTH: 2FA Required for $emailClean');
          return {'2fa_required': true, 'email': emailClean, '2faSecret': secret};
        }
        
        // Merge strategy: Start with nested profile data, then overwrite with separate profile collection
        final nestedProfile = (userDoc['profile'] as Map<String, dynamic>?) ?? {};
        
        // Smart Merge: Prioritize non-empty values for bio and name
        final Map<String, dynamic> mergedProfile = {
          ...nestedProfile, 
          ...profile,
        };
        
        if (nestedProfile['bio'] != null && (profile['bio'] == null || profile['bio'].toString().isEmpty)) {
          mergedProfile['bio'] = nestedProfile['bio'];
        }

        final Map<String, dynamic> combinedUser = {
          ...userDoc,
          ...authData,
          ...mergedProfile, // Flattened keys for existing UI compatibility
          'profile': mergedProfile, // Nested key for user.profile.bio lookup
          '_id': userDoc['_id'],
          'email': emailClean,
        };

        developer.log('✅ AUTH: Full user object retrieved for $emailClean');
        developer.log('   -> Top-level bio: ${combinedUser['bio']}');
        developer.log('   -> Profile-level bio: ${combinedUser['profile']?['bio']}');
        
        await _saveSession(combinedUser);
        return combinedUser;
      }
      developer.log('❌ AUTH: No user matching credentials found');
      return null;
    } catch (e) {
      developer.log('❌ AUTH ERROR: $e');
      rethrow;
    }
  }

  Future<void> complete2faLogin(Map<String, dynamic> userAttributes) async {
    final db = MongoDBService().db;
    if (db == null) throw Exception('Database not connected');
    
    final emailClean = userAttributes['email'];
    final usersCol = db.collection(DB.users);
    final profilesCol = db.collection(DB.userProfiles);
    
    developer.log('🔐 AUTH: Completing 2FA for $emailClean');
    
    var user = await usersCol.findOne(where.eq('auth.email', emailClean));
    user ??= await usersCol.findOne(where.eq('email', emailClean));
    
    final profile = await profilesCol.findOne(where.eq('userId', emailClean)) ?? {};
    
    if (user != null) {
      final authData = (user['auth'] as Map<String, dynamic>?) ?? {};
      final nestedProfile = (user['profile'] as Map<String, dynamic>?) ?? {};
      
      final Map<String, dynamic> mergedProfile = { ...nestedProfile, ...profile };
      final Map<String, dynamic> combinedUser = {
        ...user,
        ...authData,
        ...mergedProfile,
        'profile': mergedProfile,
        'email': emailClean,
      };
      
      developer.log('✅ AUTH: 2FA Login complete. Full Object: ${jsonEncode(combinedUser, toEncodable: (o) => o is ObjectId ? o.$oid : o.toString())}');
      await _saveSession(combinedUser);
    }
  }

  Future<void> _saveSession(Map<String, dynamic> combinedUser) async {
    final prefs = await SharedPreferences.getInstance();
    
    final email = combinedUser['email'] ?? '';
    final String name = combinedUser['name'] ?? _deriveNameFromEmail(email);
    final String imageUrl = combinedUser['imageUrl'] ?? _getGravatarUrl(email);

    final sessionData = Map<String, dynamic>.from(combinedUser)
      ..remove('passwordHash')
      ..remove('password');
      
    if (sessionData['security'] != null) {
      final security = Map<String, dynamic>.from(sessionData['security']);
      security.remove('twoFactorSecret');
      sessionData['security'] = security;
    }

    sessionData['name'] = name;
    sessionData['imageUrl'] = imageUrl;
    
    // Safely encode to JSON, converting ObjectId to hex strings
    final jsonString = jsonEncode(sessionData, toEncodable: (nonEncodable) {
      if (nonEncodable is ObjectId) return nonEncodable.$oid;
      return nonEncodable.toString();
    });
    
    await prefs.setString(_userKey, jsonString);
    _currentUser = sessionData;
    
    await SecurityService().createSession(email);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove('current_session_id');
    _currentUser = null;
    notifyListeners();
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      developer.log('Google signOut error: $e');
    }
  }

  Future<bool> deleteAccount() async {
    final user = _currentUser;
    if (user == null) return false;
    final emailClean = user['email'] ?? user['auth']?['email'];
    if (emailClean == null) return false;

    try {
      final db = MongoDBService().db;
      if (db == null) return false;

      // 1. Delete from core identity collections
      await db.collection(DB.users).remove(where.eq('auth.email', emailClean));
      await db.collection(DB.users).remove(where.eq('email', emailClean));
      await db.collection(DB.userProfiles).remove(where.eq('userId', emailClean));
      
      // 2. Delete from auxiliary data collections
      final auxCollections = [
        'personal_goals',
        'activity_log',
        'profile_activity',
        'password_history',
        'device_sessions',
      ];
      
      for (final colName in auxCollections) {
        try {
          await db.collection(colName).remove(where.eq('userId', emailClean));
          await db.collection(colName).remove(where.eq('email', emailClean));
        } catch (e) {
          developer.log('⚠️ Could not clear collection $colName: $e');
        }
      }

      developer.log('🗑️ AUTH: Account and all associated data deleted for $emailClean');
      
      // 3. Clear local session
      await logout();
      return true;
    } catch (e) {
      developer.log('❌ AUTH DELETE ERROR: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
      
      final String? sessionId = prefs.getString('current_session_id');
      if (sessionId == null || sessionId.isEmpty) {
        developer.log('🏷️ No session ID found. Creating new session for existing login...');
        await SecurityService().createSession(_currentUser!['email']);
      }

      developer.log('👤 APP START: Found cached session for ${_currentUser!['email']}');
      
      // Proactively refresh from DB to ensure bio and other data are fresh
      await refreshUser();
      
      developer.log('👤 APP START: Logged in and refreshed as ${_currentUser!['email']}');
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

  Future<bool> register(String name, String email, String password) async {
    try {
      final db = MongoDBService().db;
      if (db == null) throw Exception('Database not connected');

      final usersCol = db.collection(DB.users);
      final profilesCol = db.collection(DB.userProfiles);
      final emailClean = email.toLowerCase().trim();
      
      var existingUser = await usersCol.findOne(where.eq('auth.email', emailClean));
      existingUser ??= await usersCol.findOne(where.eq('email', emailClean));
      
      if (existingUser != null) {
        throw Exception('User with this email already exists');
      }

      final hashedPassword = _hashPassword(password);
      final displayName = name.trim().isEmpty ? _deriveNameFromEmail(emailClean) : name.trim();
      final defaultImageUrl = _getGravatarUrl(emailClean);
      final now = DateTime.now();

      // Create identity record specifically following the DB validator (auth + profile nested)
      await usersCol.insertOne({
        'auth': {
          'userId': 'USR-${DateTime.now().millisecondsSinceEpoch}-PROG',
          'name': displayName,
          'email': emailClean,
          'passwordHash': hashedPassword,
        },
        'profile': {
          'bio': '',
          'avatarUrl': defaultImageUrl,
          'theme': 'light',
          'notifications': true,
          'preferences': {
            'theme': 'system',
            'language': 'en',
            'timezone': 'UTC'
          },
        },
        'createdAt': now,
        'updatedAt': now,
      });

      // Also maintain the separate profile record for compatibility with existing UI logic
      await profilesCol.insertOne({
        'userId': emailClean,
        'name': displayName,
        'username': null,
        'imageUrl': defaultImageUrl,
        'bio': '',
        'phone': null,
        'role': 'user',
        'preferences': {
          'theme': 'system',
          'language': 'en',
          'timezone': 'UTC'
        },
        'security': {
          'twoFactorEnabled': false,
          'twoFactorSecret': null,
          'recoveryEmail': null,
          'lastPasswordChange': null
        },
        'updatedAt': now,
      });

      developer.log('✅ User registered in MongoDB (Identity + Profile): $emailClean');
      return true;
    } catch (e) {
      developer.log('❌ Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> handleGoogleSignIn(String name, String email) async {
    try {
      final db = MongoDBService().db;
      if (db == null) throw Exception('Database not connected');

      final usersCol = db.collection(DB.users);
      final profilesCol = db.collection(DB.userProfiles);
      final emailClean = email.toLowerCase().trim();

      var userDoc = await usersCol.findOne(where.eq('auth.email', emailClean));
      userDoc ??= await usersCol.findOne(where.eq('email', emailClean));

      if (userDoc == null) {
        final now = DateTime.now();
        
        final newUser = {
          'auth': {
            'userId': 'USR-${DateTime.now().millisecondsSinceEpoch}-PROG',
            'name': name.trim().isEmpty ? _deriveNameFromEmail(emailClean) : name,
            'email': emailClean,
            'passwordHash': null,
          },
          'profile': {
            'bio': '',
            'avatarUrl': _getGravatarUrl(emailClean),
            'theme': 'light',
            'notifications': true,
            'preferences': {
              'theme': 'system',
              'language': 'en',
              'timezone': 'UTC'
            },
          },
          'createdAt': now,
          'updatedAt': now,
          'lastLoginAt': now,
        };
        await usersCol.insertOne(newUser);
        
        final profile = {
          'userId': emailClean,
          'name': name.trim().isEmpty ? _deriveNameFromEmail(emailClean) : name,
          'username': null,
          'imageUrl': _getGravatarUrl(emailClean),
          'bio': '',
          'phone': null,
          'role': 'user',
          'preferences': {
            'theme': 'system',
            'language': 'en',
            'timezone': 'UTC'
          },
          'security': {
            'twoFactorEnabled': false,
            'twoFactorSecret': null,
            'recoveryEmail': null,
            'lastPasswordChange': null
          },
          'updatedAt': now,
        };
        await profilesCol.insertOne(profile);
        developer.log('✅ New Google user created (Identity + Profile): $emailClean');
        
        final Map<String, dynamic> combinedUser = {
          ...newUser, 
          ...(newUser['auth'] as Map<String, dynamic>), 
          ...(newUser['profile'] as Map<String, dynamic>), 
          ...profile,
          'email': emailClean
        };
        await _saveSession(combinedUser);
        return combinedUser;
      } else {
        await usersCol.update(
          userDoc['auth'] != null ? where.eq('auth.email', emailClean) : where.eq('email', emailClean),
          modify.set('lastLoginAt', DateTime.now()),
        );

        var profile = await profilesCol.findOne(where.eq('userId', emailClean)) ?? {};
        final security = profile['security'] ?? {};
        
        if (security['twoFactorEnabled'] == true) {
          final secret = security['twoFactorSecret'] ?? '';
          return {'2fa_required': true, 'email': emailClean, '2faSecret': secret};
        }

        final authData = (userDoc['auth'] as Map<String, dynamic>?) ?? {'email': emailClean};
        final Map<String, dynamic> combinedUser = {
          ...userDoc, 
          ...authData, 
          ...profile, 
          'email': emailClean
        };
        await _saveSession(combinedUser);
        return combinedUser;
      }
    } catch (e) {
      developer.log('Google Sync error: $e');
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
    final user = _currentUser;
    if (user == null) return;

    final updatedUser = Map<String, dynamic>.from(user);
    if (name != null) updatedUser['name'] = name;
    if (email != null) updatedUser['email'] = email;
    if (bio != null) updatedUser['bio'] = bio;
    if (imageUrl != null) updatedUser['imageUrl'] = imageUrl;
    if (rotation != null) updatedUser['rotation'] = rotation;
    if (localImagePath != null) updatedUser['localImagePath'] = localImagePath;
    if (avatarBase64 != null) updatedUser['avatarBase64'] = avatarBase64;
    updatedUser['updatedAt'] = DateTime.now().toIso8601String();

    try {
      final db = MongoDBService().db;
      if (db != null) {
        final profilesCol = db.collection(DB.userProfiles);
        final usersCol = db.collection(DB.users);
        final emailClean = user['email'];
        
        var m = modify;
        if (name != null) m = m.set('name', name);
        if (bio != null) m = m.set('bio', bio);
        if (imageUrl != null) m = m.set('imageUrl', imageUrl);
        if (rotation != null) m = m.set('rotation', rotation);
        if (localImagePath != null) m = m.set('localImagePath', localImagePath);
        if (avatarBase64 != null) m = m.set('avatarBase64', avatarBase64);
        m = m.set('updatedAt', DateTime.now());

        await profilesCol.update(where.eq('userId', emailClean), m);

        // Update nested profile in users collection point-of-truth
        var um = modify;
        if (name != null) um = um.set('auth.name', name);
        if (bio != null) um = um.set('profile.bio', bio);
        if (imageUrl != null) um = um.set('profile.avatarUrl', imageUrl);
        if (avatarBase64 != null) um = um.set('profile.avatarBase64', avatarBase64);
        um = um.set('updatedAt', DateTime.now());

        await usersCol.update(where.eq('auth.email', emailClean), um);
        
        // Critically: Fetch fresh from DB to sync all nested fields (bio, profile, etc.)
        await refreshUser();
        return; // refreshUser already called _saveSession and notified listeners
      }
      
      // If DB is null/disconnected, at least update memory and save locally
      await _saveSession(updatedUser);
    } catch (e) {
      developer.log('❌ AUTH UPDATE ERROR: $e');
      // If DB update fails, we still have the local state update in updatedUser
      await _saveSession(updatedUser);
    }
  }

  Future<void> refreshUser() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      final db = MongoDBService().db;
      if (db == null) return;

      final emailClean = user['email'];
      final usersCol = db.collection(DB.users);
      final profilesCol = db.collection(DB.userProfiles);

      developer.log('🔄 AUTH: Refreshing user data for $emailClean');

      var userDoc = await usersCol.findOne(where.eq('auth.email', emailClean));
      userDoc ??= await usersCol.findOne(where.eq('email', emailClean));
      
      final profile = await profilesCol.findOne(where.eq('userId', emailClean)) ?? {};

      // Even if userDoc is null, we should update based on the profile doc found
      final authData = (userDoc?['auth'] as Map<String, dynamic>?) ?? user;
      final profileData = (userDoc?['profile'] as Map<String, dynamic>?) ?? {};
      
      final Map<String, dynamic> mergedProfile = {
        ...profileData,
        ...profile,
      };
      
      // Smart Merge Fallback: If separate profile is empty, use nested as source of truth
      if (profileData['bio'] != null && (profile['bio'] == null || profile['bio'].toString().trim().isEmpty)) {
        mergedProfile['bio'] = profileData['bio'];
      }
      
      // Preserve avatarBase64 if present in any of the profile locations
      if (profileData['avatarBase64'] != null) mergedProfile['avatarBase64'] = profileData['avatarBase64'];
      if (profile['avatarBase64'] != null) mergedProfile['avatarBase64'] = profile['avatarBase64'];

      final Map<String, dynamic> combinedUser = {
        ...(userDoc ?? {}),
        ...authData,
        ...mergedProfile, 
        'profile': mergedProfile,
        'email': emailClean,
      };
      
      developer.log('✅ AUTH: Refresh complete for $emailClean. Profile ID: ${profile['_id']}');
      developer.log('   -> Final Bio in Memory: ${combinedUser['profile']?['bio']}');
      
      await _saveSession(combinedUser);
    } catch (e) {
      developer.log('❌ AUTH REFRESH ERROR: $e');
    }
  }
}
