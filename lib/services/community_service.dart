import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/models/workspace_models.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/services/api_service.dart';
import 'package:progresso/services/workspace_service.dart';
import 'dart:developer' as developer;

class CommunityService extends ChangeNotifier {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  String get _storageKey {
    final user = AuthService().currentUser;
    final userId = user?['userId'] ?? 'default';
    return 'progresso_community_data_$userId';
  }

  Map<String, CommunityData> _communityData = {};
  List<TeamActivity> _activities = [];
  bool _initialized = false;

  Map<String, CommunityData> get communityData => _communityData;
  List<TeamActivity> get activities => _activities;

  Future<void> init() async {
    if (_initialized) return;
    await _loadFromStorage();
    _initialized = true;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        _communityData = data.map((key, value) {
          return MapEntry(key, CommunityData.fromJson(value));
        });
        if (data['activities'] != null) {
          _activities = (data['activities'] as List)
              .map((a) => TeamActivity.fromJson(a))
              .toList();
        }
      }
    } catch (e) {
      developer.log('⚠️ Failed to load community data from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final communityMap = _communityData.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      final storageData = <String, dynamic>{
        ...communityMap,
        'activities': _activities.map((a) => a.toJson()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(storageData));
    } catch (e) {
      developer.log('⚠️ Failed to save community data: $e');
    }
  }

  CommunityData? getData(String communityId) => _communityData[communityId];

  Future<void> refreshCommunityData(Community community) async {
    final dbId = WorkspaceService().getCommunityDbId(community.id);
    if (dbId == null) return;

    final result = await ApiService().getCommunityWorkspace(workspaceId: dbId);
    if (result == null) return;

    final workspaceData = result['workspace'];
    final assignmentsData = result['assignments'] as List? ?? [];

    final updatedMembers = (workspaceData['members'] as List? ?? [])
        .map(
          (m) => CommunityMember(
            id: m['userId']?.toString() ?? m['_id']?.toString() ?? '',
            name: m['name'] ?? m['email'] ?? 'Unknown',
            email: m['email'] ?? '',
            avatarUrl: m['avatarUrl'] ?? '',
            role: _parseRole(m['role']),
          ),
        )
        .toList();

    final updatedSessions = <Session>[];
    for (var session in community.communitySessions) {
      final sessionAssignments = assignmentsData
          .where(
            (a) =>
                a['sessionId'] == session.id ||
                a['sessionId']?.toString() == session.id,
          )
          .map(
            (a) => Assignment(
              id: a['_id']?.toString() ?? a['id'] ?? '',
              title: a['title'] ?? '',
              assignedTo: a['assigneeId']?.toString(),
              assigneeName: a['assigneeName'],
              assigneeAvatar: a['assigneeAvatar'],
              deadline: a['deadline'] != null
                  ? DateTime.parse(a['deadline'])
                  : null,
              status: _parseAssignmentStatus(a['status']),
            ),
          )
          .toList();

      updatedSessions.add(
        Session(
          id: session.id,
          title: session.title,
          description: session.description,
          memberAvatars: session.memberAvatars,
          isArchived: session.isArchived,
          assignments: sessionAssignments,
        ),
      );
    }

    final updatedCommunity = Community(
      id: community.id,
      name: community.name,
      description: community.description,
      icon: community.icon,
      members: updatedMembers,
      communitySessions: updatedSessions,
    );

    _communityData[community.id] = CommunityData(
      community: updatedCommunity,
      lastUpdated: DateTime.now(),
    );

    await _saveToStorage();
    notifyListeners();
  }

  Future<bool> inviteMember(String communityId, String email) async {
    final dbId = WorkspaceService().getCommunityDbId(communityId);
    if (dbId == null) return false;

    final result = await ApiService().addMember(
      workspaceId: dbId,
      email: email,
    );
    if (result == null) return false;

    final data = _communityData[communityId];
    if (data != null) {
      final newMember = CommunityMember(
        id: result['_id']?.toString() ?? '',
        name: result['email']?.split('@')[0] ?? 'New Member',
        email: email,
        avatarUrl: '',
        role: CommunityRole.member,
      );

      final updatedMembers = List<CommunityMember>.from(data.community.members)
        ..add(newMember);
      _communityData[communityId] = CommunityData(
        community: Community(
          id: data.community.id,
          name: data.community.name,
          description: data.community.description,
          icon: data.community.icon,
          members: updatedMembers,
          communitySessions: data.community.communitySessions,
        ),
        lastUpdated: DateTime.now(),
      );

      _addActivity(
        TeamActivity(
          member: newMember,
          action: 'joined',
          target: data.community.name,
          time: DateTime.now(),
        ),
      );
    }

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<bool> createTask({
    required String communityId,
    required String taskId,
    required String title,
    String? assigneeId,
    String? assigneeName,
    String? assigneeAvatar,
    DateTime? deadline,
    String? description,
  }) async {
    final dbId = WorkspaceService().getCommunityDbId(communityId);
    if (dbId == null) return false;

    final assignmentId = await ApiService().createAssignment(
      workspaceId: dbId,
      taskId: taskId,
      title: title,
      description: description,
      assignedTo: assigneeId,
      assigneeName: assigneeName,
      assigneeAvatar: assigneeAvatar,
      deadline: deadline,
      status: 'pending',
    );

    if (assignmentId == null) return false;

    final data = _communityData[communityId];
    if (data != null) {
      final newAssignment = Assignment(
        id: assignmentId,
        title: title,
        assignedTo: assigneeId,
        assigneeName: assigneeName,
        assigneeAvatar: assigneeAvatar,
        deadline: deadline,
        status: AssignmentStatus.todo,
      );

      final updatedSessions = data.community.communitySessions.map((s) {
        final hasTask = s.assignments.any((a) => a.title == title);
        if (!hasTask) {
          return Session(
            id: s.id,
            title: s.title,
            description: s.description,
            memberAvatars: s.memberAvatars,
            isArchived: s.isArchived,
            assignments: [...s.assignments, newAssignment],
          );
        }
        return s;
      }).toList();

      _communityData[communityId] = CommunityData(
        community: Community(
          id: data.community.id,
          name: data.community.name,
          description: data.community.description,
          icon: data.community.icon,
          members: data.community.members,
          communitySessions: updatedSessions,
        ),
        lastUpdated: DateTime.now(),
      );

      if (assigneeName != null) {
        final currentUser = AuthService().currentUser;
        _addActivity(
          TeamActivity(
            member: currentUser != null
                ? CommunityMember(
                    id: currentUser['userId']?.toString() ?? '',
                    name: currentUser['name'] ?? 'You',
                    email: currentUser['email'] ?? '',
                    avatarUrl: currentUser['avatarBase64'] ?? '',
                    role: CommunityRole.admin,
                  )
                : null,
            action: 'assigned',
            target: '"$title" to $assigneeName',
            time: DateTime.now(),
          ),
        );
      } else {
        _addActivity(
          TeamActivity(
            member: null,
            action: 'created',
            target: 'task "$title" (unassigned)',
            time: DateTime.now(),
          ),
        );
      }
    }

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<bool> assignTask({
    required String communityId,
    required String taskId,
    required String title,
    required String assigneeId,
    required String assigneeName,
    String? assigneeAvatar,
    DateTime? deadline,
    String? description,
  }) async {
    final dbId = WorkspaceService().getCommunityDbId(communityId);
    if (dbId == null) return false;

    final result = await ApiService().createAssignment(
      workspaceId: dbId,
      taskId: taskId,
      title: title,
      description: description,
      assignedTo: assigneeId,
      assigneeName: assigneeName,
      assigneeAvatar: assigneeAvatar,
      deadline: deadline,
      status: 'pending',
    );

    if (result == null) return false;

    final resultMap = result as Map<String, dynamic>;
    final data = _communityData[communityId];
    if (data != null) {
      final idValue = resultMap['_id'];
      String assignmentId;
      if (idValue is Map) {
        assignmentId = (idValue['\$oid'] ?? idValue['_id'] ?? '').toString();
      } else {
        assignmentId = idValue?.toString() ?? '';
      }
      final newAssignment = Assignment(
        id: assignmentId,
        title: title,
        assignedTo: assigneeId,
        assigneeName: assigneeName,
        assigneeAvatar: assigneeAvatar,
        deadline: deadline,
        status: AssignmentStatus.todo,
      );

      final updatedSessions = data.community.communitySessions.map((s) {
        final hasTask = s.assignments.any((a) => a.title == title);
        if (!hasTask) {
          return Session(
            id: s.id,
            title: s.title,
            description: s.description,
            memberAvatars: s.memberAvatars,
            isArchived: s.isArchived,
            assignments: [...s.assignments, newAssignment],
          );
        }
        return s;
      }).toList();

      _communityData[communityId] = CommunityData(
        community: Community(
          id: data.community.id,
          name: data.community.name,
          description: data.community.description,
          icon: data.community.icon,
          members: data.community.members,
          communitySessions: updatedSessions,
        ),
        lastUpdated: DateTime.now(),
      );

      final currentUser = AuthService().currentUser;
      _addActivity(
        TeamActivity(
          member: currentUser != null
              ? CommunityMember(
                  id: currentUser['userId']?.toString() ?? '',
                  name: currentUser['name'] ?? 'You',
                  email: currentUser['email'] ?? '',
                  avatarUrl: currentUser['avatarBase64'] ?? '',
                  role: CommunityRole.admin,
                )
              : null,
          action: 'assigned',
          target: '"$title" to $assigneeName',
          time: DateTime.now(),
        ),
      );
    }

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<bool> claimTask(String communityId, String assignmentId) async {
    final result = await ApiService().claimAssignment(
      assignmentId: assignmentId,
    );
    if (result == null) return false;

    final data = _communityData[communityId];
    if (data != null) {
      final currentUser = AuthService().currentUser;
      final updatedSessions = data.community.communitySessions.map((s) {
        final updatedAssignments = s.assignments.map((a) {
          if (a.id == assignmentId) {
            return Assignment(
              id: a.id,
              title: a.title,
              assignedTo: currentUser?['userId']?.toString(),
              assigneeName: currentUser?['name'] ?? 'You',
              assigneeAvatar: '',
              deadline: a.deadline,
              status: AssignmentStatus.inProgress,
            );
          }
          return a;
        }).toList();
        return Session(
          id: s.id,
          title: s.title,
          description: s.description,
          memberAvatars: s.memberAvatars,
          isArchived: s.isArchived,
          assignments: updatedAssignments,
        );
      }).toList();

      _communityData[communityId] = CommunityData(
        community: Community(
          id: data.community.id,
          name: data.community.name,
          description: data.community.description,
          icon: data.community.icon,
          members: data.community.members,
          communitySessions: updatedSessions,
        ),
        lastUpdated: DateTime.now(),
      );

      _addActivity(
        TeamActivity(
          member: currentUser != null
              ? CommunityMember(
                  id: currentUser['userId']?.toString() ?? '',
                  name: currentUser['name'] ?? 'You',
                  email: currentUser['email'] ?? '',
                  avatarUrl: '',
                  role: CommunityRole.member,
                )
              : null,
          action: 'claimed',
          target: result['title'] ?? 'a task',
          time: DateTime.now(),
        ),
      );
    }

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<bool> updateTaskStatus(
    String communityId,
    String assignmentId,
    AssignmentStatus newStatus,
  ) async {
    final apiStatus = _toApiStatus(newStatus);
    await ApiService().updateAssignment(
      assignmentId: assignmentId,
      status: apiStatus,
    );

    final data = _communityData[communityId];
    if (data != null) {
      final updatedSessions = data.community.communitySessions.map((s) {
        final updatedAssignments = s.assignments.map((a) {
          if (a.id == assignmentId) {
            return Assignment(
              id: a.id,
              title: a.title,
              assignedTo: a.assignedTo,
              assigneeName: a.assigneeName,
              assigneeAvatar: a.assigneeAvatar,
              deadline: a.deadline,
              status: newStatus,
            );
          }
          return a;
        }).toList();
        return Session(
          id: s.id,
          title: s.title,
          description: s.description,
          memberAvatars: s.memberAvatars,
          isArchived: s.isArchived,
          assignments: updatedAssignments,
        );
      }).toList();

      _communityData[communityId] = CommunityData(
        community: Community(
          id: data.community.id,
          name: data.community.name,
          description: data.community.description,
          icon: data.community.icon,
          members: data.community.members,
          communitySessions: updatedSessions,
        ),
        lastUpdated: DateTime.now(),
      );
    }

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<bool> removeMember(String communityId, String userId) async {
    final dbId = WorkspaceService().getCommunityDbId(communityId);
    if (dbId == null) return false;

    final result = await ApiService().removeMember(
      workspaceId: dbId,
      userId: userId,
    );
    if (result == null) return false;

    final data = _communityData[communityId];
    if (data != null) {
      final updatedMembers = data.community.members
          .where((m) => m.id != userId)
          .toList();
      _communityData[communityId] = CommunityData(
        community: Community(
          id: data.community.id,
          name: data.community.name,
          description: data.community.description,
          icon: data.community.icon,
          members: updatedMembers,
          communitySessions: data.community.communitySessions,
        ),
        lastUpdated: DateTime.now(),
      );
    }

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<bool> updateMemberRole(
    String communityId,
    String userId,
    CommunityRole role,
  ) async {
    final dbId = WorkspaceService().getCommunityDbId(communityId);
    if (dbId == null) return false;

    final result = await ApiService().updateMemberRole(
      workspaceId: dbId,
      userId: userId,
      role: role.name,
    );
    if (result == null) return false;

    final data = _communityData[communityId];
    if (data != null) {
      final updatedMembers = data.community.members.map((m) {
        if (m.id == userId) {
          return CommunityMember(
            id: m.id,
            name: m.name,
            email: m.email,
            avatarUrl: m.avatarUrl,
            role: role,
          );
        }
        return m;
      }).toList();

      _communityData[communityId] = CommunityData(
        community: Community(
          id: data.community.id,
          name: data.community.name,
          description: data.community.description,
          icon: data.community.icon,
          members: updatedMembers,
          communitySessions: data.community.communitySessions,
        ),
        lastUpdated: DateTime.now(),
      );
    }

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  void _addActivity(TeamActivity activity) {
    _activities.insert(0, activity);
    if (_activities.length > 50)
      _activities.removeRange(50, _activities.length);
  }

  void addLocalActivity(TeamActivity activity) {
    _addActivity(activity);
    _saveToStorage();
    notifyListeners();
  }

  CommunityRole _parseRole(String? role) {
    if (role == null) return CommunityRole.member;
    final clean = role.replaceAll('CommunityRole.', '');
    try {
      return CommunityRole.values.byName(clean);
    } catch (_) {
      return CommunityRole.member;
    }
  }

  AssignmentStatus _parseAssignmentStatus(String? status) {
    if (status == null) return AssignmentStatus.todo;
    switch (status) {
      case 'completed':
        return AssignmentStatus.completed;
      case 'in_progress':
        return AssignmentStatus.inProgress;
      default:
        return AssignmentStatus.todo;
    }
  }

  String _toApiStatus(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.todo:
        return 'pending';
      case AssignmentStatus.inProgress:
        return 'in_progress';
      case AssignmentStatus.completed:
        return 'completed';
    }
  }

  void reset() {
    _communityData.clear();
    _activities.clear();
    _initialized = false;
    notifyListeners();
  }
}

class CommunityData {
  final Community community;
  final DateTime lastUpdated;

  CommunityData({required this.community, required this.lastUpdated});

  factory CommunityData.fromJson(Map<String, dynamic> json) {
    return CommunityData(
      community: Community.fromJson(json['community']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community': community.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class TeamActivity {
  final CommunityMember? member;
  final String action;
  final String target;
  final DateTime time;

  TeamActivity({
    this.member,
    required this.action,
    required this.target,
    required this.time,
  });

  factory TeamActivity.fromJson(Map<String, dynamic> json) {
    return TeamActivity(
      member: json['member'] != null
          ? CommunityMember.fromJson(json['member'])
          : null,
      action: json['action'] ?? '',
      target: json['target'] ?? '',
      time: DateTime.parse(json['time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member': member?.toJson(),
      'action': action,
      'target': target,
      'time': time.toIso8601String(),
    };
  }
}
