// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get accountSettingsDesc =>
      'Manage your account preferences, language, and regional settings.';

  @override
  String get language => 'Language';

  @override
  String get timezone => 'Timezone';

  @override
  String get weekStart => 'Week Start';

  @override
  String get sunday => 'Sunday';

  @override
  String get monday => 'Monday';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get totalHours => 'Total Hours';

  @override
  String get productivityTrends => 'Productivity Trends';

  @override
  String get dailyProductivityTrends => 'Daily Productivity Trends';

  @override
  String get hourlyProductivityTrends => 'Hourly Productivity Trends';

  @override
  String get weeklyFocusComparison => 'Weekly Focus Comparison';

  @override
  String get yearlyProductivityTrends => 'Yearly Productivity Trends';

  @override
  String get totalHoursWorked => 'Total Hours Worked';

  @override
  String get focusScore => 'Focus Score';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get goalAnalytics => 'Goal Analytics';

  @override
  String get dashboardOverview => 'Dashboard Overview';

  @override
  String get welcomeBack => 'Welcome back, here\'s what\'s happening today.';

  @override
  String get searchSessions => 'Search sessions...';

  @override
  String get startNewSession => 'Start New Session';

  @override
  String get weeklyProgress => 'Weekly Progress';

  @override
  String totalFocusHours(Object hours) {
    return 'Total focus hours this week: ${hours}h';
  }

  @override
  String get current => 'Current';

  @override
  String get previous => 'Previous';

  @override
  String get start => 'Start';

  @override
  String focus(Object hours) {
    return 'Focus: ${hours}h';
  }

  @override
  String get performanceInsights => 'Performance Insights';

  @override
  String get dailyOverview => 'Daily Overview';

  @override
  String get weeklyTotals => 'Weekly Totals';

  @override
  String get monthlyTotals => 'Monthly Totals';

  @override
  String get annualTotals => 'Annual Totals';

  @override
  String get avgSessionLength => 'Avg Session Length';

  @override
  String get tasksCompleted => 'Tasks Completed';

  @override
  String get today => 'Today';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get custom => 'Custom';

  @override
  String get deleteAccountDesc =>
      'Permanently delete your account and all associated data. This action cannot be undone.';

  @override
  String get delete => 'Delete';
}
