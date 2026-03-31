import 'package:flutter/material.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:intl/intl.dart';

class DailyIntensity {
  final DateTime date;
  final double averageIntensity;
  final int sessionCount;
  final String dayLabel;

  DailyIntensity({
    required this.date,
    required this.averageIntensity,
    required this.sessionCount,
    required this.dayLabel,
  });
}

class FocusIntensityPanel extends StatelessWidget {
  const FocusIntensityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GoalService(),
      builder: (context, _) {
        final goals = GoalService().goals;
        
        // 1. Setup the last 7 days
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final List<DailyIntensity> last7Days = List.generate(7, (index) {
          final date = today.subtract(Duration(days: 6 - index));
          return DailyIntensity(
            date: date,
            averageIntensity: 0,
            sessionCount: 0,
            dayLabel: DateFormat('E').format(date).toUpperCase(),
          );
        });

        // 2. Aggregate data
        double peakIntensity = 0;
        Duration totalDuration = Duration.zero;
        int totalSessions = 0;

        // Map for fast lookup of our 7 days
        final Map<DateTime, List<double>> dayMap = {
          for (var day in last7Days) day.date: []
        };

        for (var goal in goals) {
          for (var task in goal.tasks) {
            for (var session in task.sessions) {
              // Global metrics
              if (session.intensity > peakIntensity) peakIntensity = session.intensity;
              totalDuration += session.duration;
              totalSessions++;

              // Daily grouping
              final sDate = DateTime(session.timestamp.year, session.timestamp.month, session.timestamp.day);
              if (dayMap.containsKey(sDate)) {
                dayMap[sDate]!.add(session.intensity);
              }
            }
          }
        }

        // 3. Finalize daily averages
        final List<DailyIntensity> finalizedDays = last7Days.map((d) {
          final intensities = dayMap[d.date]!;
          if (intensities.isEmpty) return d;
          
          final avg = intensities.reduce((a, b) => a + b) / intensities.length;
          return DailyIntensity(
            date: d.date,
            averageIntensity: avg,
            sessionCount: intensities.length,
            dayLabel: d.dayLabel,
          );
        }).toList();

        final avgSessionMinutes = totalSessions > 0 ? totalDuration.inMinutes / totalSessions : 0.0;
        
        String formatDuration(double minutes) {
          if (minutes <= 0) return '0m';
          if (minutes < 60) return '${minutes.toInt()}m';
          final h = minutes ~/ 60;
          final m = minutes.toInt() % 60;
          return m == 0 ? '${h}h' : '${h}h ${m}m';
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), 
                blurRadius: 12, 
                offset: const Offset(0, 4)
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Daily Intensity',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w800, 
                      color: AppColors.slate900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'LAST 7 DAYS',
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.w800, 
                        color: AppColors.emerald600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: finalizedDays.map((data) {
                    const maxH = 100.0;
                    final bool hasData = data.sessionCount > 0;
                    
                    return Expanded(
                      child: Tooltip(
                        message: hasData 
                          ? '${data.sessionCount} focus sessions\nAvg Intensity: ${(data.averageIntensity * 100).toInt()}%'
                          : 'No sessions',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: hasData ? maxH * data.averageIntensity.clamp(0.2, 1.0) : 4.0,
                                decoration: BoxDecoration(
                                  color: hasData 
                                    ? AppColors.primary.withOpacity(data.averageIntensity.clamp(0.3, 1.0))
                                    : AppColors.slate100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.dayLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: hasData ? AppColors.slate600 : AppColors.slate300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  _buildStat('Peak', '${(peakIntensity * 100).toInt()}%'),
                  const SizedBox(width: 32),
                  _buildStat('Avg Session', formatDuration(avgSessionMinutes)),
                ],
              ),
            ],
          ),
        );

      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9, 
            fontWeight: FontWeight.w800, 
            color: AppColors.slate400,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w900, 
            color: AppColors.slate800,
          ),
        ),
      ],
    );
  }
}

