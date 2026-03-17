import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/models/workspace_models.dart';

import 'package:progresso/services/goal_service.dart';

class WorkspaceService extends ChangeNotifier {
  static final WorkspaceService _instance = WorkspaceService._internal();
  factory WorkspaceService() => _instance;
  WorkspaceService._internal();

  static const String _storageKey = 'progresso_communities';
  
  WorkspaceType _activeType = WorkspaceType.personal;
  Community? _activeCommunity;
  List<Community> _communities = [];
  bool _initialized = false;

  WorkspaceType get activeType => _activeType;
  Community? get activeCommunity => _activeCommunity;
  List<Community> get communities => _communities;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final String? communitiesJson = prefs.getString(_storageKey);

    if (communitiesJson != null) {
      final List<dynamic> data = jsonDecode(communitiesJson);
      _communities = data.map((c) => Community.fromJson(c)).toList();
    } else {
      // Create a default community for demo
      _communities = [
        Community(
          id: 'ml_team_1',
          name: 'Machine Learning Team',
          description: 'Specialized group for research and development of ML models.',
          members: [
            CommunityMember(
              id: 'owner_1',
              name: 'Alex Rivera',
              email: 'alex@progresso.com',
              avatarUrl: 'https://i.pravatar.cc/150?img=11',
              role: CommunityRole.owner,
            ),
            CommunityMember(
              id: 'member_1',
              name: 'Sarah Chen',
              email: 'sarah@progresso.com',
              avatarUrl: 'https://i.pravatar.cc/150?img=32',
              role: CommunityRole.member,
            ),
            CommunityMember(
              id: 'member_2',
              name: 'James Wilson',
              email: 'james@progresso.com',
              avatarUrl: 'https://i.pravatar.cc/150?img=12',
              role: CommunityRole.admin,
            ),
          ],
          communitySessions: [
            Session(
              id: 'sess_ml_1',
              title: 'ML Model Training',
              description: 'Session for optimizing training hyperparameters.',
              assignments: [
                Assignment(
                  id: 'asg_1',
                  title: 'Clean Dataset',
                  assigneeId: 'member_1',
                  assigneeName: 'Sarah Chen',
                  assigneeAvatar: 'https://i.pravatar.cc/150?img=32',
                  status: AssignmentStatus.completed,
                ),
                Assignment(
                  id: 'asg_2',
                  title: 'Tune Weights',
                  assigneeId: 'owner_1',
                  assigneeName: 'Alex Rivera',
                  assigneeAvatar: 'https://i.pravatar.cc/150?img=11',
                  status: AssignmentStatus.inProgress,
                ),
              ],
              memberAvatars: [
                'https://i.pravatar.cc/150?img=11',
                'https://i.pravatar.cc/150?img=32',
                'https://i.pravatar.cc/150?img=12',
              ],
            ),
          ],
        ),
      ];
      await saveCommunities();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveCommunities() async {
    final prefs = await SharedPreferences.getInstance();
    final String communitiesJson = jsonEncode(_communities.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, communitiesJson);
    notifyListeners();
  }

  void switchWorkspace(WorkspaceType type, [Community? community]) {
    _activeType = type;
    _activeCommunity = community;
    
    // Sync GoalService with the new workspace
    if (type == WorkspaceType.personal) {
      GoalService().loadWorkspace('personal');
    } else if (community != null) {
      GoalService().loadWorkspace(community.id);
    }
    
    notifyListeners();
  }

  void addCommunity(Community community) {
    _communities.add(community);
    saveCommunities();
  }
}
