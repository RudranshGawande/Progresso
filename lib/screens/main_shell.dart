import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // Default selected goal if goals exist
    if (GoalService().goals.isNotEmpty) {
      _selectedGoal = GoalService().goals.first;
    }
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
    return ListenableBuilder(
      listenable: GoalService(),
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
        
        if (_activeTab == 'Dashboard') {
          content = DashboardScreen(
            onGoalTap: (Goal goal) => _openGoalDetail(goal),
            onSessionTap: (goal, task, session) => _openSessionSummary(goal, task, session),
            onViewAllGoals: () => _onNavChange('Goals'),
          );
        } else if (_activeTab == 'Analysis') {
          content = const AnalysisScreen();
        } else if (_activeTab == 'Goals') {
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
