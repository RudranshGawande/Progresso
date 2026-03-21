import 'dart:async';
import 'package:flutter/material.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/widgets/responsive.dart';
import 'package:progresso/widgets/sidebar.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/screens/dashboard_screen.dart';
import 'package:progresso/screens/goal_detail_screen.dart';
import 'package:progresso/screens/goals_overview_screen.dart';
import 'package:progresso/screens/goal_archive_screen.dart';
import 'package:progresso/screens/focus_summary_screen.dart';
import 'package:progresso/screens/analysis_screen.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/screens/profile_screen.dart';
import 'package:progresso/models/workspace_models.dart';
import 'package:progresso/services/workspace_service.dart';
import 'package:progresso/screens/community_dashboard_screen.dart';
import 'package:progresso/screens/community_analysis_screen.dart';
import 'package:progresso/screens/community_goals_screen.dart';
import 'package:progresso/theme/settings_notifier.dart';
import 'package:progresso/services/security_service.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _activeTab = 'Dashboard';
  bool _showingGoalDetail = false;
  bool _showingArchive = false;
  Goal? _selectedGoal;

  Timer? _sessionValidationTimer;

  @override
  void initState() {
    super.initState();
    // Default selected goal if goals exist
    if (GoalService().goals.isNotEmpty) {
      _selectedGoal = GoalService().goals.first;
    }
    
    // Periodic check to see if THIS device was logged out from another device
    _startSessionGuard();
  }

  void _startSessionGuard() {
    _sessionValidationTimer?.cancel();
    _sessionValidationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      final isValid = await SecurityService().validateCurrentSession();
      if (!isValid && mounted) {
        timer.cancel();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => AuthScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _sessionValidationTimer?.cancel();
    super.dispose();
  }

  void _onNavChange(String item) {
    setState(() {
      _activeTab = item;
      _showingGoalDetail = false;
      _showingArchive = false;
    });
    // Close drawer if open
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  void _openGoalDetail(Goal goal) {
    setState(() {
      _selectedGoal = goal;
      _showingGoalDetail = true;
      _showingArchive = false;
    });
  }

  void _openSessionSummary(Goal goal, GoalTask task, FocusSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusSummaryScreen(
          goal: goal,
          task: task,
          session: session,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsNotifier = Provider.of<SettingsNotifier>(context);
    return ListenableBuilder(
      listenable: Listenable.merge([GoalService(), WorkspaceService(), settingsNotifier]),
      builder: (context, _) {
        final goals = GoalService().goals;
        
        // Ensure _selectedGoal is still valid after a deletion or update
        if (_selectedGoal != null) {
          try {
            _selectedGoal = goals.firstWhere((g) => g.id == _selectedGoal!.id);
          } catch (_) {
            _selectedGoal = goals.isNotEmpty ? goals.first : null;
          }
        } else if (goals.isNotEmpty) {
          _selectedGoal = goals.first;
        }

        Widget content;
        
        final wsService = WorkspaceService();
        final activeWS = wsService.activeType;
        final community = wsService.activeCommunity;
        
        if (_activeTab == 'Dashboard') {
          if (activeWS == WorkspaceType.community && community != null) {
            content = CommunityDashboardScreen(community: community);
          } else {
            content = DashboardScreen(
              onGoalTap: (Goal goal) => _openGoalDetail(goal),
              onSessionTap: (goal, task, session) => _openSessionSummary(goal, task, session),
              onViewAllGoals: () => _onNavChange('Goals'),
            );
          }
        } else if (_activeTab == 'Analysis') {
          if (activeWS == WorkspaceType.community && community != null) {
            content = CommunityAnalysisScreen(
              community: community,
              isAdmin: true, // Assuming current user is admin for now
            );
          } else {
            content = const AnalysisScreen();
          }
        } else if (_activeTab == 'Goals') {
          if (activeWS == WorkspaceType.community && community != null) {
            content = CommunityGoalsScreen(community: community);
          } else {
            if (_showingArchive && _selectedGoal != null) {
              content = GoalArchiveScreen(
                goal: _selectedGoal!,
                onBack: () => setState(() => _showingArchive = false),
                onBackToGoals: () => setState(() {
                  _showingArchive = false;
                  _showingGoalDetail = false;
                }),
              );
            } else if (_showingGoalDetail && _selectedGoal != null) {
              content = GoalDetailScreen(
                goal: _selectedGoal!, 
                allGoals: goals,
                onViewArchive: () => setState(() => _showingArchive = true),
                onBack: () => setState(() => _showingGoalDetail = false),
              );
            } else {
              content = GoalsOverviewScreen(
                onGoalTap: (goal) => _openGoalDetail(goal),
              );
            }
          }
        } else if (_activeTab == 'Profile') {
          content = const ProfileScreen();
        } else {
          content = const DashboardScreen();
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          drawer: Responsive.isDesktop(context)
              ? null
              : Drawer(
                  child: SidebarWidget(
                    activeItem: _activeTab,
                    onItemTap: _onNavChange,
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (Responsive.isDesktop(context))
                  SidebarWidget(
                    activeItem: _activeTab,
                    onItemTap: _onNavChange,
                  ),
                Expanded(child: content),
              ],
            ),
          ),
        );
      }
    );
  }
}
