import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant colors for children
  static const Color primaryColor = Color(0xFF58CC02); // Duolingo Green
  static const Color secondaryColor = Color(0xFF1CB0F6); // Sky Blue
  static const Color accentColor = Color(0xFFFF4B4B); // Vibrant Red
  static const Color warningColor = Color(0xFFFFC800); // Yellow
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF4B4B4B);
  static const Color lightGray = Color(0xFFE5E5E5);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Color(0xFF58A700),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ).copyWith(
          // Duolingo-style "3D" effect on press
          side: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return BorderSide.none;
            }
            return const BorderSide(color: Color(0xFF58A700), width: 4);
          }),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: lightGray, width: 2),
        ),
        color: Colors.white,
      ),
    );
  }
}
