import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/screens/main_shell.dart';
import 'package:progresso/services/session_manager.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/services/mongodb_service.dart';
import 'package:progresso/services/auth_service.dart';
import 'package:progresso/theme/theme_notifier.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    
    await SessionManager().init();
    await GoalService().init();
    
    // Attempt MongoDB connection (Requires password in mongodb_service.dart)
    try {
      await MongoDBService().connect();
    } catch (e) {
      developer.log('MongoDB not connected yet. Ensure password is set in mongodb_service.dart');
    }
    
    // Check if user is already logged in
    final bool loggedIn = await AuthService().isLoggedIn();
    runApp(ProgressoApp(isLoggedIn: loggedIn));
  } catch (e, stack) {
    developer.log('Error during initialization', error: e, stackTrace: stack);
    runApp(const ProgressoApp(isLoggedIn: false));
  }
}

class ProgressoApp extends StatelessWidget {
  final bool isLoggedIn;
  const ProgressoApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.backspace): const DeleteCharacterIntent(forward: false),
            SingleActivator(LogicalKeyboardKey.delete): const DeleteCharacterIntent(forward: true),
          },
          child: MaterialApp(
            title: 'PROGRESSO',
            debugShowCheckedModeBanner: false,
            themeMode: themeNotifier.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5048E5)),
              textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
              scaffoldBackgroundColor: const Color(0xFFF6F6F8),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5048E5), 
                brightness: Brightness.dark
              ),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              scaffoldBackgroundColor: const Color(0xFF0F172A),
            ),
            home: isLoggedIn ? const MainShell() : const AuthScreen(),
          ),
        );
      },
    );
  }
}
