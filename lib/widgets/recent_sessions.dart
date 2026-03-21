import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/services/session_repository.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/widgets/session_card.dart';


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
    final userId = AuthService().currentUser?['email'] ?? AuthService().currentUser?['auth']?['email'];
    if (userId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Independent Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          // Fetching sessions independently from DB, not from nested goal objects
          future: SessionRepository().fetchSessionsForGoal('all', userId), // Restricted to current account only
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ));
            }

            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No independent sessions found in DB.', 
                    style: TextStyle(color: AppColors.slate400)),
                ),
              );
            }

            // Show latest 3 sessions using the heavy session card
            final displaySessions = sessions.reversed.take(3).toList();

            return Column(
              children: displaySessions.map((session) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SessionCard(session: session, userId: userId),
              )).toList(),
            );
          },
        ),
      ],
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
                            style: const TextStyle(
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.history, size: 14, color: AppColors.slate400),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.historyCount} times previously',
                            style: const TextStyle(
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
