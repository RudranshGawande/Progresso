import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progresso/models/workspace_models.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/services/goal_service.dart';

class WorkspaceService extends ChangeNotifier {
  static final WorkspaceService _instance = WorkspaceService._internal();
  factory WorkspaceService() => _instance;
  WorkspaceService._internal();

  /// Returns a user-specific storage key so each user's data is isolated.
  String get _storageKey {
    final user = AuthService().currentUser;
    final userId = user?['userId'] ?? 'default';
    return 'progresso_communities_$userId';
  }

  bool get _isDemoUser {
    final user = AuthService().currentUser;
    return user?['email'] == 'demo@progressor.com' || 
           user?['userId'] == 'demo_user_id_123';
  }
  
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
    } else if (_isDemoUser) {
      // Create a default community only for demo account
      _communities = [
        Community(
          id: 'ietk_space',
          name: 'IETK',
          description: 'Specialized group for research and development of engineering projects.',
          members: [
            CommunityMember(
              id: 'owner_1',
              name: 'Alex Rivera',
              email: 'alex@progresso.com',
              avatarUrl: 'https://i.pravatar.cc/150?img=11',
              role: CommunityRole.owner,
            ),
          ],
          communitySessions: [],
        ),
      ];

      // Provision mock goals for the default community
      for (var c in _communities) {
         GoalService().generateCommunityMockData(c.id, c.name);
      }
      
      await saveCommunities();
    } else {
      // For real users: start with empty communities
      _communities = [];
      await saveCommunities();
    }
    _initialized = true;
    notifyListeners();
  }

  /// Resets the initialization flag so the service can be re-initialized
  /// for a different user (e.g., after login/logout).
  void reset() {
    _initialized = false;
    _communities = [];
    _activeType = WorkspaceType.personal;
    _activeCommunity = null;
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
    
    // Notify GoalService to refresh its filtered view
    GoalService().notifyListeners();
    
    notifyListeners();
  }

  void addCommunity(Community community) {
    _communities.add(community);
    
    // Generate mock data only for demo users
    GoalService().generateCommunityMockData(community.id, community.name);
    
    saveCommunities();
  }

  void deleteCommunity(String communityId) {
    _communities.removeWhere((c) => c.id == communityId);
    if (_activeCommunity?.id == communityId) {
      switchWorkspace(WorkspaceType.personal);
    } else {
      saveCommunities();
    }
  }
}
