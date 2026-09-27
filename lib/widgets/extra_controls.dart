import 'package:flutter/material.dart';

class ExtraControls extends StatelessWidget {
  final bool power;
  final bool swing;
  final VoidCallback onToggleSwing;
  final VoidCallback onResend;

  const ExtraControls({
    super.key,
    required this.power,
    required this.swing,
    required this.onToggleSwing,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: power ? onToggleSwing : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: swing && power ? const Color(0xFF0D9488) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_vert,
                    size: 20,
                    color: power ? Colors.white : Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SWING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: power ? Colors.white : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: power ? onResend : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: power ? const Color(0xFF38BDF8) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    size: 18,
                    color: power ? const Color(0xFF38BDF8) : Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RESEND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: power ? const Color(0xFF38BDF8) : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
