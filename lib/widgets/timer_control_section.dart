import 'package:flutter/material.dart';

class TimerControlSection extends StatelessWidget {
  final bool isAcOn;

  // Turn Off Timer State
  final int? offMinutes;
  final String offRemainingTime;
  final ValueChanged<int> onSetOffTimer;
  final VoidCallback onCancelOffTimer;

  // Turn On Timer State
  final int? onMinutes;
  final String onRemainingTime;
  final ValueChanged<int> onSetOnTimer;
  final VoidCallback onCancelOnTimer;

  const TimerControlSection({
    super.key,
    required this.isAcOn,
    required this.offMinutes,
    required this.offRemainingTime,
    required this.onSetOffTimer,
    required this.onCancelOffTimer,
    required this.onMinutes,
    required this.onRemainingTime,
    required this.onSetOnTimer,
    required this.onCancelOnTimer,
  });

  void _showCustomMinutesDialog(
    BuildContext context, {
    required String title,
    required Color color,
    required ValueChanged<int> onConfirm,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan durasi dalam menit (misal: 30, 45, 90, 120):',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: 'Contoh: 45',
                hintStyle: const TextStyle(color: Colors.white30),
                suffixText: 'menit',
                suffixStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0 && val <= 1440) {
                Navigator.of(ctx).pop();
                onConfirm(val);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan angka menit antara 1 - 1440 (24 jam)'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text(
              'Set Timer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Timer Turn Off (Sleep)
        _buildTimerBlock(
          context: context,
          title: 'TIMER MATIKAN AC (OFF)',
          icon: Icons.nights_stay,
          badgeColor: const Color(0xFFEF4444),
          activeBorderColor: const Color(0xFFEF4444),
          selectedColor: const Color(0xFF991B1B),
          selectedMinutes: offMinutes,
          remainingTime: offRemainingTime,
          isEnabled: isAcOn,
          onSelectMinutes: onSetOffTimer,
          onCancel: onCancelOffTimer,
        ),
        const SizedBox(height: 18),
        // 2. Timer Turn On (Wake)
        _buildTimerBlock(
          context: context,
          title: 'TIMER NYALAKAN AC (ON)',
          icon: Icons.wb_sunny_outlined,
          badgeColor: const Color(0xFF10B981),
          activeBorderColor: const Color(0xFF10B981),
          selectedColor: const Color(0xFF065F46),
          selectedMinutes: onMinutes,
          remainingTime: onRemainingTime,
          isEnabled: true, // Bisa diatur kapan saja
          onSelectMinutes: onSetOnTimer,
          onCancel: onCancelOnTimer,
        ),
      ],
    );
  }

  Widget _buildTimerBlock({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color badgeColor,
    required Color activeBorderColor,
    required Color selectedColor,
    required int? selectedMinutes,
    required String remainingTime,
    required bool isEnabled,
    required ValueChanged<int> onSelectMinutes,
    required VoidCallback onCancel,
  }) {
    final hasActiveTimer = selectedMinutes != null && remainingTime.isNotEmpty;
    const presets = [
      {'label': '30m', 'min': 30},
      {'label': '1H', 'min': 60},
      {'label': '2H', 'min': 120},
      {'label': '3H', 'min': 180},
    ];

    final isCustom = selectedMinutes != null &&
        !presets.any((p) => p['min'] == selectedMinutes);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151F32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveTimer
              ? activeBorderColor.withValues(alpha: 0.6)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: badgeColor),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: hasActiveTimer ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
              if (hasActiveTimer)
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'BATALKAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (hasActiveTimer) ...[
            const SizedBox(height: 6),
            Text(
              'Akan dieksekusi dalam: $remainingTime',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              ...presets.map((preset) {
                final minVal = preset['min'] as int;
                final label = preset['label'] as String;
                final isSelected = selectedMinutes == minVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: isEnabled
                          ? () {
                              if (isSelected) {
                                onCancel();
                              } else {
                                onSelectMinutes(minVal);
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected && isEnabled
                              ? selectedColor
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected && isEnabled
                                ? activeBorderColor
                                : Colors.transparent,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isEnabled
                                ? (isSelected ? Colors.white : Colors.white70)
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Tombol Custom Menit
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: isEnabled
                        ? () {
                            _showCustomMinutesDialog(
                              context,
                              title: title,
                              color: badgeColor,
                              onConfirm: onSelectMinutes,
                            );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isCustom && isEnabled
                            ? selectedColor
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCustom && isEnabled
                              ? activeBorderColor
                              : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_calendar,
                            size: 11,
                            color: isEnabled
                                ? (isCustom ? Colors.white : const Color(0xFF38BDF8))
                                : Colors.white24,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isCustom ? '${selectedMinutes}m' : '+Min',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? (isCustom ? Colors.white : const Color(0xFF38BDF8))
                                  : Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
