import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low, milestone }

enum GoalStatus { active, completed, paused }
enum SessionStatus { active, paused, completed }
enum FocusSessionType { free, timed }

enum ActivityType { taskCompleted, sessionCompleted, taskAdded, goalCreated }

class FocusSession {
  final String id;
  final Duration duration;
  final double intensity;
  final int focusScore;
  final List<double> trendData;
  final DateTime timestamp;

  FocusSession({
    required this.id,
    required this.duration,
    required this.intensity,
    required this.focusScore,
    required this.trendData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'duration': duration.inSeconds,
    'intensity': intensity,
    'focusScore': focusScore,
    'trendData': trendData,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'],
    duration: Duration(seconds: json['duration']),
    intensity: json['intensity'],
    focusScore: json['focusScore'],
    trendData: List<double>.from(json['trendData']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class GoalTask {
  String id;
  String name;
  TaskPriority priority;
  DateTime deadline;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? completedAt;
  Duration? timeSpent;
  List<FocusSession> sessions;
  FocusSessionType? sessionType;
  int? defaultDuration; // seconds

  GoalTask({
    required this.id,
    required this.name,
    this.priority = TaskPriority.medium,
    required this.deadline,
    this.isCompleted = false,
    this.completedAt,
    this.timeSpent,
    List<FocusSession>? sessions,
    this.sessionType,
    this.defaultDuration,
    DateTime? createdAt,
  })  : sessions = sessions ?? [],
        createdAt = createdAt ?? DateTime.now();

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low Priority';
      case TaskPriority.milestone:
        return 'Milestone';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priority': priority.name,
    'deadline': deadline.toIso8601String(),
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'timeSpent': timeSpent?.inSeconds,
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'sessionType': sessionType?.name,
    'defaultDuration': defaultDuration,
  };

  factory GoalTask.fromJson(Map<String, dynamic> json) => GoalTask(
    id: json['id'],
    name: json['name'],
    priority: TaskPriority.values.byName(json['priority']),
    deadline: DateTime.parse(json['deadline']),
    isCompleted: json['isCompleted'],
    createdAt: DateTime.parse(json['createdAt']),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    timeSpent: json['timeSpent'] != null ? Duration(seconds: json['timeSpent']) : null,
    sessions: (json['sessions'] as List).map((s) => FocusSession.fromJson(s)).toList(),
    sessionType: json['sessionType'] != null ? FocusSessionType.values.byName(json['sessionType']) : null,
    defaultDuration: json['defaultDuration'],
  );
}

class ActiveSession {
  final String sessionId;
  final String taskId;
  final String goalId;
  SessionStatus status;
  int totalElapsedTime; // milliseconds
  int? totalDuration; // milliseconds (for timed sessions)
  DateTime? lastResumeTime;
  DateTime? pausedAt;
  DateTime? endedAt;

  ActiveSession({
    required this.sessionId,
    required this.taskId,
    required this.goalId,
    this.status = SessionStatus.active,
    this.totalElapsedTime = 0,
    this.totalDuration,
    this.lastResumeTime,
    this.pausedAt,
    this.endedAt,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'taskId': taskId,
    'goalId': goalId,
    'status': status.name,
    'totalElapsedTime': totalElapsedTime,
    'totalDuration': totalDuration,
    'lastResumeTime': lastResumeTime?.toIso8601String(),
    'pausedAt': pausedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };

  factory ActiveSession.fromJson(Map<String, dynamic> json) => ActiveSession(
    sessionId: json['sessionId'],
    taskId: json['taskId'],
    goalId: json['goalId'],
    status: SessionStatus.values.byName(json['status']),
    totalElapsedTime: json['totalElapsedTime'],
    totalDuration: json['totalDuration'],
    lastResumeTime: json['lastResumeTime'] != null ? DateTime.parse(json['lastResumeTime']) : null,
    pausedAt: json['pausedAt'] != null ? DateTime.parse(json['pausedAt']) : null,
    endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
  );
}

class GoalActivity {
  final String id;
  final String title;
  final DateTime timestamp;
  final ActivityType type;
  final String? taskId;

  GoalActivity({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.type,
    this.taskId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'taskId': taskId,
  };

  factory GoalActivity.fromJson(Map<String, dynamic> json) => GoalActivity(
    id: json['id'],
    title: json['title'],
    timestamp: DateTime.parse(json['timestamp']),
    type: ActivityType.values.byName(json['type']),
    taskId: json['taskId'],
  );
}

class Goal {
  final String id;
  String title;
  String description;
  DateTime dueDate;
  GoalStatus status;
  IconData icon;
  String? imageUrl;
  List<GoalTask> tasks;
  List<GoalActivity> activities;
  Duration totalTimeSpent;
  int currentStreak;
  List<double> dailyEffort; // 7 values for Mon-Sun
  String workspaceId;

  Goal({
    required this.id,
    this.workspaceId = 'personal',
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = GoalStatus.active,
    this.icon = Icons.flag,
    this.imageUrl,
    List<GoalTask>? tasks,
    List<GoalActivity>? activities,
    this.totalTimeSpent = Duration.zero,
    this.currentStreak = 0,
    List<double>? dailyEffort,
  })  : tasks = tasks ?? [],
        activities = activities ?? [],
        dailyEffort = dailyEffort ?? List.filled(7, 0.0);

  double get progress {
    if (tasks.isEmpty) return 0.0;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    return completedCount / tasks.length;
  }

  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;

  GoalTask? get nextMilestoneTask {
    final milestoneTasks = tasks.where((t) => t.priority == TaskPriority.milestone && !t.isCompleted).toList();
    if (milestoneTasks.isEmpty) return null;

    milestoneTasks.sort((a, b) {
      final cmp = a.deadline.compareTo(b.deadline);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    return milestoneTasks.first;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'status': status.name,
    'iconCode': icon.codePoint,
    'imageUrl': imageUrl,
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'activities': activities.map((a) => a.toJson()).toList(),
    'totalTimeSpent': totalTimeSpent.inSeconds,
    'currentStreak': currentStreak,
    'dailyEffort': dailyEffort,
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'],
    workspaceId: json['workspaceId'] ?? 'personal',
    title: json['title'],
    description: json['description'],
    dueDate: DateTime.parse(json['dueDate']),
    status: GoalStatus.values.byName(json['status']),
    icon: IconData(json['iconCode'], fontFamily: 'MaterialIcons'),
    imageUrl: json['imageUrl'],
    tasks: (json['tasks'] as List).map((t) => GoalTask.fromJson(t)).toList(),
    activities: (json['activities'] as List).map((a) => GoalActivity.fromJson(a)).toList(),
    totalTimeSpent: Duration(seconds: json['totalTimeSpent'] ?? 0),
    currentStreak: json['currentStreak'] ?? 0,
    dailyEffort: () {
      final list = List<double>.from(json['dailyEffort'] ?? []);
      if (list.length == 7) return list;
      return List.filled(7, 0.0);
    }(),
  );

  Goal copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    GoalStatus? status,
    IconData? icon,
    String? imageUrl,
    List<GoalTask>? tasks,
    List<GoalActivity>? activities,
    Duration? totalTimeSpent,
    int? currentStreak,
    List<double>? dailyEffort,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      tasks: tasks ?? this.tasks,
      activities: activities ?? this.activities,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyEffort: dailyEffort ?? this.dailyEffort,
    );
  }
}
