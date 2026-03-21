import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/responsive.dart';
import '../models/goal_models.dart';
import '../widgets/focus_session_dialog.dart';

import '../services/session_manager.dart';
import '../services/goal_service.dart';
import '../screens/focus_session_screen.dart';
import '../widgets/session_type_selection_dialog.dart';
import '../widgets/create_goal_dialog.dart';
import '../theme/settings_notifier.dart';
import 'package:progresso/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum _CalendarViewMode { days, months, years }
enum TaskSortBy { closestFirst, furthestFirst, newestFirst, oldestFirst }
enum TaskStatusFilter { all, active, completed }

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  final List<Goal> allGoals;
  final VoidCallback onViewArchive;
  final VoidCallback onBack;
  const GoalDetailScreen({
    super.key, 
    required this.goal, 
    required this.allGoals,
    required this.onViewArchive, 
    required this.onBack,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  bool _isAddingTask = false;
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime _selectedDate = DateTime.now();

  // Filter & Sort State
  TaskPriority? _priorityFilter;
  TaskSortBy _sortBy = TaskSortBy.oldestFirst;
  TaskStatusFilter _statusFilter = TaskStatusFilter.all;

  @override
  void dispose() {
    _taskNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<GoalTask> get _filteredTasks {
    final searchQuery = _searchController.text.trim().toLowerCase();
    
    List<GoalTask> filtered = widget.goal.tasks.where((task) {
      if (task.isCompleted) return false; // Archive logic: completed tasks are removed from active list
      if (searchQuery.isNotEmpty && !task.name.toLowerCase().contains(searchQuery)) return false;
      if (_priorityFilter != null && task.priority != _priorityFilter) return false;
      // Status filter is now implicitly 'active' for the main list, but we can keep the logic for search completeness
      if (_statusFilter == TaskStatusFilter.completed) return false; 
      return true;
    }).toList();

    switch (_sortBy) {
      case TaskSortBy.closestFirst:
        filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case TaskSortBy.furthestFirst:
        filtered.sort((a, b) => b.deadline.compareTo(a.deadline));
        break;
      case TaskSortBy.newestFirst:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TaskSortBy.oldestFirst:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return filtered;
  }

  void _toggleTask(GoalTask task) {
    GoalService().toggleTaskCompletion(widget.goal.id, task.id);
  }

  void _deleteTask(GoalTask task) {
    // Store removed activities to allow UNDO
    final removedActivities = widget.goal.activities.where((a) => a.taskId == task.id).toList();
    
    GoalService().deleteTask(widget.goal.id, task.id);
    SessionManager().deleteSession(task.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.name}" deleted'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppColors.slate900,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () {
            GoalService().addTask(widget.goal.id, task);
            // Restore activities
            GoalService().addActivities(widget.goal.id, removedActivities);
          },
        ),
      ),
    );
  }

  void _addTask() {
    if (_taskNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name')),
      );
      return;
    }

    // Milestone logic: Deadline is mandatory (already defaulted to now, but let's assume valid)
    // Actually, let's just save.
    
    final newTask = GoalTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _taskNameController.text.trim(),
      priority: _selectedPriority,
      deadline: _selectedDate,
    );
    
    GoalService().addTask(widget.goal.id, newTask);

    setState(() {
      _isAddingTask = false;
      _taskNameController.clear();
      _selectedPriority = TaskPriority.medium;
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsNotifier = Provider.of<SettingsNotifier>(context);
    return ListenableBuilder(
      listenable: Listenable.merge([SessionManager(), GoalService(), settingsNotifier]),
      builder: (context, _) {
        return Column(
          children: [
            _GoalHeader(
              goal: widget.goal,
              allGoals: widget.allGoals,
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       _GoalTitleSection(goal: widget.goal),
                      const SizedBox(height: 32),
                      _GoalContentGrid(
                        goal: widget.goal,
                        isAddingTask: _isAddingTask,
                        onAddTaskToggle: () => setState(() => _isAddingTask = !_isAddingTask),
                        onTaskToggle: _toggleTask,
                        taskNameController: _taskNameController,
                        selectedPriority: _selectedPriority,
                        selectedDate: _selectedDate,
                        onPriorityChanged: (val) => setState(() => _selectedPriority = val),
                        onDateChanged: (val) => setState(() => _selectedDate = val),
                        onSaveTask: _addTask,
                        onCancelAddTask: () => setState(() => _isAddingTask = false),
                        // Filter & Sort props
                        filteredTasks: _filteredTasks,
                        priorityFilter: _priorityFilter,
                        sortBy: _sortBy,
                        statusFilter: _statusFilter,
                        searchController: _searchController,
                        onSearchChanged: (val) => setState(() {}),
                        onPriorityFilterChanged: (val) => setState(() => _priorityFilter = val),
                        onSortByChanged: (val) => setState(() => _sortBy = val),
                        onStatusFilterChanged: (val) => setState(() => _statusFilter = val),
                        onClearFilters: () => setState(() {
                          _priorityFilter = null;
                          _sortBy = TaskSortBy.oldestFirst;
                          _statusFilter = TaskStatusFilter.all;
                          _searchController.clear();
                        }),
                        onViewArchive: widget.onViewArchive,
                        onDeleteTask: _deleteTask,
                        onStartFocus: (task) {
                          // 1. Resume existing session if any
                          final session = SessionManager().getSessionForTask(task.id);
                          if (session != null) {
                            _resumeSession(task);
                            return;
                          }

                          // 2. First-time configuration
                          if (task.sessionType == null && task.sessions.isEmpty) {
                            _showSessionTypeSelection(task);
                            return;
                          }

                          // 3. Direct start if already configured or has history
                          _startDirectSession(task);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  void _showResumeConfirmation(GoalTask task) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Resume Session',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.indigo50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Resume Session?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have an existing session for "${task.name}". Would you like to resume it?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            SessionManager().deleteSession(task.id);
                            // Trigger the regular dialog
                            _showFocusDialog(task);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.slate200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Start New',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resumeSession(task);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Resume', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ScaleTransition(
            scale: anim1.drive(CurveTween(curve: Curves.easeOutBack)),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
    );
  }

  void _showFocusDialog(GoalTask task) {
    if (task.sessionType == null && task.sessions.isEmpty) {
      _showSessionTypeSelection(task);
    } else {
      _startDirectSession(task);
    }
  }

  void _showSessionTypeSelection(GoalTask task) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Session Type',
      barrierColor: Colors.black.withOpacity(0.6),
      pageBuilder: (context, _, __) => SessionTypeSelectionDialog(
        goal: widget.goal,
        task: task,
        onSelect: (type, duration) {
          Navigator.pop(context);
          setState(() {
            task.sessionType = type;
            task.defaultDuration = duration;
          });
          _startDirectSession(task);
        },
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  void _startDirectSession(GoalTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusSessionScreen(
          goal: widget.goal,
          task: task,
          targetSeconds: task.sessionType == FocusSessionType.timed ? task.defaultDuration : null,
        ),
      ),
    );
  }

  void _resumeSession(GoalTask task) {
    final session = SessionManager().getSessionForTask(task.id);
    if (session == null) return;
    
    // Resume if paused
    if (session.status == SessionStatus.paused) {
      SessionManager().resumeSession(task.id);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusSessionScreen(
          goal: widget.goal,
          task: task,
          // targetSeconds will be picked up from persistence in FocusSessionScreen.initState
        ),
      ),
    );
  }
}

class _GoalHeader extends StatelessWidget {
  final Goal goal;
  final List<Goal> allGoals;
  final VoidCallback onBack;
  const _GoalHeader({
    required this.goal,
    required this.allGoals,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
              color: AppColors.slate900,
            ),
            const SizedBox(width: 8),
          ],
          // Breadcrumbs
          Expanded(
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onBack,
                    child: const Text(
                      'Goals',
                      style: TextStyle(color: AppColors.slate500, fontSize: 13),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.slate400),
                Text(
                  goal.title,
                  style: const TextStyle(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Focus Session',
                    barrierColor: Colors.black.withOpacity(0.6),
                    pageBuilder: (context, _, __) => FocusSessionDialog(
                      goals: allGoals,
                      initialGoal: goal,
                    ),
                    transitionBuilder: (context, anim1, anim2, child) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: FadeTransition(
                          opacity: anim1,
                          child: child,
                        ),
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: Text(
                  isMobile ? 'Start' : 'Start Focus Session',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: AppColors.slate200),
                const SizedBox(width: 16),
                const Icon(Icons.notifications_none, color: AppColors.slate500, size: 20),
                const SizedBox(width: 16),
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalTitleSection extends StatelessWidget {
  final Goal goal;
  const _GoalTitleSection({required this.goal});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.indigo50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(goal.icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${goal.description} â€¢ Due ${DateFormat('MMM dd').format(goal.dueDate)}',
                        style: const TextStyle(color: AppColors.slate500, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: goal.status == GoalStatus.active ? const Color(0xFFDCFCE7) : AppColors.slate100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: goal.status == GoalStatus.active ? const Color(0xFFBBF7D0) : AppColors.slate200),
                        ),
                        child: Text(
                          goal.status.name.toUpperCase(),
                          style: TextStyle(
                            color: goal.status == GoalStatus.active ? const Color(0xFF15803D) : AppColors.slate600,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              _ActionButton(
                icon: Icons.edit_outlined, 
                label: 'Edit', 
                onTap: () => _showEditGoalConfirmation(context),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: AppColors.rose500,
                onTap: () => _showDeleteGoalConfirmation(context),
              ),
            ],
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_outlined, 
                  label: 'Edit',
                  onTap: () => _showEditGoalConfirmation(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.rose500,
                  onTap: () => _showDeleteGoalConfirmation(context),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showEditGoalConfirmation(BuildContext context) {
    showEditGoalDialog(context, goal);
  }

  void _showDeleteGoalConfirmation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Session',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.rose50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.rose500, size: 32),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Delete Session?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete "${goal.title}"? This will permanently remove all associated tasks.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.slate200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            GoalService().deleteGoal(goal.id);
                            final nav = Navigator.of(context);
                            if (nav.canPop()) {
                              nav.pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rose500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Delete Session', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ScaleTransition(
            scale: anim1.drive(CurveTween(curve: Curves.easeOutBack)),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = AppColors.slate700,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalContentGrid extends StatelessWidget {
  final Goal goal;
  final bool isAddingTask;
  final VoidCallback onAddTaskToggle;
  final Function(GoalTask) onTaskToggle;
  final TextEditingController taskNameController;
  final TaskPriority selectedPriority;
  final DateTime selectedDate;
  final Function(TaskPriority) onPriorityChanged;
  final Function(DateTime) onDateChanged;
  final VoidCallback onSaveTask;
  final VoidCallback onCancelAddTask;
  final List<GoalTask> filteredTasks;
  final TaskPriority? priorityFilter;
  final TaskSortBy sortBy;
  final TaskStatusFilter statusFilter;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function(TaskPriority?) onPriorityFilterChanged;
  final Function(TaskSortBy) onSortByChanged;
  final Function(TaskStatusFilter) onStatusFilterChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onViewArchive;
  final Function(GoalTask) onDeleteTask;
  final Function(GoalTask) onStartFocus;

  const _GoalContentGrid({
    required this.goal,
    required this.isAddingTask,
    required this.onAddTaskToggle,
    required this.onTaskToggle,
    required this.taskNameController,
    required this.selectedPriority,
    required this.selectedDate,
    required this.onPriorityChanged,
    required this.onDateChanged,
    required this.onSaveTask,
    required this.onCancelAddTask,
    required this.filteredTasks,
    required this.priorityFilter,
    required this.sortBy,
    required this.statusFilter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onPriorityFilterChanged,
    required this.onSortByChanged,
    required this.onStatusFilterChanged,
    required this.onClearFilters,
    required this.onViewArchive,
    required this.onDeleteTask,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _TaskListCard(
            goal: goal,
            isAddingTask: isAddingTask,
            onAddTaskToggle: onAddTaskToggle,
            onTaskToggle: onTaskToggle,
            taskNameController: taskNameController,
            selectedPriority: selectedPriority,
            selectedDate: selectedDate,
            onPriorityChanged: onPriorityChanged,
            onDateChanged: onDateChanged,
            onSaveTask: onSaveTask,
            onCancelAddTask: onCancelAddTask,
            filteredTasks: filteredTasks,
            priorityFilter: priorityFilter,
            sortBy: sortBy,
            statusFilter: statusFilter,
            searchController: searchController,
            onSearchChanged: onSearchChanged,
            onPriorityFilterChanged: onPriorityFilterChanged,
            onSortByChanged: onSortByChanged,
            onStatusFilterChanged: onStatusFilterChanged,
            onClearFilters: onClearFilters,
            onViewArchive: onViewArchive,
            onDeleteTask: onDeleteTask,
            onStartFocus: onStartFocus,
          ),
          const SizedBox(height: 32),
          _RecentActivityCard(
            activities: goal.activities,
            hasMilestone: goal.tasks.any((t) => t.priority == TaskPriority.milestone && !t.isCompleted),
            onViewMore: onViewArchive,
          ),
          const SizedBox(height: 32),
          _AnalyticsCard(goal: goal),
          const SizedBox(height: 32),
          _MilestoneCard(milestoneTask: goal.nextMilestoneTask),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _TaskListCard(
                goal: goal,
                isAddingTask: isAddingTask,
                onAddTaskToggle: onAddTaskToggle,
                onTaskToggle: onTaskToggle,
                taskNameController: taskNameController,
                selectedPriority: selectedPriority,
                selectedDate: selectedDate,
                onPriorityChanged: onPriorityChanged,
                onDateChanged: onDateChanged,
                onSaveTask: onSaveTask,
                onCancelAddTask: onCancelAddTask,
                filteredTasks: filteredTasks,
                priorityFilter: priorityFilter,
                sortBy: sortBy,
                statusFilter: statusFilter,
                searchController: searchController,
                onSearchChanged: onSearchChanged,
                onPriorityFilterChanged: onPriorityFilterChanged,
                onSortByChanged: onSortByChanged,
                onStatusFilterChanged: onStatusFilterChanged,
                onClearFilters: onClearFilters,
                onViewArchive: onViewArchive,
                onDeleteTask: onDeleteTask,
                onStartFocus: onStartFocus,
              ),
              const SizedBox(height: 32),
              _RecentActivityCard(
                activities: goal.activities,
                hasMilestone: goal.tasks.any((t) => t.priority == TaskPriority.milestone && !t.isCompleted),
                onViewMore: onViewArchive,
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _AnalyticsCard(goal: goal),
              const SizedBox(height: 32),
              _MilestoneCard(milestoneTask: goal.nextMilestoneTask),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskListCard extends StatelessWidget {
  final Goal goal;
  final bool isAddingTask;
  final VoidCallback onAddTaskToggle;
  final Function(GoalTask) onTaskToggle;
  final TextEditingController taskNameController;
  final TaskPriority selectedPriority;
  final DateTime selectedDate;
  final Function(TaskPriority) onPriorityChanged;
  final Function(DateTime) onDateChanged;
  final VoidCallback onSaveTask;
  final VoidCallback onCancelAddTask;
  final List<GoalTask> filteredTasks;
  final TaskPriority? priorityFilter;
  final TaskSortBy sortBy;
  final TaskStatusFilter statusFilter;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function(TaskPriority?) onPriorityFilterChanged;
  final Function(TaskSortBy) onSortByChanged;
  final Function(TaskStatusFilter) onStatusFilterChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onViewArchive;
  final Function(GoalTask) onDeleteTask;
  final Function(GoalTask) onStartFocus;

  const _TaskListCard({
    required this.goal,
    required this.isAddingTask,
    required this.onAddTaskToggle,
    required this.onTaskToggle,
    required this.taskNameController,
    required this.selectedPriority,
    required this.selectedDate,
    required this.onPriorityChanged,
    required this.onDateChanged,
    required this.onSaveTask,
    required this.onCancelAddTask,
    required this.filteredTasks,
    required this.priorityFilter,
    required this.sortBy,
    required this.statusFilter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onPriorityFilterChanged,
    required this.onSortByChanged,
    required this.onStatusFilterChanged,
    required this.onClearFilters,
    required this.onViewArchive,
    required this.onDeleteTask,
    required this.onStartFocus,
  });

  String _getSortLabel(TaskSortBy sortBy) {
    switch (sortBy) {
      case TaskSortBy.closestFirst:
        return 'Earliest Deadline';
      case TaskSortBy.furthestFirst:
        return 'Latest Deadline';
      case TaskSortBy.newestFirst:
        return 'Newest First';
      case TaskSortBy.oldestFirst:
        return 'Oldest First';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Task List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Search Input
                    Container(
                      width: isMobile ? 120 : 200,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.slate200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.slate400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 10),
                    ),
                  ),
                    ),
                    const SizedBox(width: 12),
                    _TaskSortFilterMenu(
                      priorityFilter: priorityFilter,
                      sortBy: sortBy,
                      statusFilter: statusFilter,
                      onPriorityFilterChanged: onPriorityFilterChanged,
                      onSortByChanged: onSortByChanged,
                      onStatusFilterChanged: onStatusFilterChanged,
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: onAddTaskToggle,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Task'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.slate100),
          // Filter Chips Section
          if (priorityFilter != null || statusFilter != TaskStatusFilter.all || searchController.text.isNotEmpty || sortBy != TaskSortBy.oldestFirst)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                   if (priorityFilter != null)
                    _FilterChip(
                      label: '${priorityFilter!.name[0].toUpperCase()}${priorityFilter!.name.substring(1)} Priority',
                      onDelete: () => onPriorityFilterChanged(null),
                    ),
                  if (statusFilter != TaskStatusFilter.all)
                    _FilterChip(
                      label: '${statusFilter.name[0].toUpperCase()}${statusFilter.name.substring(1)} Status',
                      onDelete: () => onStatusFilterChanged(TaskStatusFilter.all),
                    ),
                  if (searchController.text.isNotEmpty)
                    _FilterChip(
                      label: 'Search: "${searchController.text}"',
                      onDelete: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
                  if (sortBy != TaskSortBy.oldestFirst)
                    _FilterChip(
                      label: _getSortLabel(sortBy),
                      onDelete: () => onSortByChanged(TaskSortBy.oldestFirst),
                    ),
                  TextButton(
                    onPressed: onClearFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (isAddingTask) _AddTaskForm(
            controller: taskNameController,
            priority: selectedPriority,
            date: selectedDate,
            onPriorityChanged: onPriorityChanged,
            onDateChanged: onDateChanged,
            onSave: onSaveTask,
            onCancel: onCancelAddTask,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: goal.tasks.isEmpty 
                ? [const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No tasks yet. Click Add Task to start.', style: TextStyle(color: AppColors.slate400)),
                  )]
                : (filteredTasks.isEmpty 
                    ? [Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 48, color: AppColors.slate200),
                              const SizedBox(height: 16),
                              Text(
                                searchController.text.isNotEmpty 
                                  ? 'No tasks match your search'
                                  : 'No tasks match current filters',
                                style: const TextStyle(color: AppColors.slate400, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )]
                    : filteredTasks.map((task) => _TaskItem(
                        task: task,
                        onToggle: () => onTaskToggle(task),
                        onDelete: () => onDeleteTask(task),
                        onStartFocus: () => onStartFocus(task),
                      )).toList()),
            ),
          ),
          const Divider(height: 1, color: AppColors.slate100),
          InkWell(
            onTap: onViewArchive,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                   const Icon(Icons.archive_outlined, size: 20, color: AppColors.slate500),
                   const SizedBox(width: 12),
                   const Text(
                    'View Archive',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.slate100.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${goal.tasks.where((t) => t.isCompleted).length} Completed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.slate400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskForm extends StatelessWidget {
  final TextEditingController controller;
  final TaskPriority priority;
  final DateTime date;
  final Function(TaskPriority) onPriorityChanged;
  final Function(DateTime) onDateChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _AddTaskForm({
    required this.controller,
    required this.priority,
    required this.date,
    required this.onPriorityChanged,
    required this.onDateChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskNameField(),
                const SizedBox(height: 16),
                _buildPriorityField(context),
                const SizedBox(height: 16),
                _buildDeadlineField(context),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildTaskNameField()),
                const SizedBox(width: 12),
                Expanded(child: _buildPriorityField(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildDeadlineField(context)),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Save Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Task Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g. Read Chapter 5',
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.slate400),
            isDense: true,
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.slate300)),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityField(BuildContext context) {
    String currentLabel;
    switch (priority) {
      case TaskPriority.high: currentLabel = 'High Priority'; break;
      case TaskPriority.medium: currentLabel = 'Medium'; break;
      case TaskPriority.low: currentLabel = 'Low Priority'; break;
      case TaskPriority.milestone: currentLabel = 'Milestone'; break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate500)),
        const SizedBox(height: 6),
        Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<TaskPriority>(
            offset: const Offset(0, 45), // Position below the 42px trigger
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.slate200.withOpacity(0.1)),
            ),
            color: Colors.white,
            onSelected: (val) => onPriorityChanged(val),
            itemBuilder: (context) => TaskPriority.values.map((p) {
              String label;
              switch (p) {
                case TaskPriority.high: label = 'High Priority'; break;
                case TaskPriority.medium: label = 'Medium'; break;
                case TaskPriority.low: label = 'Low Priority'; break;
                case TaskPriority.milestone: label = 'Milestone'; break;
              }
              
              final bool isMedium = p == TaskPriority.medium;

              return PopupMenuItem<TaskPriority>(
                value: p,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMedium ? AppColors.primary.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMedium ? AppColors.primary : AppColors.slate900,
                      fontWeight: isMedium ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: priority == TaskPriority.milestone ? AppColors.primary : AppColors.slate300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentLabel,
                    style: const TextStyle(fontSize: 14, color: AppColors.slate900, fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.keyboard_arrow_up, size: 20, color: AppColors.slate900),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deadline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate500)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDialog<DateTime>(
              context: context,
              barrierColor: Colors.black.withOpacity(0.6),
              builder: (context) => _CustomCalendarDialog(initialDate: date),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: priority == TaskPriority.milestone ? AppColors.primary : AppColors.slate300, 
                width: priority == TaskPriority.milestone ? 2 : 1
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: priority == TaskPriority.milestone ? [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4, spreadRadius: 0)
              ] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MM/dd/yyyy').format(date), style: const TextStyle(fontSize: 14)),
                const Icon(Icons.calendar_today, size: 16, color: AppColors.slate400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomCalendarDialog extends StatefulWidget {
  final DateTime? initialDate;
  const _CustomCalendarDialog({this.initialDate});

  @override
  State<_CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<_CustomCalendarDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  _CalendarViewMode _viewMode = _CalendarViewMode.days;
  late int _displayedYear; // For year selection decade

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _displayedYear = _displayedMonth.year;
  }

  void _prev() {
    setState(() {
      if (_viewMode == _CalendarViewMode.days) {
        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
        _displayedYear = _displayedMonth.year;
      } else if (_viewMode == _CalendarViewMode.months) {
        _displayedYear--;
      } else {
        _displayedYear -= 12;
      }
    });
  }

  void _next() {
    setState(() {
      if (_viewMode == _CalendarViewMode.days) {
        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
        _displayedYear = _displayedMonth.year;
      } else if (_viewMode == _CalendarViewMode.months) {
        _displayedYear++;
      } else {
        _displayedYear += 12;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        child: Container(
          width: isMobile ? double.infinity : 680,
          height: isMobile ? 480 : 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              // Left Panel
              if (!isMobile)
                Container(
                  width: 240,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECT DATE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate400,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        DateFormat('EEE,\nMMM dd').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, color: AppColors.slate400, size: 20),
                    ],
                  ),
                ),
              // Right Panel (Calendar)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (isMobile) ...[
                        Text(
                          DateFormat('EEEE, MMM dd').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_viewMode == _CalendarViewMode.days) _viewMode = _CalendarViewMode.months;
                                else if (_viewMode == _CalendarViewMode.months) _viewMode = _CalendarViewMode.years;
                                else _viewMode = _CalendarViewMode.days;
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  _viewMode == _CalendarViewMode.days 
                                    ? DateFormat('MMMM yyyy').format(_displayedMonth)
                                    : (_viewMode == _CalendarViewMode.months ? '$_displayedYear' : '${_displayedYear - 5} - ${_displayedYear + 6}'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 20),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, size: 20),
                                onPressed: _prev,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, size: 20),
                                onPressed: _next,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_viewMode == _CalendarViewMode.days) ...[
                        _buildDaysOfWeek(),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: _viewMode == _CalendarViewMode.days 
                          ? _buildCalendarGrid() 
                          : (_viewMode == _CalendarViewMode.months ? _buildMonthGrid() : _buildYearGrid()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(context, _selectedDate),
                            child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) => SizedBox(
        width: 36,
        child: Center(
          child: Text(d, style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstDayOffset = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;
    
    // Days from previous month to fill the first row
    final prevMonthLastDay = DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;
    final prevMonthDays = List.generate(firstDayOffset, (i) => prevMonthLastDay - firstDayOffset + i + 1);

    final currentMonthDays = List.generate(daysInMonth, (i) => i + 1);
    
    // Fill remaining cells for 6 weeks (42 cells)
    final remainingCells = 42 - (prevMonthDays.length + currentMonthDays.length);
    final nextMonthDays = List.generate(remainingCells, (i) => i + 1);

    return GridView.count(
      crossAxisCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...prevMonthDays.map((d) => _buildDateCell(d, isCurrentMonth: false)),
        ...currentMonthDays.map((d) => _buildDateCell(d, isCurrentMonth: true)),
        ...nextMonthDays.map((d) => _buildDateCell(d, isCurrentMonth: false)),
      ],
    );
  }

  Widget _buildDateCell(int day, {required bool isCurrentMonth}) {
    final date = DateTime(_displayedMonth.year, isCurrentMonth ? _displayedMonth.month : (day > 20 ? _displayedMonth.month - 1 : _displayedMonth.month + 1), day);
    final isSelected = DateUtils.isSameDay(date, _selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = date.isBefore(today);

    return MouseRegion(
      cursor: isPast ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isPast ? null : () {
          setState(() {
            _selectedDate = date;
            if (!isCurrentMonth) {
              _displayedMonth = DateTime(date.year, date.month);
              _displayedYear = _displayedMonth.year;
            }
          });
        },
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : null,
              shape: BoxShape.circle,
              border: isToday && !isSelected ? Border.all(color: AppColors.primary) : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected 
                    ? Colors.white 
                    : (isPast 
                        ? AppColors.slate200 
                        : (isCurrentMonth ? AppColors.slate900 : AppColors.slate300)),
                  fontSize: 13,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final monthDate = DateTime(_displayedYear, index + 1);
        final isSelected = _displayedMonth.month == index + 1 && _displayedMonth.year == _displayedYear;
        final isPast = monthDate.isBefore(thisMonth);

        return GestureDetector(
          onTap: isPast ? null : () {
            setState(() {
              _displayedMonth = monthDate;
              _viewMode = _CalendarViewMode.days;
            });
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                months[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : (isPast ? AppColors.slate200 : AppColors.slate900),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearGrid() {
    final now = DateTime.now();
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final year = _displayedYear - 5 + index;
        final isSelected = _displayedMonth.year == year;
        final isPast = year < now.year;

        return GestureDetector(
          onTap: isPast ? null : () {
            setState(() {
              _displayedYear = year;
              _displayedMonth = DateTime(year, _displayedMonth.month);
              _viewMode = _CalendarViewMode.months;
            });
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$year',
                style: TextStyle(
                  color: isSelected ? Colors.white : (isPast ? AppColors.slate200 : AppColors.slate900),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaskItem extends StatelessWidget {
  final GoalTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onStartFocus;

  const _TaskItem({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onStartFocus,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Task',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.rose50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.rose500, size: 32),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Delete Task?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete "${task.name}"? This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.slate200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rose500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ScaleTransition(
            scale: anim1.drive(CurveTween(curve: Curves.easeOutBack)),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.slate500;
    Color statusBg = AppColors.slate100;

    if (task.isCompleted) {
      statusColor = AppColors.slate400;
      statusBg = AppColors.slate100;
    } else if (task.priority == TaskPriority.high) {
      statusColor = const Color(0xFFEA580C);
      statusBg = const Color(0xFFFFF7ED);
    } else if (task.priority == TaskPriority.milestone) {
      statusColor = AppColors.primary;
      statusBg = AppColors.primary.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onStartFocus,
          onLongPress: () => _showDeleteConfirmation(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: (task.priority == TaskPriority.high || task.priority == TaskPriority.milestone) && !task.isCompleted
                ? Border.all(color: task.priority == TaskPriority.high ? const Color(0xFFFED7AA) : AppColors.primary.withOpacity(0.2), width: 1)
                : null,
              color: (task.priority == TaskPriority.high || task.priority == TaskPriority.milestone) && !task.isCompleted
                ? (task.priority == TaskPriority.high ? const Color(0xFFFFF7ED).withOpacity(0.5) : AppColors.primary.withOpacity(0.05))
                : null,
            ),
            child: Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (val) => onToggle(),
                  activeColor: AppColors.primary,
                  side: BorderSide(color: (task.priority == TaskPriority.high || task.priority == TaskPriority.milestone) && !task.isCompleted ? (task.priority == TaskPriority.high ? const Color(0xFFFDBA74) : AppColors.primary) : AppColors.slate300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            task.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: (task.priority == TaskPriority.high || task.priority == TaskPriority.milestone) && !task.isCompleted ? FontWeight.bold : FontWeight.w500,
                              color: task.isCompleted ? AppColors.slate400 : AppColors.slate900,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (task.priority == TaskPriority.high && !task.isCompleted) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFEA580C)),
                          ],
                        ],
                      ),
                      _buildSessionStatus(),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(4),
                    border: (task.priority == TaskPriority.high || task.priority == TaskPriority.milestone) && !task.isCompleted
                      ? Border.all(color: (task.priority == TaskPriority.high ? const Color(0xFFFDBA74) : AppColors.primary).withOpacity(0.2))
                      : null,
                  ),
                  child: Text(
                    task.isCompleted ? 'Done' : (task.priority == TaskPriority.milestone ? 'Milestone' : task.priorityLabel),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStatus() {
    final session = SessionManager().getSessionForTask(task.id);
    if (session == null || task.isCompleted) return const SizedBox.shrink();

    final Color color = session.status == SessionStatus.paused ? AppColors.slate400 : AppColors.primary;
    final String label = session.status == SessionStatus.paused ? 'Paused' : 'In Progress';
    final IconData icon = session.status == SessionStatus.paused ? Icons.pause : Icons.timer_outlined;
    final Duration elapsed = SessionManager().getElapsedTime(task.id);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label â€¢ ${SessionManager.formatDuration(elapsed)} logged',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<GoalActivity> activities;
  final bool hasMilestone;
  final VoidCallback onViewMore;

  const _RecentActivityCard({
    required this.activities,
    required this.hasMilestone,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    final int maxVisible = hasMilestone ? 3 : 2;
    final bool showViewMore = activities.length > maxVisible;
    final List<GoalActivity> visibleActivities = activities.take(maxVisible).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (activities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No activity yet.', style: TextStyle(color: AppColors.slate400))),
                  )
                else
                  Column(
                    children: List.generate(
                      visibleActivities.length,
                      (index) => _ActivityItem(
                        activity: visibleActivities[index],
                        isFirst: index == 0,
                        isLast: index == visibleActivities.length - 1 && !showViewMore,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showViewMore) ...[
            const Divider(height: 1, color: AppColors.slate100),
            InkWell(
              onTap: onViewMore,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20, color: AppColors.slate500),
                    SizedBox(width: 12),
                    Text(
                      'View More Activity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.slate400),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final GoalActivity activity;
  final bool isFirst;
  final bool isLast;

  const _ActivityItem({
    required this.activity,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconBg;

    switch (activity.type) {
      case ActivityType.taskCompleted:
        icon = Icons.check;
        iconBg = AppColors.primary;
        break;
      case ActivityType.sessionCompleted:
        icon = Icons.play_arrow;
        iconBg = Colors.blue;
        break;
      case ActivityType.goalCreated:
        icon = Icons.edit_note;
        iconBg = AppColors.slate400;
        break;
      case ActivityType.taskCreated:
      case ActivityType.taskAdded:
        icon = Icons.add;
        iconBg = AppColors.blue500;
        break;
      case ActivityType.taskDeleted:
        icon = Icons.delete_outline;
        iconBg = AppColors.rose500;
        break;
      case ActivityType.sessionStarted:
        icon = Icons.play_arrow_outlined;
        iconBg = Colors.green;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(icon, color: Colors.white, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.slate200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, hh:mm a').format(activity.timestamp),
                    style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final Goal goal;
  const _AnalyticsCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.goalAnalytics,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total Progress',
                style: TextStyle(color: AppColors.slate600, fontWeight: FontWeight.w500),
              ),
              Text(
                '${(goal.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 12,
              backgroundColor: AppColors.slate100,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.completedTasksCount} of ${goal.tasks.length} tasks completed',
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.schedule_outlined,
                  label: 'TIME SPENT',
                  value: '${goal.totalTimeSpent.inHours}h',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatBox(
                  icon: Icons.local_fire_department_outlined,
                  label: 'STREAK',
                  value: '${goal.currentStreak} Days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Effort',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '+12%',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SimpleAnalyticsBarChart(values: goal.dailyEffort),
          const SizedBox(height: 8),
          _BarLabels(),
        ],
      ),
    );
  }
}

class _BarLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsNotifier = Provider.of<SettingsNotifier>(context);
    final int firstDay = settingsNotifier.firstDayOfWeek;
    final List<String> shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(shortDays[(firstDay - 1) % 7], style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
        Text(shortDays[(firstDay + 5) % 7], style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
      ],
    );
  }
}

class _SimpleAnalyticsBarChart extends StatelessWidget {
  final List<double> values;
  const _SimpleAnalyticsBarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final settingsNotifier = Provider.of<SettingsNotifier>(context);
    final int firstDay = settingsNotifier.firstDayOfWeek;
    
    // Reorder values based on firstDay
    final List<double> orderedValues = [];
    for (int i = 0; i < 7; i++) {
       orderedValues.add(values[(firstDay - 1 + i) % 7]);
    }

    return _SimpleBarChart(values: orderedValues);
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.slate400),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<double> values;
  const _SimpleBarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final isBlue = v > 0.4;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FractionallySizedBox(
                heightFactor: v.clamp(0.01, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: v == 0 ? AppColors.slate100 : (isBlue ? AppColors.primary.withOpacity(v.clamp(0.2, 1.0)) : AppColors.slate100),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final GoalTask? milestoneTask;
  const _MilestoneCard({this.milestoneTask});

  @override
  Widget build(BuildContext context) {
    if (milestoneTask == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200, style: BorderStyle.solid),
        ),
        child: const Center(child: Text('No upcoming milestones', style: TextStyle(color: AppColors.slate400))),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(milestoneTask!.deadline.year, milestoneTask!.deadline.month, milestoneTask!.deadline.day);
    final diff = deadlineDay.difference(today).inDays;
    
    String countdownText;
    if (diff < 0) {
      countdownText = 'Overdue';
    } else if (diff == 0) {
      countdownText = 'Due today';
    } else {
      countdownText = '$diff days left';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEXT MILESTONE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDBEAFE),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      milestoneTask!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event_available, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateFormat('MMM dd').format(milestoneTask!.deadline),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              const Text('â€¢', style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 8),
              Text(
                countdownText,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSortFilterMenu extends StatelessWidget {
  final TaskPriority? priorityFilter;
  final TaskSortBy sortBy;
  final TaskStatusFilter statusFilter;
  final Function(TaskPriority?) onPriorityFilterChanged;
  final Function(TaskSortBy) onSortByChanged;
  final Function(TaskStatusFilter) onStatusFilterChanged;

  const _TaskSortFilterMenu({
    required this.priorityFilter,
    required this.sortBy,
    required this.statusFilter,
    required this.onPriorityFilterChanged,
    required this.onSortByChanged,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<dynamic>(
      offset: const Offset(0, 45),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.slate200.withOpacity(0.1)),
      ),
      color: Colors.white,
      onSelected: (val) {
        if (val is String) {
          if (val == 'priority_all') onPriorityFilterChanged(null);
        } else if (val is TaskPriority) {
          onPriorityFilterChanged(val);
        } else if (val is TaskSortBy) {
          onSortByChanged(val);
        } else if (val is TaskStatusFilter) {
          onStatusFilterChanged(val);
        }
      },
      itemBuilder: (context) => [
        _buildCategoryHeader('PRIORITY'),
        _buildMenuItem('All', 'priority_all', priorityFilter == null),
        _buildMenuItem('Low', TaskPriority.low, priorityFilter == TaskPriority.low),
        _buildMenuItem('Medium', TaskPriority.medium, priorityFilter == TaskPriority.medium),
        _buildMenuItem('High', TaskPriority.high, priorityFilter == TaskPriority.high),
        _buildMenuItem('Milestone', TaskPriority.milestone, priorityFilter == TaskPriority.milestone),
        _buildDivider(),
        _buildCategoryHeader('DEADLINE'),
        _buildMenuItem('Earliest First', TaskSortBy.closestFirst, sortBy == TaskSortBy.closestFirst),
        _buildMenuItem('Latest First', TaskSortBy.furthestFirst, sortBy == TaskSortBy.furthestFirst),
        _buildDivider(),
        _buildCategoryHeader('TASK LISTED'),
        _buildMenuItem('Newest First', TaskSortBy.newestFirst, sortBy == TaskSortBy.newestFirst),
        _buildMenuItem('Oldest First', TaskSortBy.oldestFirst, sortBy == TaskSortBy.oldestFirst),
        _buildDivider(),
        _buildCategoryHeader('STATUS'),
        _buildMenuItem('All', TaskStatusFilter.all, statusFilter == TaskStatusFilter.all),
        _buildMenuItem('Active', TaskStatusFilter.active, statusFilter == TaskStatusFilter.active),
        _buildMenuItem('Completed', TaskStatusFilter.completed, statusFilter == TaskStatusFilter.completed),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 18, color: AppColors.slate500),
            SizedBox(width: 8),
            Text(
              'Sort & Filter',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<dynamic> _buildCategoryHeader(String title) {
    return PopupMenuItem<dynamic>(
      enabled: false,
      height: 32,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.slate400,
          letterSpacing: 1,
        ),
      ),
    );
  }

  PopupMenuEntry<dynamic> _buildDivider() {
    return const PopupMenuDivider(height: 1);
  }

  PopupMenuItem<dynamic> _buildMenuItem(String label, dynamic value, bool isSelected) {
    return PopupMenuItem<dynamic>(
      value: value,
      height: 40,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.slate700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) const Icon(Icons.check, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _FilterChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        borderRadius: BorderRadius.circular(fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3730A3),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  static const double fullRadius = 100;
}
