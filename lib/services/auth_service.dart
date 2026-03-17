import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:progresso/services/mongodb_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsi;
import 'package:progresso/config/secrets.dart';
import 'dart:developer' as developer;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initGoogleSignIn();
  }

  final String _collectionName = 'users';
  static const String _userKey = 'logged_in_user';

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Google Sign In Instance (Singleton)
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

  // Helper to hash passwords before saving/checking
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final db = MongoDBService().db;
      if (db == null) throw Exception('Database not connected');

      final collection = db.collection(_collectionName);
      final hashedPassword = _hashPassword(password);

      final user = await collection.findOne(
        where.eq('email', email.toLowerCase().trim()).eq('password', hashedPassword),
      );

      if (user != null) {
        developer.log('User logged in: ${user['email']}');
        await _saveSession(user);
        return user;
      }
      return null;
    } catch (e) {
      developer.log('Login error: $e');
      rethrow;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    // Don't save password in local storage
    final sessionData = Map<String, dynamic>.from(user)..remove('password');
    await prefs.setString(_userKey, jsonEncode(sessionData));
    _currentUser = sessionData;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _currentUser = null;
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      developer.log('Google signOut error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
      developer.log('👤 APP START: Logged in as ${_currentUser!['email']}');
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final db = MongoDBService().db;
      if (db == null) throw Exception('Database not connected');

      final collection = db.collection(_collectionName);
      
      // Check if user already exists
      final existingUser = await collection.findOne(where.eq('email', email.toLowerCase().trim()));
      if (existingUser != null) {
        throw Exception('User with this email already exists');
      }

      final hashedPassword = _hashPassword(password);

      final result = await collection.insertOne({
        'name': name,
        'email': email.toLowerCase().trim(),
        'password': hashedPassword,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (result.isSuccess) {
        developer.log('✅ User effectively saved to MongoDB: $email');
      } else {
        developer.log('⚠️ MongoDB insertion might not have been acknowledged: ${result.writeConcernError}');
      }
      
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

      final collection = db.collection(_collectionName);
      final emailClean = email.toLowerCase().trim();

      // Check if user exists
      var user = await collection.findOne(where.eq('email', emailClean));

      if (user == null) {
        // Create new user for first-time Google Sign-In
        final newUser = {
          'name': name,
          'email': emailClean,
          'googleAuth': true,
          'createdAt': DateTime.now().toIso8601String(),
        };
        final result = await collection.insertOne(newUser);
        if (result.isSuccess) {
          developer.log('✅ New Google user created in MongoDB: $emailClean');
        } else {
          developer.log('⚠️ Google user insertion not acknowledged: ${result.writeConcernError}');
        }
        user = newUser;
      } else {
        developer.log('Existing Google user found in MongoDB: $emailClean');
      }

      await _saveSession(user);
      return user;
    } catch (e) {
      developer.log('Google Sync error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({String? name, String? email, String? bio, String? imageUrl}) async {
    final user = _currentUser;
    if (user == null) return;

    final updatedUser = Map<String, dynamic>.from(user);
    if (name != null) updatedUser['name'] = name;
    if (email != null) updatedUser['email'] = email;
    if (bio != null) updatedUser['bio'] = bio;
    if (imageUrl != null) updatedUser['imageUrl'] = imageUrl;

    try {
      final db = MongoDBService().db;
      if (db != null) {
        final collection = db.collection(_collectionName);
        await collection.update(
          where.eq('email', user['email']),
          modify.set('name', updatedUser['name'])
               .set('email', updatedUser['email'])
               .set('bio', updatedUser['bio'])
               .set('imageUrl', updatedUser['imageUrl']),
        );
      }
    } catch (e) {
      developer.log('Error updating MongoDB profile: $e');
    }

    await _saveSession(updatedUser);
  }
}
