import 'package:flutter/material.dart';
import '../models/ac_state.dart';

class FanSpeedSelector extends StatelessWidget {
  final bool power;
  final AcFanSpeed currentSpeed;
  final ValueChanged<AcFanSpeed> onSpeedChanged;

  const FanSpeedSelector({
    super.key,
    required this.power,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FAN SPEED',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: AcFanSpeed.values.map((speed) {
            final isSelected = currentSpeed == speed;
            final isEnabled = power;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: isEnabled ? () => onSpeedChanged(speed) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected && isEnabled
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected && isEnabled
                            ? const Color(0xFF818CF8)
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      speed.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isEnabled
                            ? (isSelected ? Colors.white : Colors.white60)
                            : Colors.white24,
                      ),
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
