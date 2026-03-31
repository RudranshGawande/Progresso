import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progresso/models/goal_models.dart';
import 'package:progresso/screens/goal_detail_screen.dart';
import 'package:progresso/widgets/session_type_selection_dialog.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUp(() async {
    HttpOverrides.global = null; // Reset any previous overrides
    SharedPreferences.setMockInitialValues({});
    await GoalService().init(forceReset: true);
    await SessionManager().init();
  });

  testWidgets('Session type selection dialog shown for first-time task focus', (WidgetTester tester) async {
    // Ignore network image errors in tests to avoid test failure
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) {
        return;
      }
      originalOnError?.call(details);
    };

    // 0. Set up larger screen size to avoid overflows in tests
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. Create a Goal with multiple tasks
    final task1 = GoalTask(
      id: 'task_1',
      name: 'Task 1',
      deadline: DateTime.now().add(const Duration(days: 1)),
      sessions: [
        FocusSession(
          id: 's1',
          duration: const Duration(minutes: 30),
          intensity: 0.8,
          focusScore: 85,
          trendData: [0.5, 0.8],
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        )
      ],
      sessionType: FocusSessionType.timed,
    );

    final task2 = GoalTask(
      id: 'task_2',
      name: 'Task 2',
      deadline: DateTime.now().add(const Duration(days: 2)),
      sessions: [],
      sessionType: null,
    );

    final goal = Goal(
      id: 'goal_1',
      title: 'Test Goal',
      description: 'Test Description',
      dueDate: DateTime.now().add(const Duration(days: 30)),
      tasks: [task1, task2],
    );

    // 2. Build the GoalDetailScreen
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: GoalDetailScreen(
            goal: goal,
            allGoals: [goal],
            onViewArchive: () {},
            onBack: () {},
          ),
        ),
      ),
    );

    // 3. Find Task 2 (the first-time task)
    // In GoalDetailScreen, tasks are rendered using _TaskItem widgets.
    // We can find it by its name.
    final task2Finder = find.text('Task 2');
    expect(task2Finder, findsOneWidget);

    // 4. Tap on Task 2 to start focus
    await tester.tap(task2Finder);
    await tester.pumpAndSettle();

    // 5. Verify that SessionTypeSelectionDialog is shown
    // The dialog contains the text 'Select Session Details'
    expect(find.text('Select Session Details'), findsOneWidget);
    expect(find.byType(SessionTypeSelectionDialog), findsOneWidget);
    
    // Check if both 'Timed' and 'Free Flow' options are visible
    expect(find.text('Timed'), findsOneWidget);
    expect(find.text('Free Flow'), findsOneWidget);
    
    // Reset onError
    FlutterError.onError = originalOnError;
  });

  testWidgets('Session type selection dialog NOT shown for tasks with existing type', (WidgetTester tester) async {
    // 0. Set up
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      originalOnError?.call(details);
    };

    // 1. Create a Goal with a task that already has a session type
    final task1 = GoalTask(
      id: 'task_1',
      name: 'Existing Task',
      deadline: DateTime.now().add(const Duration(days: 1)),
      sessions: [],
      sessionType: FocusSessionType.free,
    );

    final goal = Goal(
      id: 'goal_1',
      title: 'Test Goal',
      description: 'Test Description',
      dueDate: DateTime.now().add(const Duration(days: 30)),
      tasks: [task1],
    );

    // 2. Build the GoalDetailScreen
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: GoalDetailScreen(
            goal: goal,
            allGoals: [goal],
            onViewArchive: () {},
            onBack: () {},
          ),
        ),
      ),
    );

    // 3. Find and Tap Task 1
    final task1Finder = find.text('Existing Task');
    await tester.tap(task1Finder);
    await tester.pumpAndSettle();

    // 4. Verify that SessionTypeSelectionDialog is NOT shown
    expect(find.text('Select Session Details'), findsNothing);
    expect(find.byType(SessionTypeSelectionDialog), findsNothing);
    
    // 5. Verify it navigated to FocusSessionScreen or at least tried to
    // In our test it might have just pushed the route. We can check the route.
    // However, FocusSessionScreen should be in the tree now.
    expect(find.byType(GoalDetailScreen), findsNothing); 
    // This is because Navigator.push was called. In a simple test with no navigator mocking,
    // the pushed screen will be on top.

    // Reset onError
    FlutterError.onError = originalOnError;
  });
}
