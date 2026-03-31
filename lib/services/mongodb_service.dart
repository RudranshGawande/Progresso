import 'package:mongo_dart/mongo_dart.dart';
import 'dart:developer' as developer;

class MongoDBService {
  static final MongoDBService _instance = MongoDBService._internal();
  factory MongoDBService() => _instance;
  MongoDBService._internal();

  Db? _db;
  bool _isConnected = false;

  // Replace <db_password> with your actual password
  // Suggestion: Use a secret management system or environment variables for production
  // authSource=admin ensures it looks for the user in the correct Atlas database
  static const String _connectionString = "mongodb+srv://rudransh:Progresso@progresso.addrnjy.mongodb.net/progresso?authSource=admin&retryWrites=true&w=majority";

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      developer.log('Attempting to connect to MongoDB...');
      _db = await Db.create(_connectionString);
      await _db!.open();
      _isConnected = true;
      developer.log('✅ Successfully connected to MongoDB Atlas');
    } catch (e) {
      if (e.toString().contains('bad auth')) {
        developer.log('❌ AUTH FAILED: Check username (rudransh) and password (Progresso) in Atlas Database Access tab.');
      } else {
        developer.log('❌ Connection Error: $e');
      }
      _isConnected = false;
      rethrow;
    }
  }

  Db? get db => _db;

  Future<void> close() async {
    await _db?.close();
    _isConnected = false;
  }
}
