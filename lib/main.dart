import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progresso/screens/auth_screen.dart';
import 'package:progresso/services/session_manager.dart';
import 'package:progresso/services/goal_service.dart';
import 'package:progresso/services/workspace_service.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    
    await SessionManager().init();
    await GoalService().init();
    await WorkspaceService().init();
  } catch (e, stack) {
    developer.log('Error during initialization', error: e, stackTrace: stack);
  }
  runApp(const ProgressoApp());
}

class ProgressoApp extends StatelessWidget {
  const ProgressoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROGRESSO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
      ),

      home: const AuthScreen(),
    );
  }
}

