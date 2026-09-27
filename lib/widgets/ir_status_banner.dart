import 'package:flutter/material.dart';

class IrStatusBanner extends StatelessWidget {
  final bool isChecking;
  final bool hasIr;

  const IrStatusBanner({
    super.key,
    required this.isChecking,
    required this.hasIr,
  });

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: const Text('Memeriksa sensor IR...', style: TextStyle(color: Colors.white70)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: hasIr ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasIr ? const Color(0xFF059669) : const Color(0xFFDC2626),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasIr ? Icons.check_circle : Icons.warning_amber_rounded,
            color: hasIr ? Colors.greenAccent : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasIr
                  ? 'IR Blaster Terdeteksi (Device Siap)'
                  : 'HP tidak memiliki IR Blaster internal. (Gunakan IR dongle jika perlu)',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
