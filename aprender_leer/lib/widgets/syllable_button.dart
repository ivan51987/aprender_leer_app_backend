import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SyllableButton extends StatelessWidget {
  final String syllable;
  final VoidCallback onTap;

  const SyllableButton({
    super.key,
    required this.syllable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        side: const BorderSide(color: AppTheme.primaryColor, width: 2),
        minimumSize: const Size(100, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        syllable,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
