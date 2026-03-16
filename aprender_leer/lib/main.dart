import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'services/progress_service.dart';
import 'providers/game_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if a child is already registered
  final progressService = ProgressService();
  final isRegistered = await progressService.isRegistered();
  
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: LiteracyApp(isRegistered: isRegistered),
    ),
  );
}

class LiteracyApp extends StatelessWidget {
  final bool isRegistered;
  
  const LiteracyApp({super.key, required this.isRegistered});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aprender a Leer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isRegistered ? const HomeScreen() : const RegisterScreen(),
    );
  }
}
