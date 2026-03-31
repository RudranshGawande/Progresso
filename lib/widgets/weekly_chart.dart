import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/widgets/responsive.dart';
import 'package:progresso/services/goal_service.dart';

class WeeklyProgressChart extends StatelessWidget {
  const WeeklyProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    
    return ListenableBuilder(
      listenable: GoalService(),
      builder: (context, _) {
        final goals = GoalService().goals;
        final List<double> weeklyEffort = List.filled(7, 0.0);
        double totalWeekHours = 0;

        for (var goal in goals) {
          for (int i = 0; i < 7; i++) {
            if (goal.dailyEffort.length > i) {
              weeklyEffort[i] += goal.dailyEffort[i];
              totalWeekHours += goal.dailyEffort[i];
            }
          }
        }

        final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
        final List<(String, double)> bars = [];
        
        // Scale: 1.0 = 8 hours of work (arbitrary max for visualization)
        for (int i = 0; i < 7; i++) {
          double pct = (weeklyEffort[i] / 8.0).clamp(0.0, 1.0);
          // If all values are very small, maybe scale differently? 
          // For now let's stick to 8h max.
          bars.add((days[i], pct));
        }

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Progress',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate900)),
                        const SizedBox(height: 4),
                        Text(
                            isMobile
                                ? 'Focus: ${totalWeekHours.toStringAsFixed(1)}h'
                                : 'Total focus hours this week: ${totalWeekHours.toStringAsFixed(1)}h',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    Row(
                      children: [
                        _LegendDot(color: AppColors.primary, label: 'Current'),
                        const SizedBox(width: 16),
                        _LegendDot(color: AppColors.slate200, label: 'Previous'),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _LegendDot(color: AppColors.primary, label: 'Current'),
                        const SizedBox(height: 4),
                        _LegendDot(color: AppColors.slate200, label: 'Previous'),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 32),
              // Chart
              SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: bars.map((bar) {
                    final (day, pct) = bar;
                    const barMaxHeight = 192.0;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 3 : 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: barMaxHeight,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.slate100,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(6)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: barMaxHeight * pct,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(6)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day,
                              style: TextStyle(
                                fontSize: isMobile ? 9 : 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: AppColors.slate500)),
      ],
    );
  }
}