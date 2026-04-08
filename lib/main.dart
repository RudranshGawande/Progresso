import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:progresso/screens/main_shell.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/services/session_manager.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/services/mongodb_service.dart';
import 'package:progresso/theme/settings_notifier.dart';
import 'package:progresso/services/workspace_service.dart';
import 'package:progresso/l10n/app_localizations.dart';
import 'package:progresso/splash_screen.dart';
import 'dart:developer' as developer;
import 'package:progresso/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MongoDBService().connect();
    developer.log('✅ MongoDB connected at startup');
  } catch (e) {
    developer.log('❌ MongoDB connection failed at startup: $e');
  }
  try {
    // Services will now initialize AFTER checking auth status
  } catch (e, stack) {
    developer.log('Error during setup', error: e, stackTrace: stack);
  }
  runApp(const ProgressoApp());
}

class ProgressoApp extends StatelessWidget {
  const ProgressoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: AuthService()),
        ChangeNotifierProvider<SettingsNotifier>.value(value: settingsNotifier),
        ChangeNotifierProvider<WorkspaceService>.value(
          value: WorkspaceService(),
        ),
      ],
      child: Consumer<SettingsNotifier>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'PROGRESSO',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              textTheme: GoogleFonts.interTextTheme(
                ThemeData.light().textTheme,
              ),
              scaffoldBackgroundColor: const Color(0xFFF6F6F8),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5048E5),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5048E5),
                brightness: Brightness.dark,
              ),
            ),
            locale: settings.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _AppEntryPoint(),
          );
        },
      ),
    );
  }
}

/// Checks auth state at startup and routes to AuthScreen or MainShell.
class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  bool _showSplash = true;
  bool _checkingAuth = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Show splash screen for 3 seconds, then check auth
    Future.delayed(const Duration(milliseconds: 6000), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
        _checkAuth();
      }
    });
  }

  Future<void> _checkAuth() async {
    try {
      final loggedIn = await AuthService().isLoggedIn();

      if (loggedIn) {
        // Initialize services with the authenticated user's context
        await SessionManager().init();
        await WorkspaceService().init();
        await GoalService().init();
      }

      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _checkingAuth = false;
        });
      }
    } catch (e) {
      developer.log('Auth check failed: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _checkingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen first
    if (_showSplash) {
      return const SplashScreen();
    }

    // Then check auth state
    if (_checkingAuth) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // AuthScreen handles its own navigation to MainShell after login.
    // If already logged in, go directly to MainShell.
    return _isLoggedIn ? const MainShell() : const AuthScreen();
  }
}
