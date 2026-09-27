import 'package:flutter/material.dart';

class PowerTempControls extends StatelessWidget {
  final bool power;
  final VoidCallback onTogglePower;
  final VoidCallback onTempDown;
  final VoidCallback onTempUp;

  const PowerTempControls({
    super.key,
    required this.power,
    required this.onTogglePower,
    required this.onTempDown,
    required this.onTempUp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Power button
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: onTogglePower,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: power ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: power
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.power_settings_new,
                    size: 42,
                    color: power ? Colors.white : const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    power ? 'TURN OFF' : 'TURN ON',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: power ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Temp Up/Down
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.remove,
                    label: 'DOWN',
                    onTap: power ? onTempDown : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add,
                    label: 'UP',
                    onTap: power ? onTempUp : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF1E293B) : const Color(0xFF151D2A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled ? Colors.white12 : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: enabled ? const Color(0xFF38BDF8) : Colors.white24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.white70 : Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
