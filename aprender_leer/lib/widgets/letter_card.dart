import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class LetterCard extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;
  final bool isSelected;

  const LetterCard({
    super.key,
    required this.letter,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.secondaryColor : AppTheme.lightGray,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF1CB0F6) : AppTheme.lightGray,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 40, // Increased from 32
            fontWeight: FontWeight.w900, // Thicker weight
            color: isSelected ? Colors.white : AppTheme.textColor.withOpacity(0.9),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
