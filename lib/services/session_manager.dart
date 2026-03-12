import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/models/goal_models.dart';

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const String _storageKey = 'progresso_sessions';
  final Map<String, ActiveSession> _sessions = {};
  bool _initialized = false;
  Timer? _updateTimer;

  Map<String, ActiveSession> get sessions => _sessions;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString(_storageKey);
    
    if (sessionsJson != null) {
      final Map<String, dynamic> data = jsonDecode(sessionsJson);
      data.forEach((taskId, sessionData) {
        _sessions[taskId] = ActiveSession.fromJson(sessionData);
      });
    }
    _initialized = true;
    _startUpdateTimer();
    notifyListeners();
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_sessions.values.any((s) => s.status == SessionStatus.active)) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    _sessions.forEach((taskId, session) {
      data[taskId] = session.toJson();
    });
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  ActiveSession? getSessionForTask(String taskId) => _sessions[taskId];

  Future<void> startSession(String taskId, String goalId, {int? totalDuration}) async {
    if (_sessions.containsKey(taskId)) return;

    final session = ActiveSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      goalId: goalId,
      status: SessionStatus.active,
      lastResumeTime: DateTime.now(),
      totalDuration: totalDuration,
    );

    _sessions[taskId] = session;
    await _persist();
    notifyListeners();
  }

  Future<void> pauseSession(String taskId) async {
    final session = _sessions[taskId];
    if (session == null || session.status != SessionStatus.active) return;

    final now = DateTime.now();
    if (session.lastResumeTime != null) {
      session.totalElapsedTime += now.difference(session.lastResumeTime!).inMilliseconds;
    }
    session.status = SessionStatus.paused;
    session.pausedAt = now;
    session.lastResumeTime = null;

    await _persist();
    notifyListeners();
  }

  Future<void> resumeSession(String taskId) async {
    final session = _sessions[taskId];
    if (session == null || session.status != SessionStatus.paused) return;

    session.status = SessionStatus.active;
    session.lastResumeTime = DateTime.now();
    session.pausedAt = null;

    await _persist();
    notifyListeners();
  }

  Future<void> completeSession(String taskId) async {
    final session = _sessions[taskId];
    if (session == null) return;

    final now = DateTime.now();
    if (session.status == SessionStatus.active && session.lastResumeTime != null) {
      session.totalElapsedTime += now.difference(session.lastResumeTime!).inMilliseconds;
    }

    session.status = SessionStatus.completed;
    session.endedAt = now;

    _sessions.remove(taskId);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteSession(String taskId) async {
    if (_sessions.containsKey(taskId)) {
      _sessions.remove(taskId);
      await _persist();
      notifyListeners();
    }
  }

  Duration getElapsedTime(String taskId) {
    final session = _sessions[taskId];
    if (session == null) return Duration.zero;

    int totalMs = session.totalElapsedTime;
    if (session.status == SessionStatus.active && session.lastResumeTime != null) {
      totalMs += DateTime.now().difference(session.lastResumeTime!).inMilliseconds;
    }
    return Duration(milliseconds: totalMs);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}m';
    }
  }
}
