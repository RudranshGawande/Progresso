import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/models/goal_models.dart';

class ActiveGoalsPanel extends StatelessWidget {
  final Function(Goal)? onGoalTap;
  final VoidCallback? onViewAll;

  const ActiveGoalsPanel({
    super.key,
    this.onGoalTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GoalService(),
      builder: (context, _) {
        final goals = GoalService().goals.where((g) => g.status == GoalStatus.active).take(3).toList();

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
                  const Text('Active Goals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (goals.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No active goals.', style: TextStyle(color: AppColors.slate400)),
                  ),
                )
              else
                ...goals.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GoalItem(
                    goal: g,
                    onTap: () => onGoalTap?.call(g),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}

class _GoalItem extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _GoalItem({
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48, height: 48,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(48, 48),
                    painter: _CircleProgressPainter(
                      progress: goal.progress,
                      progressColor: AppColors.primary,
                      bgColor: AppColors.slate200,
                      strokeWidth: 4,
                    ),
                  ),
                  Center(
                    child: Text('${(goal.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                  const SizedBox(height: 2),
                  Text('${goal.completedTasksCount}/${goal.tasks.length} Tasks Completed',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color bgColor;
  final double strokeWidth;

  const _CircleProgressPainter({
    required this.progress, required this.progressColor,
    required this.bgColor, required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
