import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:intl/intl.dart';
import '../models/goal_models.dart';
import '../theme/app_colors.dart';

import '../services/goal_service.dart';

class GoalArchiveScreen extends StatefulWidget {
  final Goal goal;
  final VoidCallback onBack;
  final VoidCallback onBackToGoals;

  const GoalArchiveScreen({
    super.key,
    required this.goal,
    required this.onBack,
    required this.onBackToGoals,
  });

  @override
  State<GoalArchiveScreen> createState() => _GoalArchiveScreenState();
}

class _GoalArchiveScreenState extends State<GoalArchiveScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  
  // Sort state
  String _sortBy = 'Newest First';

  List<GoalTask> get _archivedTasks {
    List<GoalTask> archived = widget.goal.tasks.where((t) => t.isCompleted).toList();
    
    switch (_sortBy) {
      case 'Newest First':
        archived.sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
        break;
      case 'Oldest First':
        archived.sort((a, b) => (a.completedAt ?? a.createdAt).compareTo(b.completedAt ?? b.createdAt));
        break;
      case 'Priority':
        archived.sort((a, b) {
          final priorityOrder = {
            TaskPriority.milestone: 0,
            TaskPriority.high: 1,
            TaskPriority.medium: 2,
            TaskPriority.low: 3,
          };
          return (priorityOrder[a.priority] ?? 4).compareTo(priorityOrder[b.priority] ?? 4);
        });
        break;
      case 'Completion Duration':
        archived.sort((a, b) {
          final durA = a.timeSpent ?? (a.completedAt?.difference(a.createdAt) ?? Duration.zero);
          final durB = b.timeSpent ?? (b.completedAt?.difference(b.createdAt) ?? Duration.zero);
          return durB.compareTo(durA);
        });
        break;
    }
    return archived;
  }

  Map<String, List<GoalTask>> get _groupedTasks {
    final Map<String, List<GoalTask>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var task in _archivedTasks) {
      final compDate = task.completedAt ?? task.createdAt;
      final dateOnly = DateTime(compDate.year, compDate.month, compDate.day);
      
      String label;
      if (dateOnly == today) {
        label = 'TODAY';
      } else if (dateOnly == yesterday) {
        label = 'YESTERDAY';
      } else {
        label = DateFormat('MMMM dd, yyyy').format(dateOnly).toUpperCase();
      }

      if (!groups.containsKey(label)) {
        groups[label] = [];
      }
      groups[label]!.add(task);
    }
    return groups;
  }

  void _deleteTask(GoalTask task) {
    // Store removed activities to allow UNDO
    final removedActivities = widget.goal.activities.where((a) => a.taskId == task.id).toList();

    GoalService().deleteTask(widget.goal.id, task.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived task "${task.name}" deleted'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppColors.slate900,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () {
            GoalService().addTask(widget.goal.id, task);
            GoalService().addActivities(widget.goal.id, removedActivities);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSubHeader(),
                        const Spacer(),
                        _buildTotalCount(),
                        const SizedBox(width: 24),
                        _buildSortMenu(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_archivedTasks.isEmpty)
                      _buildEmptyState()
                    else
                      ..._groupedTasks.entries.map((entry) => _buildGroup(entry.key, entry.value)),
                    
                    if (_archivedTasks.length > 5 && !_isLoadingMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _isLoadingMore = true);
                              Future.delayed(const Duration(seconds: 1), () {
                                if (mounted) setState(() => _isLoadingMore = false);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.slate600,
                              side: BorderSide(color: AppColors.slate200),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('Load More History', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.archive_outlined, size: 64, color: AppColors.slate200),
            SizedBox(height: 16),
            Text(
              'No completed tasks yet',
              style: TextStyle(color: AppColors.slate400, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: Icon(Icons.arrow_back, color: AppColors.slate400),
            tooltip: 'Back to Goal Detail',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.goal.title} Archive',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
                const SizedBox(height: 4),
                _buildBreadcrumb(),
              ],
            ),
          ),
          const SizedBox(width: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.slate700,
              side: BorderSide(color: AppColors.slate200),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onBackToGoals,
            child: Text('Goals', style: TextStyle(color: AppColors.slate500, fontSize: 14)),
          ),
        ),
        Icon(Icons.chevron_right, size: 16, color: AppColors.slate300),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onBack,
            child: Text(widget.goal.title, style: TextStyle(color: AppColors.slate500, fontSize: 14)),
          ),
        ),
        Icon(Icons.chevron_right, size: 16, color: AppColors.slate300),
        Text('Archived Tasks', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSubHeader() {
    return Text(
      'ACTIVITY HISTORY',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 1),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.slate200.withOpacity(0.5)),
      ),
      color: Colors.white,
      onSelected: (value) => setState(() => _sortBy = value),
      itemBuilder: (context) => [
        _buildArchiveSortHeader('SORT BY'),
        _buildArchiveSortMenuItem('Newest First', _sortBy == 'Newest First'),
        _buildArchiveSortMenuItem('Oldest First', _sortBy == 'Oldest First'),
        _buildArchiveSortMenuItem('Priority', _sortBy == 'Priority'),
        _buildArchiveSortMenuItem('Completion Duration', _sortBy == 'Completion Duration'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 14, color: AppColors.slate500),
            const SizedBox(width: 6),
            Text(
              _sortBy,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate600),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<String> _buildArchiveSortHeader(String title) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 32,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.slate400,
          letterSpacing: 1,
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildArchiveSortMenuItem(String label, bool isSelected) {
    return PopupMenuItem<String>(
      value: label,
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
            if (isSelected) Icon(Icons.check, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCount() {
    return Text.rich(
      TextSpan(
        text: 'Total: ',
        style: TextStyle(color: AppColors.slate500, fontSize: 14),
        children: [
          TextSpan(
            text: '${_archivedTasks.length} tasks completed',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String label, List<GoalTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, top: 24),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 1.5),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ArchiveTaskItem(
            task: tasks[index],
            onDelete: () => _deleteTask(tasks[index]),
            onUntick: () {
              final task = tasks[index];
              GoalService().toggleTaskCompletion(widget.goal.id, task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${task.name}" moved back to active tasks'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArchiveTaskItem extends StatelessWidget {
  final GoalTask task;
  final VoidCallback onDelete;
  final VoidCallback onUntick;

  const _ArchiveTaskItem({
    required this.task,
    required this.onDelete,
    required this.onUntick,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete from History',
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
                    decoration: BoxDecoration(
                      color: AppColors.rose50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline, color: AppColors.rose500, size: 32),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Delete from History?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This will permanently remove the task record. Would you like to move it back to your active list instead?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children: [
                       SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onUntick();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Move to Active List', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: AppColors.slate200),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.rose600,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Delete permanently', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
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

  void _showUntickConfirmation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Move to Active',
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
                      color: Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.undo, color: Color(0xFF16A34A), size: 32),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Move to Active Tasks?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This will un-mark "${task.name}" as completed and move it back to your main goal task list.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                            side: BorderSide(color: AppColors.slate200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
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
                            onUntick();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Yes, Move Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

  String _formatTimeSpent() {
    final duration = task.timeSpent ?? (task.completedAt?.difference(task.createdAt) ?? Duration.zero);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m spent';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m spent';
    }
  }

  String _formatCompletedTime() {
    final date = task.completedAt ?? task.createdAt;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compDate = DateTime(date.year, date.month, date.day);

    String prefix = '';
    if (compDate == today) {
      prefix = 'Today';
    } else if (compDate == yesterday) {
      prefix = 'Yesterday';
    } else {
      prefix = DateFormat('MMM dd').format(date);
    }

    return '$prefix, ${DateFormat('h:mm a').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onLongPress: () => _showDeleteConfirmation(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => _showUntickConfirmation(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(_formatCompletedTime(), style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                        const SizedBox(width: 16),
                        Icon(Icons.flash_on, size: 14, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(_formatTimeSpent(), style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildPriorityBadge(),
              const SizedBox(width: 8),
              if (task.sessions.isNotEmpty)
                IconButton(
                  onPressed: () => _showSessionInfo(context),
                  icon: Icon(Icons.info_outline, size: 20, color: AppColors.slate400),
                  splashRadius: 20,
                  tooltip: 'View Focus Analysis',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionInfo(BuildContext context) {
    if (task.sessions.isEmpty) return;
    
    // Show the first/last session info
    final session = task.sessions.last;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session Analysis',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.slate400),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.slate100),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoMetric('INTENSITY', '${(session.intensity * 100).toInt()}%'),
                        _buildInfoMetric('SCORE', '${session.focusScore}/100'),
                        _buildInfoMetric('DURATION', _formatDuration(session.duration)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'FOCUS TREND',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          (session.trendData.isNotEmpty ? session.trendData : [0.5, 0.7, 0.6, 0.9, 0.82]).length,
                          (index) {
                            final trendData = session.trendData.isNotEmpty ? session.trendData : [0.5, 0.7, 0.6, 0.9, 0.82];
                            final val = trendData[index];
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: _AnimatedArchiveBar(
                                  value: val,
                                  delayIndex: index,
                                  color: AppColors.primary.withOpacity(val > 0.8 ? 1.0 : 0.5),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 14, color: AppColors.slate400),
                    const SizedBox(width: 8),
                    Text(
                      'Completed on ${DateFormat('MMM dd, h:mm a').format(session.timestamp)}',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}m';
  }

  Widget _buildPriorityBadge() {
    Color bg;
    Color fg;
    String label = task.priority.name[0].toUpperCase() + task.priority.name.substring(1);

    switch (task.priority) {
      case TaskPriority.high:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFF991B1B);
        break;
      case TaskPriority.medium:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1E40AF);
        break;
      case TaskPriority.low:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF374151);
        break;
      case TaskPriority.milestone:
        bg = AppColors.primary.withOpacity(0.1);
        fg = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _AnimatedArchiveBar extends StatefulWidget {
  final double value;
  final int delayIndex;
  final Color color;

  const _AnimatedArchiveBar({
    required this.value,
    required this.delayIndex,
    required this.color,
  });

  @override
  State<_AnimatedArchiveBar> createState() => _AnimatedArchiveBarState();
}

class _AnimatedArchiveBarState extends State<_AnimatedArchiveBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    Future.delayed(Duration(milliseconds: 50 * widget.delayIndex), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: _animation.value * 80,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        );
      },
    );
  }
}