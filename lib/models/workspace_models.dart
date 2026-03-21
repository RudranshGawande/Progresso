import 'package:flutter/material.dart';

enum WorkspaceType { personal, community }

enum CommunityRole { owner, admin, member }

class Community {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final List<CommunityMember> members;
  final List<Session> communitySessions;

  Community({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.members,
    required this.communitySessions,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      members: (json['members'] as List).map((m) => CommunityMember.fromJson(m)).toList(),
      communitySessions: (json['communitySessions'] as List).map((s) => Session.fromJson(s)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'members': members.map((m) => m.toJson()).toList(),
      'communitySessions': communitySessions.map((s) => s.toJson()).toList(),
    };
  }
}

class CommunityMember {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final CommunityRole role;

  CommunityMember({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      role: CommunityRole.values.firstWhere((e) => e.toString() == json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.toString(),
    };
  }
}

class Session {
  final String id;
  final String title;
  final String? description;
  final List<Assignment> assignments;
  final List<String> memberAvatars;
  final bool isArchived;

  Session({
    required this.id,
    required this.title,
    this.description,
    required this.assignments,
    required this.memberAvatars,
    this.isArchived = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      assignments: (json['assignments'] as List).map((a) => Assignment.fromJson(a)).toList(),
      memberAvatars: List<String>.from(json['memberAvatars']),
      isArchived: json['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignments': assignments.map((a) => a.toJson()).toList(),
      'memberAvatars': memberAvatars,
      'isArchived': isArchived,
    };
  }
}

class Assignment {
  final String id;
  final String title;
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeAvatar;
  final DateTime? deadline;
  final AssignmentStatus status;

  Assignment({
    required this.id,
    required this.title,
    this.assigneeId,
    this.assigneeName,
    this.assigneeAvatar,
    this.deadline,
    this.status = AssignmentStatus.todo,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      title: json['title'],
      assigneeId: json['assigneeId'],
      assigneeName: json['assigneeName'],
      assigneeAvatar: json['assigneeAvatar'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: AssignmentStatus.values.firstWhere((e) => e.toString() == json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneeAvatar': assigneeAvatar,
      'deadline': deadline?.toIso8601String(),
      'status': status.toString(),
    };
  }
}

enum AssignmentStatus { todo, inProgress, completed }
