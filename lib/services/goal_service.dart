import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/services/session_manager.dart';

class GoalService extends ChangeNotifier {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

  static const String _storageKey = 'progresso_goals';
  List<Goal> _goals = [];
  bool _initialized = false;

  List<Goal> get goals => _goals;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final String? goalsJson = prefs.getString(_storageKey);

    if (goalsJson != null) {
      final List<dynamic> data = jsonDecode(goalsJson);
      _goals = data.map((g) => Goal.fromJson(g)).toList();
    } else {
      // Create default "Exam Prep" session on first launch
      _goals = [
        Goal(
          id: 'exam_prep_default',
          title: 'Exam Prep',
          description: 'Focus on upcoming analytics certification and core concepts.',
          dueDate: DateTime.now().add(const Duration(days: 14)),
          icon: Icons.school,
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD9QJ_LVBXza2ziIOuTjHIhBsAb0-GKCtjEvzPsPCTdttR7xoxn5p2PxUXPG5Hcwkd3pSU6-l95dIwsV-nFWQ_Zn21LOu0jiFdCnUIZN4xvAI1jg4KTCOFB8wqCcBomckeuE-tRCPnH6f7rYRU_58NUkKXCgpLrujuyLqBGDt82O3aAZ4tzK-zOA2sJa7fjC-TAGD61Muj4h_gRt7H1sUrBkc_O4_y-rqOZcpZVZt5W998QnletUnN8jXPHM6LrkcVrOlw3FvJYnuwa',
          tasks: [
            GoalTask(
              id: 'task_ui',
              name: 'UI Design System',
              deadline: DateTime.now().add(const Duration(days: 2)),
              priority: TaskPriority.high,
              sessions: List.generate(14, (i) => FocusSession(
                id: 's_ui_$i',
                duration: const Duration(hours: 2, minutes: 15),
                intensity: 0.9,
                focusScore: 88,
                trendData: [0.4, 0.6, 0.8, 0.9],
                timestamp: DateTime.now().subtract(Duration(days: i, hours: 2)),
              )),
            ),
            GoalTask(
              id: 'task_email',
              name: 'Email Triage',
              deadline: DateTime.now().add(const Duration(days: 3)),
              priority: TaskPriority.medium,
              sessions: List.generate(8, (i) => FocusSession(
                id: 's_email_$i',
                duration: const Duration(minutes: 45),
                intensity: 0.6,
                focusScore: 75,
                trendData: [0.5, 0.5, 0.6, 0.6],
                timestamp: DateTime.now().subtract(Duration(days: i, hours: 4)),
              )),
            ),
            GoalTask(
              id: 'task_sprint',
              name: 'Sprint Planning',
              deadline: DateTime.now().add(const Duration(days: 1)),
              priority: TaskPriority.high,
              sessions: List.generate(3, (i) => FocusSession(
                id: 's_sprint_$i',
                duration: const Duration(hours: 1, minutes: 30),
                intensity: 0.8,
                focusScore: 82,
                trendData: [0.4, 0.7, 0.8, 0.8],
                timestamp: DateTime.now().subtract(Duration(days: i, hours: 6)),
              )),
            ),
            GoalTask(
              id: 'task_bugs',
              name: 'Bug Fixes',
              deadline: DateTime.now().add(const Duration(days: 5)),
              priority: TaskPriority.high,
              sessions: List.generate(21, (i) => FocusSession(
                id: 's_bugs_$i',
                duration: const Duration(hours: 2),
                intensity: 0.95,
                focusScore: 94,
                trendData: [0.7, 0.8, 0.9, 0.95],
                timestamp: DateTime.now().subtract(Duration(days: i, hours: 8)),
              )),
            ),
          ],
          totalTimeSpent: const Duration(hours: 42),
          dailyEffort: [4.2, 5.5, 6.0, 4.0, 5.0, 3.5, 2.0],
          activities: [
            GoalActivity(
              id: 'act_1',
              title: 'Completed "Review Module 1"',
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
              type: ActivityType.taskCompleted,
              taskId: 'task_1',
            ),
            GoalActivity(
              id: 'act_0',
              title: 'Session Created',
              timestamp: DateTime.now().subtract(const Duration(days: 2)),
              type: ActivityType.goalCreated,
            ),
          ],
        )
      ];
      await saveGoals();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String goalsJson = jsonEncode(_goals.map((g) => g.toJson()).toList());
    await prefs.setString(_storageKey, goalsJson);
    notifyListeners();
  }

  void addGoal(Goal goal) {
    _goals.insert(0, goal);
    saveGoals();
  }

  void updateGoal(Goal goal) {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      saveGoals();
    }
  }

  void deleteGoal(String goalId) {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = _goals[goalIndex];
      // Cleanup any active sessions for this goal's tasks
      for (var task in goal.tasks) {
        SessionManager().deleteSession(task.id);
      }
      _goals.removeAt(goalIndex);
      saveGoals();
    }
  }

  // Task specific updates to trigger notifyListeners properly
  void addTask(String goalId, GoalTask task) {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.tasks.add(task);
    goal.activities.insert(0, GoalActivity(
      id: DateTime.now().toString(),
      title: 'Added task "${task.name}"',
      timestamp: DateTime.now(),
      type: ActivityType.taskAdded,
      taskId: task.id,
    ));
    saveGoals();
  }

  void toggleTaskCompletion(String goalId, String taskId) {
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
    saveGoals();
  }

  void deleteTask(String goalId, String taskId) {
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
      saveGoals();
    }
  }

  void addActivities(String goalId, List<GoalActivity> activities) {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.activities.addAll(activities);
    goal.activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    saveGoals();
  }

  void addSessionToTask(String goalId, String taskId, FocusSession session) {
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
    
    saveGoals();
  }
}
