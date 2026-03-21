import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/widgets/responsive.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/models/goal_models.dart';

class CTABanner extends StatelessWidget {
  final VoidCallback? onAction;

  const CTABanner({super.key, this.onAction});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return ListenableBuilder(
      listenable: GoalService(),
      builder: (context, _) {
        final goals = GoalService().goals;
        
        // 1. Dynamic Focus Insight
        int totalHours = goals.fold(0, (sum, g) => sum + g.totalTimeSpent.inHours);
        String insight = totalHours > 0 
          ? 'You have spent $totalHours hours focused recently. Keep it up!'
          : 'Ready to kickstart your productivity? Start your first focus session now.';

        // 2. Nearest Milestone
        GoalTask? nearestMilestone;
        String? milestoneGoalTitle;
        final now = DateTime.now();

        for (var goal in goals) {
          for (var task in goal.tasks) {
            if (task.priority == TaskPriority.milestone && !task.isCompleted && task.deadline.isAfter(now)) {
              if (nearestMilestone == null || task.deadline.isBefore(nearestMilestone.deadline)) {
                nearestMilestone = task;
                milestoneGoalTitle = goal.title;
              }
            }
          }
        }

        String milestoneText = nearestMilestone != null 
          ? '${nearestMilestone.name} in ${nearestMilestone.deadline.difference(now).inDays}d'
          : 'No upcoming milestones';
        

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Stack(
              children: [
                Positioned(
                  right: -80,
                  bottom: -80,
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  top: -40,
                  child: Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isMobile ? 24 : 32),
                  child: Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Expanded(child: _buildLeftContent(insight, onAction))
                      else
                        _buildLeftContent(insight, onAction),
                      if (isMobile) const SizedBox(height: 32) else const SizedBox(width: 32),
                      Container(
                        width: isMobile ? double.infinity : 320,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('UPCOMING',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.7),
                                        letterSpacing: 1)),
                                Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.7), size: 18),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(milestoneGoalTitle ?? 'No active milestones',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white)),
                            const SizedBox(height: 4),
                            Text(milestoneText,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftContent(String insight, VoidCallback? onAction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ready to Focus?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white)),
        const SizedBox(height: 8),
        Text(
          insight,
          style: TextStyle(fontSize: 14, color: AppColors.indigo100.withOpacity(0.9)),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View Full Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
