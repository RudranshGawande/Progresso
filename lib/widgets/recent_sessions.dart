import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/models/goal_models.dart';


class RecentSessionsPanel extends StatelessWidget {
  final Function(Goal)? onGoalTap;
  final Function(Goal, GoalTask, FocusSession)? onSessionTap;
  final VoidCallback? onViewAll;

  const RecentSessionsPanel({
    super.key,
    this.onGoalTap,
    this.onSessionTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GoalService(),
      builder: (context, _) {
        final goals = GoalService().goals;
        final taskActivities = <String, Map<String, dynamic>>{};

        for (var goal in goals) {
          for (var task in goal.tasks) {
            if (task.sessions.isNotEmpty) {
              // Find the latest session for this task
              final latestSession = task.sessions.reduce((a, b) => 
                a.timestamp.isAfter(b.timestamp) ? a : b);
              
              taskActivities[task.id] = {
                'session': latestSession,
                'task': task,
                'taskName': task.name,
                'goalTitle': goal.title,
                'goal': goal,
                'historyCount': task.sessions.length,
              };
            }
          }
        }

        final recentTasks = taskActivities.values.toList();
        recentTasks.sort((a, b) => (b['session'] as FocusSession).timestamp.compareTo((a['session'] as FocusSession).timestamp));
        final displayedItems = recentTasks.take(4).toList();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Timeline Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('View All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (displayedItems.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No sessions logged yet.', style: TextStyle(color: AppColors.slate400)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedItems.length,
                  itemBuilder: (context, index) {
                    final s = displayedItems[index];
                    final session = s['session'] as FocusSession;
                    final startTime = session.timestamp;
                    final endTime = session.timestamp.add(session.duration);
                    final timeRange = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                    return _TimelineTile(
                      title: s['taskName'],
                      category: s['goalTitle'],
                      timeRange: timeRange,
                      historyCount: s['historyCount'],
                      isLast: index == displayedItems.length - 1,
                      onTap: () {
                        if (onSessionTap != null) {
                          onSessionTap!.call(s['goal'], s['task'], s['session']);
                        } else {
                          onGoalTap?.call(s['goal']);
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineTile extends StatefulWidget {
  final String title;
  final String category;
  final String timeRange;
  final int historyCount;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineTile({
    required this.title,
    required this.category,
    required this.timeRange,
    required this.historyCount,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_TimelineTile> createState() => _TimelineTileState();
}

class _TimelineTileState extends State<_TimelineTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Content Column
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isHovered ? AppColors.primary.withOpacity(0.8) : AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            widget.timeRange,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.history, size: 14, color: AppColors.slate400),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.historyCount} times previously',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}