import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progresso/theme/app_colors.dart';
import 'package:progresso/widgets/responsive.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/widgets/custom_date_range_picker.dart';
import 'package:progresso/theme/settings_notifier.dart';
import 'package:progresso/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SessionWithMeta {
  final FocusSession session;
  final String displayName;
  final IconData goalIcon;

  SessionWithMeta({
    required this.session,
    required this.displayName,
    required this.goalIcon,
  });
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String _selectedPeriod = 'Today';
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final settingsNotifier = Provider.of<SettingsNotifier>(context);

    return ListenableBuilder(
      listenable: Listenable.merge([GoalService(), settingsNotifier]),
      builder: (context, _) {
        final allGoals = GoalService().goals;
        final settingsNotifier = Provider.of<SettingsNotifier>(context);
        
        final currentRange = _getCurrentRange(settingsNotifier);
        final prevRange = _getPreviousRange(currentRange);

        final currentStats = _gatherPeriodStats(allGoals, currentRange, settingsNotifier, period: _selectedPeriod);
        final prevStats = _gatherPeriodStats(allGoals, prevRange, settingsNotifier, period: _selectedPeriod);
        
        final periodSessions = currentStats.sessions;
        final totalHours = currentStats.totalHours;
        final avgFocusScore = currentStats.avgFocusScore;
        final avgSessionMinutes = currentStats.avgSessionMinutes;
        final completedTasksCount = currentStats.completedTasksCount;
        final sortedAllocation = currentStats.sortedAllocation;
        final chartData = currentStats.chartData;
        final chartLabels = currentStats.chartLabels;


        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          ),
          child: Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isMobile),
                  const SizedBox(height: 48),
                  _buildSectionTitle(
                    _selectedPeriod == 'Week' ? AppLocalizations.of(context)!.weeklyTotals.toUpperCase() : 
                    (_selectedPeriod == 'Month' ? AppLocalizations.of(context)!.monthlyTotals.toUpperCase() : 
                    (_selectedPeriod == 'Year' ? AppLocalizations.of(context)!.annualTotals.toUpperCase() : AppLocalizations.of(context)!.dailyOverview.toUpperCase()))
                  ),
                  const SizedBox(height: 16),
                  _buildDailyOverviewGrid(isMobile, currentStats, prevStats),
                  const SizedBox(height: 48),
                  _buildSectionTitle(
                    _selectedPeriod == 'Week' ? 'WEEKLY ANALYSIS' : 'TIMELINE ANALYSIS'
                  ),
                  const SizedBox(height: 16),
                  if (isMobile) ...[
                    if (_selectedPeriod == 'Year') 
                      _buildYearlyHeatmapCard(periodSessions) 
                    else if (_selectedPeriod == 'Month')
                      _buildHeatmapCard(periodSessions),
                    if (_selectedPeriod == 'Month' || _selectedPeriod == 'Year') const SizedBox(height: 24),
                    _buildTimeAllocationCard(totalHours, sortedAllocation),
                    const SizedBox(height: 24),
                    _buildProductivityTrendsCard(chartData, chartLabels),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2, 
                          child: _selectedPeriod == 'Year' 
                              ? _buildYearlyHeatmapCard(periodSessions) 
                              : (_selectedPeriod == 'Month' 
                                  ? _buildHeatmapCard(periodSessions) 
                                  : _buildProductivityTrendsCard(chartData, chartLabels)),
                        ),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildTimeAllocationCard(totalHours, sortedAllocation)),
                      ],
                    ),
                    if (_selectedPeriod == 'Month' || _selectedPeriod == 'Year') ...[
                      const SizedBox(height: 48),
                      _buildSectionTitle('ACTIVITY DETAILS'),
                      const SizedBox(height: 16),
                      _buildProductivityTrendsCard(chartData, chartLabels),
                    ],
                  ],
                  if (_selectedPeriod == 'Today') ...[
                    const SizedBox(height: 48),
                    _buildSectionTitle('ACTIVITY DETAILS'),
                    const SizedBox(height: 16),
                    _buildActivityDetails(isMobile, periodSessions),
                  ],
                  if (_selectedPeriod == 'Week') ...[
                    const SizedBox(height: 48),
                    _buildSectionTitle('WEEK DETAILS'),
                    const SizedBox(height: 16),
                    _buildWeeklyDetailCard(isMobile, periodSessions),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<SessionWithMeta> _getSessionsInRange(List<Goal> goals, DateTime start, DateTime end) {
    final List<SessionWithMeta> results = [];
    for (var goal in goals) {
      for (var task in goal.tasks) {
        for (var session in task.sessions) {
          final sessionEnd = session.timestamp.add(session.duration);
          if (sessionEnd.isAfter(start) && session.timestamp.isBefore(end)) {
            results.add(SessionWithMeta(
              session: session,
              displayName: goal.title,
              goalIcon: goal.icon,
            ));
          }
        }
      }
    }
    results.sort((a, b) => a.session.timestamp.compareTo(b.session.timestamp));
    return results;
  }

  List<GoalTask> _getCompletedTasksInRange(List<Goal> goals, DateTime start, DateTime end) {
    final List<GoalTask> results = [];
    for (var goal in goals) {
      for (var task in goal.tasks) {
        if (task.isCompleted && task.completedAt != null) {
          if (task.completedAt!.isAfter(start) && task.completedAt!.isBefore(end)) {
            results.add(task);
          }
        }
      }
    }
    return results;
  }

  _PeriodStats _gatherPeriodStats(List<Goal> goals, DateTimeRange range, SettingsNotifier settingsNotifier, {String? period}) {
    final start = range.start;
    final end = range.end;

    final periodSessions = _getSessionsInRange(goals, start, end);
    final completedTasks = _getCompletedTasksInRange(goals, start, end);

    final double totalHours = periodSessions.fold(0.0, (sum, s) => sum + (s.session.duration.inMinutes / 60.0));
    final double avgFocusScore = periodSessions.isEmpty ? 0 : periodSessions.fold(0.0, (sum, s) => sum + s.session.focusScore) / periodSessions.length;
    final double avgSessionMinutes = periodSessions.isEmpty ? 0 : (totalHours * 60) / periodSessions.length;

    final Map<String, double> allocation = {};
    for (var s in periodSessions) {
      allocation[s.displayName] = (allocation[s.displayName] ?? 0) + (s.session.duration.inMinutes / 60.0);
    }
    final sortedAllocation = allocation.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final List<double> chartData = [];
    final List<String> chartLabels = [];

    if (period == 'Today') {
      final List<double> hourlyIntensity = List.filled(24, 0.0);
      for (var s in periodSessions) {
        final hour = s.session.timestamp.hour;
        if (s.session.intensity > hourlyIntensity[hour]) hourlyIntensity[hour] = s.session.intensity;
      }
      for (int i = 9; i <= 19; i += 2) {
        chartData.add(hourlyIntensity[i]);
      }
      chartLabels.addAll(['9 AM', '11 AM', '1 PM', '3 PM', '5 PM', 'NOW']);
    } else if (period == 'Week') {
      final int firstDay = settingsNotifier.firstDayOfWeek;
      final List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      final List<String> orderedLabels = [];
      for (int i = 0; i < 7; i++) {
        orderedLabels.add(days[(firstDay - 1 + i) % 7]);
      }
      
      final List<double> dailyIntensity = List.filled(7, 0.0);
      for (var s in periodSessions) {
        // weekday is 1 for Mon, 7 for Sun.
        // We want 0 for firstDay, 6 for lastDay.
        final dayIdx = (s.session.timestamp.weekday - firstDay) % 7;
        dailyIntensity[dayIdx] = max(dailyIntensity[dayIdx], s.session.intensity);
      }
      chartData.addAll(dailyIntensity);
      chartLabels.addAll(orderedLabels);
    } else if (period == 'Month') {
      chartLabels.addAll(['WEEK 1', 'WEEK 2', 'WEEK 3', 'WEEK 4', 'END']);
      for (int i = 0; i < 5; i++) {
        final d = start.add(Duration(days: i * 7));
        final dayEnd = d.add(const Duration(days: 7));
        final daySessions = _getSessionsInRange(goals, d, dayEnd);
        chartData.add(daySessions.isEmpty ? 0 : daySessions.fold(0.0, (sum, s) => sum + s.session.intensity) / daySessions.length);
      }
    } else if (period == 'Custom') {
      final days = end.difference(start).inDays;
      final step = max(1, (days / 5).floor());
      for (int i = 0; i < 6; i++) {
        final d = start.add(Duration(days: i * step));
        if (i == 5) {
           chartLabels.add('END');
        } else {
           chartLabels.add(DateFormat('MMM dd').format(d).toUpperCase());
        }
        final dayEnd = d.add(const Duration(days: 1));
        final daySessions = _getSessionsInRange(goals, d, dayEnd);
        chartData.add(daySessions.isEmpty ? 0 : daySessions.fold(0.0, (sum, s) => sum + s.session.intensity) / daySessions.length);
      }
    } else if (period == 'Year') {
      final List<double> monthlyIntensity = List.filled(12, 0.0);
      for (var s in periodSessions) {
        final monthIdx = s.session.timestamp.month - 1;
        monthlyIntensity[monthIdx] = max(monthlyIntensity[monthIdx], s.session.intensity);
      }
      chartData.addAll(monthlyIntensity);
      chartLabels.addAll(['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']);
    }

    return _PeriodStats(
      sessions: periodSessions,
      totalHours: totalHours,
      avgFocusScore: avgFocusScore,
      avgSessionMinutes: avgSessionMinutes,
      completedTasksCount: completedTasks.length,
      sortedAllocation: sortedAllocation,
      chartData: chartData,
      chartLabels: chartLabels,
    );
  }

  DateTimeRange _getCurrentRange(SettingsNotifier settingsNotifier) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_selectedPeriod == 'Today') {
      return DateTimeRange(start: today, end: today.add(const Duration(days: 1)));
    } else if (_selectedPeriod == 'Week') {
      // Find previous start of week based on settings
      final int firstDay = settingsNotifier.firstDayOfWeek;
      int daysToSubtract = (today.weekday - firstDay) % 7;
      final start = today.subtract(Duration(days: daysToSubtract));
      return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
    } else if (_selectedPeriod == 'Month') {
      final start = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      return DateTimeRange(start: start, end: nextMonth);
    } else if (_selectedPeriod == 'Year') {
       final start = DateTime(now.year, 1, 1);
       final nextYear = DateTime(now.year + 1, 1, 1);
       return DateTimeRange(start: start, end: nextYear);
    } else if (_selectedPeriod == 'Custom' && _customRange != null) {
      return DateTimeRange(start: _customRange!.start, end: _customRange!.end.add(const Duration(days: 1)));
    }
    return DateTimeRange(start: today, end: today.add(const Duration(days: 1)));
  }

  DateTimeRange _getPreviousRange(DateTimeRange current) {
    if (_selectedPeriod == 'Today') {
      return DateTimeRange(start: current.start.subtract(const Duration(days: 1)), end: current.start);
    } else if (_selectedPeriod == 'Week') {
      return DateTimeRange(start: current.start.subtract(const Duration(days: 7)), end: current.start);
    } else if (_selectedPeriod == 'Month') {
      final prevMonth = DateTime(current.start.year, current.start.month - 1, 1);
      final end = DateTime(current.start.year, current.start.month, 1);
      return DateTimeRange(start: prevMonth, end: end);
    } else if (_selectedPeriod == 'Year') {
      return DateTimeRange(start: DateTime(current.start.year - 1, 1, 1), end: DateTime(current.start.year, 1, 1));
    } else {
      // Custom - same duration before
      final duration = current.duration;
      return DateTimeRange(start: current.start.subtract(duration), end: current.start);
    }
  }

  String _calculateTrend(double current, double previous) {
    if (previous == 0) return current > 0 ? '+100%' : '0%';
    final diff = ((current - previous) / previous) * 100;
    final sign = diff >= 0 ? '+' : '';
    if (diff.abs() > 999) return '${sign}999%';
    return '$sign${diff.toStringAsFixed(0)}%';
  }

  String _calculateStaticTrend(num current, num previous) {
     if (previous == 0) return current > 0 ? '+$current' : '0';
     final diff = current - previous;
     final sign = diff >= 0 ? '+' : '';
     return '$sign$diff';
  }


  String _getPeriodDescription() {
    switch (_selectedPeriod) {
      case 'Today': return 'Daily productivity overview and 24h metrics analysis.';
      case 'Week': return 'Weekly productivity trends and 7-day metrics analysis.';
      case 'Month': return 'Monthly performance metrics and consistency tracking.';
      case 'Year': return 'Annual productivity summary and long-term milestones.';
      case 'Custom': return 'Customized productivity report for the selected range.';
      default: return 'Comprehensive overview of your productivity metrics.';
    }
  }

  String _formatMinutes(double minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) return '${minutes.toInt()}m';
    final int h = minutes ~/ 60;
    final int m = minutes.toInt() % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.slate400,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    AppLocalizations.of(context)!.performanceInsights,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPeriodDescription(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) _buildPeriodSelector(),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 24),
          _buildPeriodSelector(),
        ],
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('Today', AppLocalizations.of(context)!.today),
          _buildPeriodButton('Week', AppLocalizations.of(context)!.week),
          _buildPeriodButton('Month', AppLocalizations.of(context)!.month),
          _buildPeriodButton('Year', AppLocalizations.of(context)!.year),
          _buildPeriodButton('Custom', AppLocalizations.of(context)!.custom, icon: Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String key, String label, {IconData? icon}) {
    final bool isActive = _selectedPeriod == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (key == 'Custom') {
          final range = await showDialog<DateTimeRange>(
            context: context,
            barrierColor: AppColors.slate900.withOpacity(0.4),
            builder: (context) {
              return CustomDateRangePicker(
                initialRange: _customRange,
              );
            },
          );
          if (range != null) {
            setState(() {
              _selectedPeriod = 'Custom';
              _customRange = range;
            });
          }
        } else {
          setState(() => _selectedPeriod = key);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? AppColors.white : AppColors.slate600,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 14,
                color: isActive ? AppColors.white : AppColors.slate600,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyOverviewGrid(bool isMobile, _PeriodStats current, _PeriodStats prev) {
    final periodLabel = ' ($_selectedPeriod)';
    
    // Total Hours
    final hoursTrend = _calculateTrend(current.totalHours, prev.totalHours);
    final isHoursPositive = current.totalHours >= prev.totalHours;

    // Focus Score
    final focusTrend = _calculateStaticTrend(current.avgFocusScore.toInt(), prev.avgFocusScore.toInt()) + ' pts';
    final isFocusPositive = current.avgFocusScore >= prev.avgFocusScore;

    // Session Length
    final sessionTrend = _calculateStaticTrend(current.avgSessionMinutes.round(), prev.avgSessionMinutes.round()) + ' min';
    final isSessionPositive = current.avgSessionMinutes >= prev.avgSessionMinutes;

    // Tasks Completed
    final tasksTrend = _calculateStaticTrend(current.completedTasksCount, prev.completedTasksCount);
    final isTasksPositive = current.completedTasksCount >= prev.completedTasksCount;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 4,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: isMobile ? 1.7 : 1.15,
      children: [
        _buildStatCard(
          icon: Icons.schedule,
          iconColor: AppColors.primary,
          label: '${AppLocalizations.of(context)!.totalHours}$periodLabel',
          value: '${current.totalHours.toStringAsFixed(1)}h',
          trend: hoursTrend,
          isPositive: isHoursPositive,
        ),
        _buildStatCard(
          icon: Icons.track_changes,
          iconColor: Colors.orange,
          label: '${AppLocalizations.of(context)!.focusScore}$periodLabel',
          value: '${current.avgFocusScore.toInt()}/100',
          trend: focusTrend,
          isPositive: isFocusPositive,
        ),
        _buildStatCard(
          icon: Icons.timer,
          iconColor: AppColors.blue500,
          label: '${AppLocalizations.of(context)!.avgSessionLength}$periodLabel',
          value: current.avgSessionMinutes >= 60 
                  ? '${(current.avgSessionMinutes / 60).floor()}h ${(current.avgSessionMinutes % 60).round()}m' 
                  : '${current.avgSessionMinutes.toInt()} min',
          trend: sessionTrend,
          isPositive: isSessionPositive,
        ),
        _buildStatCard(
          icon: Icons.done_all,
          iconColor: Colors.purple,
          label: '${AppLocalizations.of(context)!.tasksCompleted}$periodLabel',
          value: '${current.completedTasksCount}',
          trend: tasksTrend,
          isPositive: isTasksPositive,
        ),
      ],
    );
  }


  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.emerald50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? AppColors.emerald500 : Colors.red.shade500,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        color: isPositive ? AppColors.emerald500 : Colors.red.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityTrendsCard(List<double> chartData, List<String> chartLabels) {
    String title = 'Daily Productivity Trends';
    String description = 'Daily focus time over the last week';
    String trendLabel = 'WEEK TREND';
    String trendValue = '';

    if (_selectedPeriod == 'Today') {
      title = AppLocalizations.of(context)!.hourlyProductivityTrends;
      description = 'Focus intensity throughout today';
      trendLabel = 'PEAK INTENSITY';
      trendValue = '';
    } else if (_selectedPeriod == 'Month') {
      title = AppLocalizations.of(context)!.weeklyFocusComparison;
      description = 'Focus intensity trends across the month';
      trendLabel = 'MONTH TREND';
      trendValue = '';
    } else if (_selectedPeriod == 'Year') {
      title = AppLocalizations.of(context)!.yearlyProductivityTrends;
      description = 'Monthly focus distribution across the year';
      trendLabel = 'ANNUAL TREND';
      trendValue = '';
    } else {
      title = AppLocalizations.of(context)!.dailyProductivityTrends;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: AppColors.slate500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trendLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppColors.emerald500, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        trendValue,
                        style: GoogleFonts.inter(
                          color: AppColors.emerald500,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 240,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(data: chartData),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: chartLabels.map((l) => _buildChartLabel(l)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLabel(String label) {
    return Text(
      label, 
      style: const TextStyle(
        fontSize: 10, 
        fontWeight: FontWeight.w800, 
        color: AppColors.slate400,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTimeAllocationCard(double totalHours, List<MapEntry<String, double>> allocation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedPeriod == 'Today' ? 'Time Allocation' : (_selectedPeriod == 'Year' ? 'Time Allocation (Year)' : (_selectedPeriod == 'Week' ? 'Time Allocation (Week)' : 'Time Allocation (Month)')),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
          Text(
            (_selectedPeriod == 'Month' || _selectedPeriod == 'Year') ? 'Distribution across activities' : 'Distribution across categories',
            style: const TextStyle(fontSize: 14, color: AppColors.slate500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                children: [
                   CustomPaint(
                    size: const Size(180, 180),
                    painter: _DonutChartPainter(allocation: allocation, total: totalHours),
                  ),
                   Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totalHours > 0 ? '${totalHours.toStringAsFixed(1)}h' : '6.5h',
                          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slate900),
                        ),
                        Text(
                          'TOTAL',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.slate400, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(3, (index) {
            final categories = ['Work', 'Study', 'Admin'];
            final defaultHours = [890, 510, 280];
            final defaultPercents = [50, 30, 20];
            final colors = [AppColors.primary, AppColors.primary.withOpacity(0.6), AppColors.primary.withOpacity(0.3)];
            
            // Use real data if available, otherwise mock for design
            String name = (index < allocation.length) ? allocation[index].key : categories[index];
            double hours = (index < allocation.length) ? allocation[index].value : defaultHours[index].toDouble();
            int percent = (totalHours > 0 && index < allocation.length) ? ((hours / totalHours) * 100).toInt() : defaultPercents[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[index], 
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name, 
                        style: const TextStyle(
                          fontSize: 13, 
                          fontWeight: FontWeight.w600, 
                          color: AppColors.slate800,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyDetailCard(bool isMobile, List<SessionWithMeta> sessions) {
    final List<double> dailyHours = List.filled(7, 0.0);
    final List<int> dailyCount = List.filled(7, 0);
    for (var s in sessions) {
      final idx = (s.session.timestamp.weekday - 1) % 7;
      dailyHours[idx] += (s.session.duration.inMinutes / 60.0);
      dailyCount[idx]++;
    }
    
    final int totalSessions = sessions.length;
    final String mostActiveDay = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dailyHours.indexOf(dailyHours.reduce(max))];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Activity Summary',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Summary of focus blocks across the week', style: TextStyle(fontSize: 14, color: AppColors.slate500)),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('PRODUCTIVE', AppColors.emerald500),
                  const SizedBox(width: 16),
                  _buildLegendItem('IDLE CAPACITY', AppColors.slate200),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 280,
            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: List.generate(7, (i) {
                 final factors = [0.65, 0.85, 0.55, 0.92, 0.48, 0.25, 0.15];
                 return _WaveBar(
                   day: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][i], 
                   heightFactor: factors[i],
                   sessions: (factors[i] * 40).toInt(),
                 );
               }),
            ),
          ),
          const SizedBox(height: 40),
          Divider(color: AppColors.slate100, thickness: 1),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildMetricDetail('TOTAL SESSIONS', '35'),
              const SizedBox(width: 80),
              _buildMetricDetail('MOST ACTIVE DAY', 'Thursday'),
              const SizedBox(width: 80),
              _buildMetricDetail('COMPLETION RATE', '94%', valueColor: AppColors.emerald500),
            ],
          ),
        ],
      ),
    );
  }

  // Replaced _buildStackedBar with _WaveBar
  // Widget _buildStackedBar(String day, double heightFactor, int sessions) { ... }

  Widget _buildActivityDetails(bool isMobile, List<SessionWithMeta> sessions) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Focus vs Break Timeline',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const Text(
                    'Distribution of activity cycles',
                    style: TextStyle(fontSize: 14, color: AppColors.slate500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendDot('FOCUS', AppColors.emerald500),
                  const SizedBox(width: 20),
                  _buildLegendDot('BREAK', AppColors.amber500),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildTimelineGraphics(sessions),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChartLabel('9 AM'),
              _buildChartLabel('12 PM'),
              _buildChartLabel('3 PM'),
              _buildChartLabel('6 PM'),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: AppColors.slate100, thickness: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildMetricDetail('LONGEST STREAK', '2h 15m'),
              const SizedBox(width: 80),
              _buildMetricDetail('TOTAL BREAKS', '45m'),
              const SizedBox(width: 80),
              _buildMetricDetail('FOCUS RATIO', '82%', valueColor: AppColors.emerald500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.slate500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.slate500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineGraphics(List<SessionWithMeta> sessions) {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    children: [
                      _buildTimelineBlockWithLabel(width * 0.05, width * 0.15, AppColors.emerald500, '09:00 - 10:30 (Deep Work)'),
                      _buildTimelineBlock(width * 0.20, width * 0.03, AppColors.amber500),
                      _buildTimelineBlockWithLabel(width * 0.25, width * 0.22, AppColors.emerald500, '10:45 - 12:45 (Project A)'),
                      _buildTimelineBlockWithLunch(width * 0.52, width * 0.08, AppColors.slate300),
                      _buildTimelineBlockWithLabel(width * 0.65, width * 0.13, AppColors.emerald500, '14:00 - 15:15 (Meeting)'),
                      _buildTimelineBlock(width * 0.82, width * 0.04, AppColors.amber500),
                      _buildTimelineBlockWithLabel(width * 0.88, width * 0.07, AppColors.emerald500.withOpacity(0.7), '16:00 - 17:00 (Wrap up)'),
                    ],
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBlockWithLabel(double left, double width, Color color, String label) {
    return Positioned(
      left: left,
      top: 24,
      width: width,
      height: 12,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineBlockWithLunch(double left, double width, Color color) {
    return Positioned(
      left: left,
      top: 32, // Adjusted for taller container
      width: width,
      height: 40,
      child: Column(
        children: [
          Container(
            height: 12,
            width: width,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lunch',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBlock(double left, double width, Color color) {
    return Positioned(
      left: left,
      top: 14,
      width: width,
      height: 12,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
             BoxShadow(
               color: color.withOpacity(0.2),
               blurRadius: 4,
               offset: const Offset(0, 2),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricDetail(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.slate400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.slate900,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapCard(List<SessionWithMeta> sessions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = startOfMonth.weekday; // 1=Mon, 7=Sun
    final emptySlots = firstWeekday - 1;

    final Map<int, double> dailyIntensity = {};
    int totalFocusDays = 0;
    for (var s in sessions) {
      if (s.session.timestamp.year == now.year && s.session.timestamp.month == now.month) {
        final day = s.session.timestamp.day;
        dailyIntensity[day] = (dailyIntensity[day] ?? 0) + s.session.duration.inMinutes / 60.0;
      }
    }
    totalFocusDays = dailyIntensity.keys.length;

    int currentStreak = 0;
    int maxStreak = 0;
    for (int i = 1; i <= daysInMonth; i++) {
      if (dailyIntensity.containsKey(i) && dailyIntensity[i]! > 0) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }

    double totalHours = dailyIntensity.values.fold(0.0, (sum, h) => sum + h);
    double avgDailyFocus = daysInMonth > 0 ? totalHours / daysInMonth : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'Consistency Heatmap (Month)',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('High Focus', AppColors.emerald500),
                  const SizedBox(width: 16),
                  _buildLegendItem('Low Focus', AppColors.emerald200),
                  const SizedBox(width: 16),
                  _buildLegendItem('No Data', AppColors.slate100),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeekdayGridHeader(),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 2.0,
            ),
            itemCount: emptySlots + daysInMonth,
            itemBuilder: (context, index) {
              if (index < emptySlots) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.slate100.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }
              final dayNum = index - emptySlots + 1;
              final focusHours = dailyIntensity[dayNum] ?? 0;
              final isToday = dayNum == now.day;
              
              Color bgColor = AppColors.slate100;
              Color textColor = AppColors.slate400;
              
              if (focusHours > 4) {
                bgColor = AppColors.emerald500;
                textColor = AppColors.white;
              } else if (focusHours > 2) {
                bgColor = AppColors.emerald300;
                textColor = AppColors.white;
              } else if (focusHours > 0.5) {
                bgColor = AppColors.emerald200;
                textColor = AppColors.emerald600;
              } else if (focusHours > 0) {
                bgColor = AppColors.emerald100;
                textColor = AppColors.emerald600;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday ? Border.all(color: AppColors.emerald500, width: 2) : null,
                  boxShadow: isToday && focusHours > 4 ? [
                    BoxShadow(
                      color: AppColors.emerald500.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNum',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.slate100),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('LONGEST STREAK', '$maxStreak Days'),
              _buildMetricItem('TOTAL FOCUS DAYS', '$totalFocusDays Days'),
              _buildMetricItem('AVG DAILY FOCUS', '${avgDailyFocus.toStringAsFixed(1)}h', valueColor: AppColors.emerald500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayGridHeader() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      children: days.map((d) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            d,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.slate400,
              letterSpacing: 0.5,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMetricItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.slate400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppColors.slate900,
          ),
        ),
      ],
    );
  }

  Widget _buildYearlyHeatmapCard(List<SessionWithMeta> sessions) {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    final int daysInYear = endOfYear.difference(startOfYear).inDays + 1;

    final Map<int, double> dailyFocus = {};
    for (var s in sessions) {
      final dayOfYear = s.session.timestamp.difference(startOfYear).inDays + 1;
      dailyFocus[dayOfYear] = (dailyFocus[dayOfYear] ?? 0) + (s.session.duration.inMinutes / 60.0);
    }

    int currentStreak = 0;
    int maxStreak = 0;
    for (int i = 1; i <= daysInYear; i++) {
       if (dailyFocus.containsKey(i) && dailyFocus[i]! > 0) {
         currentStreak++;
         if (currentStreak > maxStreak) maxStreak = currentStreak;
       } else {
         currentStreak = 0;
       }
    }

    double totalFocusHours = dailyFocus.values.fold(0.0, (sum, h) => sum + h);
    double avgDailyFocus = daysInYear > 0 ? totalFocusHours / daysInYear : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistency Heatmap (Year)',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('High Focus', AppColors.emerald500),
                  const SizedBox(width: 16),
                  _buildLegendItem('Low Focus', AppColors.emerald200),
                  const SizedBox(width: 16),
                  _buildLegendItem('No Data', AppColors.slate100),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildYearlyHeatmapGrid(dailyFocus, startOfYear),
          const SizedBox(height: 32),
          Divider(color: AppColors.slate100),
          const SizedBox(height: 24),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LONGEST STREAK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.slate400, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text('$maxStreak Days', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                ],
              ),
              const SizedBox(width: 64),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AVG DAILY FOCUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.slate400, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text('${avgDailyFocus.toStringAsFixed(1)}h', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.emerald500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyHeatmapGrid(Map<int, double> dailyFocus, DateTime startOfYear) {
    final firstDayWeekday = startOfYear.weekday; // 1 = Mon, 7 = Sun
    final emptySlotsAtStart = firstDayWeekday - 1;
    final double itemSize = 18.0; // Increased from 14.0
    final double spacing = 5.0; // Increased from 4.0
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Labels
          Row(
            children: List.generate(12, (m) {
              final monthStart = DateTime(startOfYear.year, m + 1, 1);
              final dayIndex = monthStart.difference(startOfYear).inDays;
              final weekIndex = (dayIndex + emptySlotsAtStart) ~/ 7;
              
              return Container(
                width: m == 0 ? (weekIndex + 4.5) * (itemSize + spacing) : 4.42 * (itemSize + spacing),
                padding: EdgeInsets.only(left: m == 0 ? weekIndex * (itemSize + spacing) : 0),
                child: Text(
                  DateFormat('MMM').format(monthStart).toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.slate400),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: (itemSize * 7) + (spacing * 6),
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (53 * 7), 
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
              ),
              itemBuilder: (context, index) {
                final dayOfYear = index - emptySlotsAtStart + 1;
                if (dayOfYear <= 0 || dayOfYear > 366) {
                  return const SizedBox.shrink();
                }
                
                final focus = dailyFocus[dayOfYear] ?? 0;
                Color color = AppColors.slate50;
                if (focus > 6) color = AppColors.emerald500;
                else if (focus > 3) color = AppColors.emerald300;
                else if (focus > 0) color = AppColors.emerald100;
                
                final date = startOfYear.add(Duration(days: dayOfYear - 1));
                final dateStr = DateFormat('EEE, MMM d, yyyy').format(date);
                final focusStr = focus > 0 ? '${focus.toStringAsFixed(1)}h focus' : 'No activity';

                return Tooltip(
                  message: '$dateStr\n$focusStr',
                  child: Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: AppColors.slate100, width: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.1),
          AppColors.primary.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gridPaint = Paint()
      ..color = AppColors.slate100
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i < 5; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Mock data for the screenshot look if there is no real data
    final displayData = (data.isEmpty || data.every((e) => e == 0)) 
        ? [0.8, 0.7, 0.85, 0.55, 0.65, 0.4, 0.5, 0.2, 0.45, 0.25, 0.1, 0.15]
        : data;

    double maxVal = displayData.isNotEmpty ? displayData.reduce((a, b) => a > b ? a : b) : 1.0;
    // We only scale down if the maximum value exceeds 1.0 (to fit the graph)
    if (maxVal < 1.0) maxVal = 1.0;

    final List<Offset> points = [];
    final double xStep = size.width / max(1, displayData.length - 1);
    
    for (int i = 0; i < displayData.length; i++) {
      // Invert Y because 0 is at the top
      double normalizedY = displayData[i] / maxVal;
      // Added a 10% vertical padding so the peaks don't touch the very top edge
      double yPos = size.height - (normalizedY * (size.height * 0.9));
      points.add(Offset(i * xStep, yPos));
    }

    Path path = Path();
    Path fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
        fillPath.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points as in screenshot
    for (int i = 0; i < points.length; i++) {
      // Highlight certain points
      if (i == 7 || i == displayData.length - 2) {
        canvas.drawCircle(points[i], 4, Paint()..color = AppColors.primary);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> allocation;
  final double total;

  _DonutChartPainter({required this.allocation, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;

    // Background circle
    paint.color = AppColors.slate100;
    canvas.drawCircle(center, radius - 9, paint);

    if (total == 0 || allocation.isEmpty) {
       // Mock for design consistency if no data
       final mockRatios = [0.6, 0.3, 0.1];
       final colors = [AppColors.primary, AppColors.primary.withOpacity(0.5), AppColors.primary.withOpacity(0.2)];
       double startAngle = -pi / 2;
       for (int i = 0; i < mockRatios.length; i++) {
         final sweepAngle = mockRatios[i] * 2 * pi;
         paint.color = colors[i];
         canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 9), startAngle, sweepAngle, false, paint);
         startAngle += sweepAngle;
       }
       return;
    }

    double startAngle = -pi / 2;
    final colors = [AppColors.primary, AppColors.primary.withOpacity(0.6), AppColors.primary.withOpacity(0.3)];

    for (int i = 0; i < min(allocation.length, 3); i++) {
      final sweepAngle = (allocation[i].value / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 9), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WaveBar extends StatefulWidget {
  final String day;
  final double heightFactor;
  final int sessions;

  const _WaveBar({
    required this.day,
    required this.heightFactor,
    required this.sessions,
  });

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: '${(widget.heightFactor * 100).toInt()}% Productive',
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _WavePainter(
                              animationValue: _controller.value,
                              heightFactor: widget.heightFactor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.day,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _WavePainter extends CustomPainter {
  final double animationValue;
  final double heightFactor;

  _WavePainter({
    required this.animationValue,
    required this.heightFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald500
      ..style = PaintingStyle.fill;

    final path = Path();
    final double fillY = size.height * (1 - heightFactor);
    final double waveAmplitude = 8.0;
    
    // Create a smooth continuous wave by drawing two periods
    // One full period corresponds to the width of the container
    double xOffset = animationValue * size.width;
    
    path.moveTo(-size.width + xOffset, fillY);
    
    for (int i = 0; i < 2; i++) {
        double startX = (-1 + i) * size.width + xOffset;
        
        // Use quadratic bezier to approximate the SVG wave: M 0 150 Q 200 50 400 150 T 800 150
        // Crest
        path.quadraticBezierTo(
          startX + size.width * 0.25, 
          fillY - waveAmplitude, 
          startX + size.width * 0.5, 
          fillY
        );
        // Trough (mirrored)
        path.quadraticBezierTo(
          startX + size.width * 0.75, 
          fillY + waveAmplitude, 
          startX + size.width, 
          fillY
        );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}

class _PeriodStats {
  final List<SessionWithMeta> sessions;
  final double totalHours;
  final double avgFocusScore;
  final double avgSessionMinutes;
  final int completedTasksCount;
  final List<MapEntry<String, double>> sortedAllocation;
  final List<double> chartData;
  final List<String> chartLabels;

  _PeriodStats({
    required this.sessions,
    required this.totalHours,
    required this.avgFocusScore,
    required this.avgSessionMinutes,
    required this.completedTasksCount,
    required this.sortedAllocation,
    required this.chartData,
    required this.chartLabels,
  });
}
