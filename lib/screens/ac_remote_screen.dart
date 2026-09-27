import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ac_state.dart';
import '../services/ac_protocol_helper.dart';
import '../services/ir_service.dart';
import '../widgets/ac_display_panel.dart';
import '../widgets/extra_controls.dart';
import '../widgets/fan_speed_selector.dart';
import '../widgets/ir_status_banner.dart';
import '../widgets/mode_selector.dart';
import '../widgets/power_temp_controls.dart';
import '../widgets/timer_control_section.dart';

class AcRemoteScreen extends StatefulWidget {
  const AcRemoteScreen({super.key});

  @override
  State<AcRemoteScreen> createState() => _AcRemoteScreenState();
}

class _AcRemoteScreenState extends State<AcRemoteScreen> {
  bool _hasIr = false;
  bool _isCheckingIr = true;

  // AC State (Sharp YB1FA default)
  AcState _acState = const AcState(brand: AcBrand.sharpYb1fa);

  // Timer Turn Off (Sleep) State in minutes
  int? _sleepTimerMinutes;
  DateTime? _sleepTargetTime;

  // Timer Turn On (Wake) State in minutes
  int? _wakeTimerMinutes;
  DateTime? _wakeTargetTime;

  Timer? _countdownTicker;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _checkIrStatus();
    _listenToNativeEvents();
    _startTicker();
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool needUpdate = false;
      final now = DateTime.now();

      if (_sleepTargetTime != null) {
        if (now.isAfter(_sleepTargetTime!)) {
          _acState = _acState.copyWith(power: false);
          _sleepTimerMinutes = null;
          _sleepTargetTime = null;
        }
        needUpdate = true;
      }

      if (_wakeTargetTime != null) {
        if (now.isAfter(_wakeTargetTime!)) {
          _acState = _acState.copyWith(power: true);
          _wakeTimerMinutes = null;
          _wakeTargetTime = null;
        }
        needUpdate = true;
      }

      if (needUpdate && mounted) {
        setState(() {});
      }
    });
  }

  void _listenToNativeEvents() {
    _eventSubscription = IrService.eventStream.listen((event) {
      if (!mounted) return;
      if (event == 'AC_OFF_FIRED') {
        setState(() {
          _acState = _acState.copyWith(power: false);
          _sleepTimerMinutes = null;
          _sleepTargetTime = null;
        });
      } else if (event == 'AC_ON_FIRED') {
        setState(() {
          _acState = _acState.copyWith(power: true);
          _wakeTimerMinutes = null;
          _wakeTargetTime = null;
        });
      }
    });
  }

  Future<void> _checkIrStatus() async {
    final hasIr = await IrService.hasIrEmitter();
    if (mounted) {
      setState(() {
        _hasIr = hasIr;
        _isCheckingIr = false;
      });
    }
  }

  Future<void> _sendSignal({AcState? customState}) async {
    HapticFeedback.lightImpact();
    final stateToSend = customState ?? _acState;

    final pattern = AcProtocolHelper.generateAcSignal(
      brand: stateToSend.brand,
      power: stateToSend.power,
      mode: stateToSend.mode,
      temperature: stateToSend.temperature,
      fanSpeed: stateToSend.fanSpeed,
      swing: stateToSend.swing,
    );

    try {
      await IrService.transmit(
        frequency: AcProtocolHelper.defaultFrequency,
        pattern: pattern,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sinyal IR ${stateToSend.brand.label} terkirim'),
            duration: const Duration(milliseconds: 700),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Info: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _togglePower() {
    final newPower = !_acState.power;
    setState(() {
      _acState = _acState.copyWith(power: newPower);
      if (!newPower && _sleepTimerMinutes != null) {
        _cancelSleepTimer();
      }
    });
    _sendSignal();
  }

  void _changeTemperature(int delta) {
    if (!_acState.power) return;
    final isSharpStandard = _acState.brand == AcBrand.sharpA907 ||
        _acState.brand == AcBrand.sharpA903 ||
        _acState.brand == AcBrand.sharpA705;
    final minTemp = isSharpStandard ? 15 : 16;
    final newTemp = _acState.temperature + delta;
    if (newTemp >= minTemp && newTemp <= 30) {
      setState(() {
        _acState = _acState.copyWith(temperature: newTemp);
      });
      _sendSignal();
    }
  }

  void _changeMode(AcMode mode) {
    if (!_acState.power) return;
    setState(() {
      _acState = _acState.copyWith(mode: mode);
    });
    _sendSignal();
  }

  void _changeFanSpeed(AcFanSpeed speed) {
    if (!_acState.power) return;
    setState(() {
      _acState = _acState.copyWith(fanSpeed: speed);
    });
    _sendSignal();
  }

  void _toggleSwing() {
    if (!_acState.power) return;
    setState(() {
      _acState = _acState.copyWith(swing: !_acState.swing);
    });
    _sendSignal();
  }

  void _changeBrand(AcBrand brand) {
    setState(() {
      _acState = _acState.copyWith(brand: brand);
    });
    _sendSignal();
  }

  Future<void> _setSleepTimer(int minutes) async {
    if (!_acState.power) return;

    final seconds = minutes * 60;
    final offPattern = AcProtocolHelper.generateAcSignal(
      brand: _acState.brand,
      power: false,
      mode: _acState.mode,
      temperature: _acState.temperature,
      fanSpeed: _acState.fanSpeed,
      swing: _acState.swing,
    );

    try {
      await IrService.scheduleSleepTimer(
        delaySeconds: seconds,
        frequency: AcProtocolHelper.defaultFrequency,
        pattern: offPattern,
        actionType: 'OFF',
      );

      setState(() {
        _sleepTimerMinutes = minutes;
        _sleepTargetTime = DateTime.now().add(Duration(seconds: seconds));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final text = minutes >= 60 && minutes % 60 == 0
            ? '${minutes ~/ 60} jam'
            : '$minutes menit';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Timer MATI disetel: $text (Background Alarm aktif)'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal set timer mati: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _cancelSleepTimer() async {
    try {
      await IrService.cancelSleepTimer(actionType: 'OFF');
    } catch (_) {}

    setState(() {
      _sleepTimerMinutes = null;
      _sleepTargetTime = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timer matikan AC dibatalkan'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _setWakeTimer(int minutes) async {
    final seconds = minutes * 60;
    final onPattern = AcProtocolHelper.generateAcSignal(
      brand: _acState.brand,
      power: true,
      mode: _acState.mode,
      temperature: _acState.temperature,
      fanSpeed: _acState.fanSpeed,
      swing: _acState.swing,
    );

    try {
      await IrService.scheduleSleepTimer(
        delaySeconds: seconds,
        frequency: AcProtocolHelper.defaultFrequency,
        pattern: onPattern,
        actionType: 'ON',
      );

      setState(() {
        _wakeTimerMinutes = minutes;
        _wakeTargetTime = DateTime.now().add(Duration(seconds: seconds));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final text = minutes >= 60 && minutes % 60 == 0
            ? '${minutes ~/ 60} jam'
            : '$minutes menit';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Timer NYALA disetel: $text (Background Alarm aktif)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal set timer nyala: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _cancelWakeTimer() async {
    try {
      await IrService.cancelSleepTimer(actionType: 'ON');
    } catch (_) {}

    setState(() {
      _wakeTimerMinutes = null;
      _wakeTargetTime = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timer nyalakan AC dibatalkan'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  String _getFormattedRemainingOffTime() {
    if (_sleepTargetTime == null) return '';
    final diff = _sleepTargetTime!.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  String _getFormattedRemainingOnTime() {
    if (_wakeTargetTime == null) return '';
    final diff = _wakeTargetTime!.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IR AC REMOTE',
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          PopupMenuButton<AcBrand>(
            initialValue: _acState.brand,
            tooltip: 'Pilih Merk AC',
            icon: const Icon(Icons.settings_remote, color: Color(0xFF38BDF8)),
            onSelected: _changeBrand,
            itemBuilder: (context) => AcBrand.values
                .map((b) => PopupMenuItem(value: b, child: Text(b.label)))
                .toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IrStatusBanner(
                isChecking: _isCheckingIr,
                hasIr: _hasIr,
              ),
              const SizedBox(height: 16),
              AcDisplayPanel(
                state: _acState,
                remainingSleepTime: _getFormattedRemainingOffTime(),
                remainingTurnOnTime: _getFormattedRemainingOnTime(),
              ),
              const SizedBox(height: 24),
              PowerTempControls(
                power: _acState.power,
                onTogglePower: _togglePower,
                onTempDown: () => _changeTemperature(-1),
                onTempUp: () => _changeTemperature(1),
              ),
              const SizedBox(height: 20),
              ModeSelector(
                power: _acState.power,
                currentMode: _acState.mode,
                onModeChanged: _changeMode,
              ),
              const SizedBox(height: 20),
              FanSpeedSelector(
                power: _acState.power,
                currentSpeed: _acState.fanSpeed,
                onSpeedChanged: _changeFanSpeed,
              ),
              const SizedBox(height: 20),
              TimerControlSection(
                isAcOn: _acState.power,
                offMinutes: _sleepTimerMinutes,
                offRemainingTime: _getFormattedRemainingOffTime(),
                onSetOffTimer: _setSleepTimer,
                onCancelOffTimer: _cancelSleepTimer,
                onMinutes: _wakeTimerMinutes,
                onRemainingTime: _getFormattedRemainingOnTime(),
                onSetOnTimer: _setWakeTimer,
                onCancelOnTimer: _cancelWakeTimer,
              ),
              const SizedBox(height: 20),
              ExtraControls(
                power: _acState.power,
                swing: _acState.swing,
                onToggleSwing: _toggleSwing,
                onResend: () => _sendSignal(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
