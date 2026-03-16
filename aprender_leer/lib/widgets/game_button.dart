import 'package:flutter/material.dart';

class GameButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFF58CC02),
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(label),
    );
  }
}
