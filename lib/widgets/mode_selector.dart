import 'package:flutter/material.dart';
import '../models/ac_state.dart';

class ModeSelector extends StatelessWidget {
  final bool power;
  final AcMode currentMode;
  final ValueChanged<AcMode> onModeChanged;

  const ModeSelector({
    super.key,
    required this.power,
    required this.currentMode,
    required this.onModeChanged,
  });

  IconData _getModeIcon(AcMode mode) {
    switch (mode) {
      case AcMode.cool:
        return Icons.ac_unit;
      case AcMode.dry:
        return Icons.water_drop_outlined;
      case AcMode.fan:
        return Icons.air;
      case AcMode.auto:
        return Icons.autorenew;
      case AcMode.heat:
        return Icons.wb_sunny_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MODE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: AcMode.values.map((mode) {
            final isSelected = currentMode == mode;
            final isEnabled = power;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: isEnabled ? () => onModeChanged(mode) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected && isEnabled
                          ? const Color(0xFF0284C7)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected && isEnabled
                            ? const Color(0xFF38BDF8)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getModeIcon(mode),
                          size: 20,
                          color: isEnabled
                              ? (isSelected ? Colors.white : Colors.white70)
                              : Colors.white24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isEnabled
                                ? (isSelected ? Colors.white : Colors.white60)
                                : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
