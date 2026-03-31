import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Thin REST client for session and task persistence.
/// All methods are fire-and-forget (best-effort): they log errors but don't
/// throw, so the local SharedPreferences state is always the source of truth.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _base = 'http://127.0.0.1:5000/api';

  Map<String, String> get _headers {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Goals ──────────────────────────────────────────────────────────────────

  /// Creates a goal in MongoDB and returns its `_id`, or null on failure.
  Future<String?> createGoal({
    required String workspaceId,
    required String name,
    required String description,
    required DateTime dueDate,
    required String iconCode,
    required String imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/goals'),
        headers: _headers,
        body: jsonEncode({
          'workspaceId': workspaceId,
          'name': name,
          'description': description,
          'dueDate': dueDate.toIso8601String(),
          'iconCode': iconCode,
          'imageUrl': imageUrl,
          'sessionIds': [],
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        developer.log('GOAL CREATED IN DB: ${data['_id']}');
        return data['_id']?.toString();
      } else {
        developer.log('GOAL CREATE FAILED: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('❌ GOAL API ERROR: $e');
      return null;
    }
  }

  /// Updates an existing goal's name and description in MongoDB.
  Future<void> updateGoal({
    required String goalId,
    String? name,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;

      if (body.isEmpty) return; // Nothing to update

      final response = await http.put(
        Uri.parse('$_base/goals/$goalId'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        developer.log('⚠️ GOAL UPDATE FAILED: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      developer.log('❌ GOAL UPDATE API ERROR: $e');
    }
  }

  // ── Sessions ─────────────────────────────────────────────────────────────

  /// Creates a session record in MongoDB.
  /// Returns the created document's `_id`, or null on failure.
  /// The backend automatically pushes this session's _id into Goal.sessionIds.
  Future<String?> createSession({
    required String workspaceId,
    required String goalId,
    required String goalName,
    required List<String> taskIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/sessions'),
        headers: _headers,
        body: jsonEncode({
          'workspaceId': workspaceId,
          'goalId': goalId,
          'goalSnapshot': {'_id': goalId, 'name': goalName},
          'taskIds': taskIds,
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        developer.log('✅ SESSION CREATED & LINKED TO GOAL: ${data['_id']}');
        return data['_id']?.toString();
      } else {
        developer.log('⚠️ SESSION CREATE FAILED: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('❌ SESSION API ERROR: $e');
      return null;
    }
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  /// Creates a task record in MongoDB.
  /// Returns the created document's `_id`, or null on failure.
  Future<String?> createTask({
    String? sessionId,
    required String goalId,
    required String workspaceId,
    required String name,
    required String priority,
    required DateTime deadline,
    required String sessionType,
    required int totalAllocatedTime, // seconds
  }) async {
    try {
      final body = <String, dynamic>{
        'goalId': goalId,
        'workspaceId': workspaceId,
        'name': name,
        'priority': priority,
        'deadline': deadline.toIso8601String(),
        'sessionType': sessionType,
        'status': 'not_started',
        'selected': false,
        'timer': {
          'totalAllocatedTime': totalAllocatedTime,
          'timeSpent': 0,
        },
      };
      // Only include sessionId if it's a valid ObjectId
      if (sessionId != null && sessionId.isNotEmpty) {
        body['sessionId'] = sessionId;
      }

      final response = await http.post(
        Uri.parse('$_base/tasks'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        developer.log('✅ TASK CREATED: ${data['_id']}');
        return data['_id']?.toString();
      } else {
        developer.log('⚠️ TASK CREATE FAILED: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('❌ TASK API ERROR: $e');
      return null;
    }
  }

  /// Updates an existing task's status and timeSpent.
  Future<void> updateTask({
    required String taskId,
    String? status,
    int? timeSpent, // seconds
    int? totalAllocatedTime, // seconds
    String? sessionType,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (timeSpent != null) body['timer.timeSpent'] = timeSpent;
      if (totalAllocatedTime != null) body['timer.totalAllocatedTime'] = totalAllocatedTime;
      if (sessionType != null) body['sessionType'] = sessionType;

      final response = await http.put(
        Uri.parse('$_base/tasks/$taskId'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        developer.log('⚠️ TASK UPDATE FAILED: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      developer.log('❌ TASK UPDATE API ERROR: $e');
    }
  }
}
