import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/models/workspace_models.dart';
import 'package:progresso/services/session_manager.dart';
import 'package:progresso/services/workspace_service.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/services/api_service.dart';
import 'dart:developer' as developer;

class GoalService extends ChangeNotifier {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

  List<Goal> _goals = [];
  bool _initialized = false;

  /// Returns a user-specific storage key so each user's data is isolated.
  String get _storageKey {
    final user = AuthService().currentUser;
    final userId = user?['userId'] ?? 'default';
    return 'progresso_goals_$userId';
  }

  bool get _isDemoUser {
    final user = AuthService().currentUser;
    return user?['email'] == 'demo@progressor.com' || 
           user?['email'] == 'demo@gmail.com' ||
           user?['userId'] == 'demo_user_id_123' ||
           user?['userId'] == 'demo_gmail_user_123';
  }

  Future<void> init({bool forceReset = false}) async {
    if (_initialized && !forceReset) return;
    final prefs = await SharedPreferences.getInstance();
    
    if (forceReset) {
      await prefs.remove(_storageKey);
    }

    final String? goalsJson = prefs.getString(_storageKey);

    if (goalsJson != null && !forceReset && !_isDemoUser) {
      final List<dynamic> data = jsonDecode(goalsJson);
      _goals = data.map((g) => Goal.fromJson(g)).toList();
    } else if (_isDemoUser) {
      // Only generate mock data for the demo account
      final user = AuthService().currentUser;
      if (user?['email'] == 'demo@gmail.com') {
        _goals = _generateGmailDemoGoals();
      } else {
        _goals = _generateDemoGoals();
      }
      await saveGoals();
    } else {
      // For real users: start with empty data — they create their own
      _goals = [];
      await saveGoals();
    }
    _initialized = true;
    notifyListeners();
  }

  /// Resets the initialization flag so the service can be re-initialized
  /// for a different user (e.g., after login/logout).
  void reset() {
    _initialized = false;
    _goals = [];
    notifyListeners();
  }

  List<Goal> get goals {
    final ws = WorkspaceService();
    final id = ws.activeType == WorkspaceType.personal ? 'personal' : ws.activeCommunity?.id ?? 'personal';
    return _goals.where((g) => g.workspaceId == id).toList();
  }

  void generateCommunityMockData(String workspaceId, String communityName) {
    // Only generate mock data for demo users
    if (!_isDemoUser) return;
    
    if (_goals.any((g) => g.workspaceId == workspaceId)) return;
    
    final now = DateTime.now();
    _goals.addAll([
      _createProfessionalGoal(
        '${workspaceId}_goal_1',
        workspaceId,
        '$communityName: Strategic Roadmap',
        'Long-term planning and foundational infrastructure setup.',
        'assets/images/development.png',
        Icons.rocket_launch,
        [
          'Market Research', 'Competitor Analysis', 'Resource Allocation', 
          'Tech Stack Selection', 'Infrastructure Setup', 'Initial Wireframes', 
          'Brand Identity', 'API Specifications', 'Database Schema', 
          'Security Review', 'Legal Compliance', 'Stakeholder Meeting', 
          'Budget Approval', 'Hiring Roadmap', 'Initial Prototype'
        ],
        now,
      ),
      _createProfessionalGoal(
        '${workspaceId}_goal_2',
        workspaceId,
        '$communityName: Agile Sprint 1',
        'Rapid development phase for core MVP features.',
        'assets/images/research.png',
        Icons.bolt,
        [
          'Auth System', 'User Profile UI', 'Data Synchronization', 
          'Real-time Updates', 'Error Handling', 'Logging Service', 
          'Unit Test Suite', 'Integration Tests', 'Performance Audit', 
          'Staging Deployment', 'QA Pass', 'Bug Scrub', 
          'Release Notes', 'User Documentation', 'Sprint Retrospective'
        ],
        now,
      ),
    ]);
    saveGoals();
  }

  List<Goal> getGoalsByWorkspace(String workspaceId) {
    return _goals.where((g) => g.workspaceId == workspaceId).toList();
  }

  // ── Demo data generation (only for demo@progresso.com) ─────────────
  List<Goal> _generateDemoGoals() {
    final now = DateTime.now();
    return [
      _createProfessionalGoal(
        'web_dev_2026',
        'personal',
        'Full-Stack Web Development',
        'Responsive e-commerce platform with real-time analytics.',
        'assets/images/development.png',
        Icons.code,
        [
          'Schema Design', 'Indexing', 'Auth Middleware', 'JWT Integration', 
          'UI Dashboard', 'Responsive Layout', 'Image Upload API', 
          'Unit Tests', 'CI/CD Pipeline', 'Vercel Deployment', 
          'Stripe Checkout', 'SEO Optimization', 'User Profile Page', 
          'Dark Mode Support', 'Accessibility Audit'
        ],
        now,
      ),
      _createProfessionalGoal(
        'ai_research',
        'personal',
        'AI Research & Implementation',
        'Exploring machine learning models for predictive maintenance.',
        'assets/images/research.png',
        Icons.psychology,
        [
          'Papers Review', 'Data Cleaning', 'TensorFlow Setup', 'Model Selection', 
          'Feature Engineering', 'Initial Training', 'Hyperparameter Tuning', 
          'Cross Validation', 'Inference Engine', 'Quantization', 
          'API Wrapper', 'Edge Deployment', 'Benchmarking', 
          'Documentation', 'Final Presentation'
        ],
        now,
      ),
      _createProfessionalGoal(
        'exam_prep',
        'personal',
        'CS Finals Preparation',
        'Comprehensive study of core algorithms and systems.',
        'assets/images/study.png',
        Icons.school,
        [
          'Dynamic Programming', 'Graph Theory', 'Search Algorithms', 'Big O Notation', 
          'Concurrency', 'Memory Management', 'Network Layers', 'TCP vs UDP', 
          'SQL Joins', 'Consensus Algorithms', 'Raft Protocol', 'Cache Consistency',
          'Distributed Hash Tables', 'OS Scheduling', 'Final Mock Test'
        ],
        now,
      ),
    ];
  }

  Goal _createSpecificGoal(String id, String title, String desc, String img, IconData icon, List<String> taskNames, DateTime now, String statusMode) {
    final tasks = <GoalTask>[];
    for (int i = 0; i < taskNames.length; i++) {
      String status = 'not_started';
      bool isComp = false;

      if (statusMode == 'completed') {
        status = 'completed';
        isComp = true;
      } else if (statusMode == 'not_started') {
        status = 'not_started';
        isComp = false;
      } else {
        // in_progress: complete half of the tasks
        if (i < taskNames.length / 2) {
          status = 'completed';
          isComp = true;
        } else {
          status = 'not_started';
          isComp = false;
        }
      }

      final deadline = now.add(Duration(days: (i - 5) * 2));
      
      TaskPriority priority;
      if (i % 4 == 0) priority = TaskPriority.high;
      else if (i % 4 == 1) priority = TaskPriority.medium;
      else if (i % 4 == 2) priority = TaskPriority.low;
      else priority = TaskPriority.milestone;

      List<FocusSession> sessions = [];
      if (status != 'not_started') {
        // For 'Today' data, generate some sessions around now
        sessions = _generateMockSessions(id + '_$i', 20, now);
      }

      final currentTask = GoalTask(
        id: '${id}_task_$i',
        name: taskNames[i],
        deadline: deadline,
        priority: priority,
        isCompleted: isComp,
        completedAt: isComp ? deadline : null,
        timeSpent: status != 'not_started' ? Duration(hours: (i % 5) + 1) : Duration.zero,
        sessions: sessions,
      );
      tasks.add(currentTask);
    }

    final activities = <GoalActivity>[];
    for (int i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      if (t.isCompleted) {
        activities.add(GoalActivity(
          id: '${id}_act_comp_$i',
          title: 'Task Completed: ${t.name}',
          timestamp: t.deadline,
          type: ActivityType.taskCompleted,
          taskId: t.id,
        ));
      }
      if (t.sessions.isNotEmpty) {
        activities.add(GoalActivity(
          id: '${id}_act_sess_$i',
          title: 'Focus Session: ${t.name}',
          timestamp: t.sessions.isNotEmpty ? t.sessions.last.timestamp : t.deadline,
          type: ActivityType.sessionCompleted,
          taskId: t.id,
        ));
      }
    }
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // For the demo showcase, we force all generated sessions to remain visually active 
    // so they appear on the Active Goals dashboard page without being hidden.
    GoalStatus goalStatus = GoalStatus.active;

    return Goal(
      id: id,
      workspaceId: 'personal',
      title: title,
      description: desc,
      dueDate: now.add(const Duration(days: 30)),
      icon: icon,
      imageUrl: img,
      status: goalStatus,
      tasks: tasks,
      activities: activities,
      totalTimeSpent: Duration(hours: statusMode == 'not_started' ? 0 : tasks.length * 2),
      dailyEffort: statusMode == 'not_started' ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] : [4.0, 5.0, 6.0, 3.5, 4.5, 2.0, 1.0],
    );
  }

  List<Goal> _generateGmailDemoGoals() {
    final now = DateTime.now();
    return [
      _createSpecificGoal(
        'gmail_goal_1',
        'Session 1: Application Design',
        'Initial wireframing and database schemas.',
        'assets/images/research.png',
        Icons.architecture,
        [
          'Define User Personas', 'Create Wireframes', 'Design Mockups', 'Collect Feedback',
          'Database Schema', 'API Endpoints Design', 'Auth Flow', 'Security Rules',
          'Project Structuring', 'Task Prioritization', 'Select Tech Stack', 'Approval'
        ],
        now,
        'completed'
      ),
      _createSpecificGoal(
        'gmail_goal_2',
        'Session 2: Core Implementation',
        'Coding the backend and essential features.',
        'assets/images/development.png',
        Icons.code,
        [
          'Init Repository', 'Setup CI/CD', 'Implement Login', 'Implement Registration',
          'Create Models', 'Write Services', 'Setup Routing', 'Connect Database',
          'State Management', 'Testing Providers', 'Error Handling', 'Logging'
        ],
        now,
        'in_progress'
      ),
      _createSpecificGoal(
        'gmail_goal_3',
        'Session 3: Quality Assurance',
        'Running all unit tests and finalizing launch.',
        'assets/images/study.png',
        Icons.bug_report,
        [
          'Write Unit Tests', 'Integration Testing', 'E2E Testing', 'Load Testing',
          'Fix UI Bugs', 'Optimize Performance', 'Review Codebase', 'Audit Security',
          'Write Documentation', 'Prepare Deployment', 'App Store Assets', 'Release'
        ],
        now,
        'not_started'
      )
    ];
  }

  Goal _createProfessionalGoal(String id, String workspaceId, String title, String desc, String img, IconData icon, List<String> taskNames, DateTime now) {
    final tasks = <GoalTask>[];
    for (int i = 0; i < taskNames.length; i++) {
      String status = 'not_started';
      bool isComp = false;
      if (i < taskNames.length / 3) {
        status = 'completed';
        isComp = true;
      } else if (i < (taskNames.length * 2) / 3) {
        status = 'in_progress';
      }

      final deadline = now.add(Duration(days: (i - 5) * 2));
      
      TaskPriority priority;
      if (i == 6 || i == 12) {
        priority = TaskPriority.milestone;
      } else {
        priority = i % 5 == 0 ? TaskPriority.high : (i % 3 == 0 ? TaskPriority.medium : TaskPriority.low);
      }

      final currentTask = GoalTask(
        id: '${id}_task_$i',
        name: taskNames[i],
        deadline: deadline,
        priority: priority,
        isCompleted: isComp,
        completedAt: isComp ? deadline : null,
        timeSpent: status != 'not_started' ? Duration(hours: (i % 5) + 1) : Duration.zero,
        sessions: status != 'not_started' ? _generateMockSessions(id, (i % 5) + 15, now) : [],
      );
      tasks.add(currentTask);
    }

    final activities = <GoalActivity>[];
    for (int i = 0; i < 3 && i < tasks.length; i++) {
      final t = tasks[i];
      activities.add(GoalActivity(
        id: '${id}_act_comp_$i',
        title: 'Task Completed: ${t.name}',
        timestamp: t.deadline,
        type: ActivityType.taskCompleted,
        taskId: t.id,
      ));
      activities.add(GoalActivity(
        id: '${id}_act_sess_$i',
        title: 'Focus Session: ${t.name}',
        timestamp: t.deadline.subtract(const Duration(hours: 2)),
        type: ActivityType.sessionCompleted,
        taskId: t.id,
      ));
    }
    // Newest activities first
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Goal(
      id: id,
      workspaceId: workspaceId,
      title: title,
      description: desc,
      dueDate: now.add(const Duration(days: 30)),
      icon: icon,
      imageUrl: img,
      status: GoalStatus.active,
      tasks: tasks,
      activities: activities,
      totalTimeSpent: Duration(hours: tasks.length * 2),
      dailyEffort: [4.0, 5.0, 6.0, 3.5, 4.5, 2.0, 1.0],
    );
  }

  static List<FocusSession> _generateMockSessions(String prefix, int initialCount, DateTime now) {
    final List<FocusSession> sessions = [];
    
    // Generate data for the last 365 days, including TODAY (index 0)
    for (int daysAgo = 0; daysAgo <= 365; daysAgo++) {
      bool isHighSeason = (daysAgo % 30 < 10);
      bool shouldAdd = (daysAgo < 14)
          || (daysAgo % 3 == 0)
          || (isHighSeason && daysAgo % 2 == 0); 
      
      if (shouldAdd) {
        final timestamp = now.subtract(Duration(days: daysAgo, hours: (daysAgo % 6) + 10)); 
        
        double baseIntensity = 0.5 + (0.3 * (daysAgo % 7 == 0 ? 0.8 : (daysAgo % 2 == 0 ? 0.2 : 0.5)));
        double randomNoise = (daysAgo % 5) * 0.05;
        double intensity = (baseIntensity + randomNoise).clamp(0.2, 0.95);

        sessions.add(FocusSession(
          id: 's_${prefix}_$daysAgo',
          duration: Duration(minutes: 50 + (daysAgo % 45)),
          intensity: intensity,
          focusScore: 75 + (daysAgo % 5) * 4,
          trendData: [0.4, 0.6, 0.5, 0.8],
          timestamp: timestamp,
        ));
      }
    }
    return sessions;
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
      
      ApiService().updateGoal(
        goalId: goal.id,
        name: goal.title,
        description: goal.description,
      );
    }
  }

  void deleteGoal(String goalId) {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = _goals[goalIndex];
      for (var task in goal.tasks) {
        SessionManager().deleteSession(task.id);
      }
      _goals.removeAt(goalIndex);
      saveGoals();
    }
  }

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

    // Persist to backend (best-effort, non-blocking)
    final user = AuthService().currentUser;
    final workspaceId = goal.workspaceId == 'personal'
        ? (user?['defaultPersonalWorkspaceId']?.toString() ?? '')
        : goal.workspaceId;

    if (workspaceId.isNotEmpty && !_isDemoUser) {
      ApiService().createTask(
        goalId: goalId,
        workspaceId: workspaceId,
        name: task.name,
        priority: task.priority.name,
        deadline: task.deadline,
        sessionType: task.sessionType?.name ?? 'timed',
        totalAllocatedTime: task.defaultDuration ?? 1500,
      ).then((dbId) {
        if (dbId != null) {
          task.id = dbId; // Replace the temporary local ID with the true Mongo ObjectId
          saveGoals();
          developer.log('📋 TASK synced to DB: $dbId for "${task.name}"');
        }
      });
    }
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
      goal.activities.removeWhere((a) => a.taskId == taskId && a.type == ActivityType.taskCompleted);
    }
    saveGoals();
  }

  void deleteTask(String goalId, String taskId) {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final taskIndex = goal.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = goal.tasks[taskIndex];
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

  void addSessionToTask(String goalId, String taskId, FocusSession session) {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final task = goal.tasks.firstWhere((t) => t.id == taskId);
    task.sessions.add(session);
    task.timeSpent = (task.timeSpent ?? Duration.zero) + session.duration;
    goal.totalTimeSpent += session.duration;
    final dayIndex = (session.timestamp.weekday - 1);
    goal.dailyEffort[dayIndex] += session.duration.inMinutes / 60.0;
    
    goal.activities.insert(0, GoalActivity(
      id: DateTime.now().toString(),
      title: 'Focus session: ${session.duration.inMinutes}m',
      timestamp: session.timestamp,
      type: ActivityType.sessionCompleted,
      taskId: task.id,
    ));
    saveGoals();

    // Persist to backend: create a Session document then a Task document under it
    final user = AuthService().currentUser;
    final workspaceId = goal.workspaceId == 'personal'
        ? (user?['defaultPersonalWorkspaceId']?.toString() ?? '')
        : goal.workspaceId;

    if (workspaceId.isNotEmpty && !_isDemoUser) {
      _persistFocusSessionToDb(
        goal: goal,
        task: task,
        session: session,
        workspaceId: workspaceId,
      );
    }
  }

  /// Persists a focus session to MongoDB:
  /// 1. Creates a Session document (linked to Goal via goalId)
  /// 2. The backend automatically pushes session._id into Goal.sessionIds
  /// 3. Updates the existing Task document's timer metrics (no duplicate)
  Future<void> _persistFocusSessionToDb({
    required Goal goal,
    required GoalTask task,
    required FocusSession session,
    required String workspaceId,
  }) async {
    try {
      // Only pass taskIds if the task has a valid MongoDB ObjectId (24 hex chars)
      final bool taskHasDbId = RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(task.id);

      // 1. Create the Session record (backend links it to Goal.sessionIds automatically)
      await ApiService().createSession(
        workspaceId: workspaceId,
        goalId: goal.id,
        goalName: goal.title,
        taskIds: taskHasDbId ? [task.id] : [],
      );

      // 2. Update the existing task metrics only if it has a valid DB ID
      if (taskHasDbId) {
        await ApiService().updateTask(
          taskId: task.id,
          totalAllocatedTime: (task.timeSpent?.inSeconds ?? 0),
          sessionType: task.sessionType?.name ?? 'timed',
        );
      }

      developer.log('FOCUS SESSION SYNCED TO DB | Goal: ${goal.title} | Task: ${task.name}');
    } catch (e) {
      developer.log('❌ PERSIST SESSION ERROR: $e');
    }
  }

  void addActivities(String goalId, List<GoalActivity> newActivities) {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.activities.addAll(newActivities);
    goal.activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    saveGoals();
  }
}
