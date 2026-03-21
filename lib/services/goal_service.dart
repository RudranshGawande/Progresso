import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/services/session_manager.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/services/session_repository.dart';
import 'package:progresso/services/goal_repository.dart';
import 'dart:developer' as developer;

class GoalService extends ChangeNotifier {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

  static const String _personalKey = 'progresso_goals_v2';
  String _currentWorkspaceId = 'personal';
  List<Goal> _goals = [];
  bool _initialized = false;

  String get _storageKey => _currentWorkspaceId == 'personal'
      ? _personalKey
      : 'progresso_goals_v2_$_currentWorkspaceId';

  List<Goal> get goals => _goals;

  Future<void> init() async {
    await loadWorkspace('personal');
  }

  Future<void> loadWorkspace(String workspaceId) async {
    _currentWorkspaceId = workspaceId;
    final prefs = await SharedPreferences.getInstance();
    final String? goalsJson = prefs.getString(_storageKey);

    if (goalsJson != null) {
      final List<dynamic> data = jsonDecode(goalsJson);
      _goals = data.map((g) => Goal.fromJson(g)).toList();
      // Ensure existing local data is immediately synced to MongoDB
      saveGoals();
    } 

    if (goalsJson == null) {
      _goals = [];
      await saveGoals();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String goalsJson = jsonEncode(_goals.map((g) => g.toJson()).toList());
    await prefs.setString(_storageKey, goalsJson);
    
    // Proactive MongoDB Sync: Mirror current state to Atlas
    final user = AuthService().currentUser;
    final String? userId = user?['email'] ?? user?['auth']?['email'];
    if (userId != null) {
      developer.log('🔄 SYNC: Pushing ${_goals.length} goals to MongoDB for $userId');
      for (final goal in _goals) {
        final success = await GoalRepository().saveGoal(userId, goal);
        if (!success) {
          developer.log('⚠️ SYNC: Failed to push goal "${goal.title}" to MongoDB');
        }
      }
    }
    
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    _goals.insert(0, goal);
    await saveGoals();
  }

  Future<void> updateGoal(Goal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      await saveGoals();
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = _goals[goalIndex];
      // Cleanup any active sessions for this goal's tasks
      for (var task in goal.tasks) {
        SessionManager().deleteSession(task.id);
      }
      _goals.removeAt(goalIndex);
      await saveGoals();
    }
  }

  // Task specific updates to trigger notifyListeners properly
  Future<void> addTask(String goalId, GoalTask task) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.tasks.add(task);
    goal.activities.insert(0, GoalActivity(
      id: DateTime.now().toString(),
      title: 'Added task "${task.name}"',
      timestamp: DateTime.now(),
      type: ActivityType.taskAdded,
      taskId: task.id,
    ));
    await saveGoals();
  }

  Future<void> toggleTaskCompletion(String goalId, String taskId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final task = goal.tasks.firstWhere((t) => t.id == taskId);
    task.isCompleted = !task.isCompleted;
    if (task.isCompleted) {
      task.completedAt = DateTime.now();
      goal.activities.insert(0, GoalActivity(
        id: DateTime.now().toString(),
        title: 'Completed "${task.name}"',
        timestamp: DateTime.now(),
        type: ActivityType.taskCompleted,
        taskId: task.id,
      ));
    } else {
      task.completedAt = null;
      // Optionally remove completion activity
      goal.activities.removeWhere((a) => a.taskId == taskId && a.type == ActivityType.taskCompleted);
    }
    await saveGoals();
  }

  Future<void> deleteTask(String goalId, String taskId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final taskIndex = goal.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = goal.tasks[taskIndex];
      
      // Subtract task efforts from goal totals
      for (var session in task.sessions) {
        goal.totalTimeSpent -= session.duration;
        final dayIndex = (session.timestamp.weekday - 1);
        goal.dailyEffort[dayIndex] = (goal.dailyEffort[dayIndex] - (session.duration.inMinutes / 60.0)).clamp(0.0, double.infinity);
      }
      
      goal.tasks.removeAt(taskIndex);
      goal.activities.removeWhere((a) => a.taskId == taskId);
      await saveGoals();
    }
  }

  Future<void> addActivities(String goalId, List<GoalActivity> activities) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.activities.addAll(activities);
    goal.activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await saveGoals();
  }

  Future<void> addSessionToTask(String goalId, String taskId, FocusSession session) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final task = goal.tasks.firstWhere((t) => t.id == taskId);
    task.sessions.add(session);
    task.timeSpent = (task.timeSpent ?? Duration.zero) + session.duration;
    
    // Update goal total time
    goal.totalTimeSpent += session.duration;
    
    // Update daily effort
    final dayIndex = (session.timestamp.weekday - 1); // 0-6 (Mon-Sun)
    goal.dailyEffort[dayIndex] += session.duration.inMinutes / 60.0;
    
    goal.activities.insert(0, GoalActivity(
      id: DateTime.now().toString(),
      title: 'Focus session: ${session.duration.inMinutes}m',
      timestamp: session.timestamp,
      type: ActivityType.sessionCompleted,
      taskId: task.id,
    ));
    
    await saveGoals();
    
    // Proactive MongoDB Sync: Session Reference Requirement
    final user = AuthService().currentUser;
    final String? userId = user?['email'] ?? user?['auth']?['email'];
    if (userId != null) {
      // Ensure task has necessary metadata for DB storage
      task.userId = userId;
      task.goalId = goalId;
      task.sessionId = session.id;

      // 1. Flush independent session document
      await SessionRepository().createSession(
        goalId: goalId,
        userId: userId,
        session: session,
      );
      
      // 2. Add current task to session if it doesn't already exist in session_tasks
      await SessionRepository().addTaskToSession(task);
    }
  }
}
