import 'package:flutter/material.dart';
import '../models/ac_state.dart';

class AcDisplayPanel extends StatelessWidget {
  final AcState state;
  final String remainingSleepTime;
  final String remainingTurnOnTime;

  const AcDisplayPanel({
    super.key,
    required this.state,
    required this.remainingSleepTime,
    this.remainingTurnOnTime = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: state.power
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E1E24), const Color(0xFF121214)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: state.power ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: state.power
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.brand.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: state.power ? const Color(0xFF94A3B8) : Colors.white24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: state.power ? const Color(0xFF0284C7) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.power ? 'ON' : 'OFF',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.power ? '${state.temperature}' : '--',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  color: state.power ? Colors.white : Colors.white24,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '°C',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: state.power ? const Color(0xFF38BDF8) : Colors.white24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIndicator(
                icon: Icons.ac_unit,
                label: state.mode.displayName,
                active: state.power,
              ),
              _buildIndicator(
                icon: Icons.air,
                label: 'FAN: ${state.fanSpeed.displayName}',
                active: state.power,
              ),
              _buildIndicator(
                icon: Icons.swap_vert,
                label: state.swing ? 'SWING ON' : 'SWING OFF',
                active: state.power && state.swing,
              ),
              if (remainingSleepTime.isNotEmpty)
                _buildIndicator(
                  icon: Icons.nights_stay,
                  label: 'OFF: $remainingSleepTime',
                  active: state.power,
                ),
              if (remainingTurnOnTime.isNotEmpty)
                _buildIndicator(
                  icon: Icons.wb_sunny_outlined,
                  label: 'ON: $remainingTurnOnTime',
                  active: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required IconData icon, required String label, required bool active}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: active ? const Color(0xFF38BDF8) : Colors.white24,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white70 : Colors.white24,
          ),
        ),
      ],
    );
  }
}
