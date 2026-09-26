import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/ir_service.dart';
import 'services/ac_protocol_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const AcRemoteApp());
}

class AcRemoteApp extends StatelessWidget {
  const AcRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IR AC Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const AcRemoteScreen(),
    );
  }
}

class AcRemoteScreen extends StatefulWidget {
  const AcRemoteScreen({super.key});

  @override
  State<AcRemoteScreen> createState() => _AcRemoteScreenState();
}

class _AcRemoteScreenState extends State<AcRemoteScreen> {
  bool _hasIr = false;
  bool _isCheckingIr = true;

  // AC State
  bool _power = true;
  int _temperature = 24;
  AcMode _mode = AcMode.cool;
  AcFanSpeed _fanSpeed = AcFanSpeed.auto;
  bool _swing = false;
  String _selectedBrand = 'Gree';

  // Sleep Timer State
  int? _sleepTimerHours; // 1, 2, 3 dsb
  DateTime? _sleepTargetTime;
  Timer? _countdownTicker;
  StreamSubscription? _eventSubscription;

  final List<String> _brands = ['Gree', 'Panasonic', 'Samsung', 'LG', 'Daikin'];

  @override
  void initState() {
    super.initState();
    _checkIrStatus();
    _listenToNativeEvents();
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _listenToNativeEvents() {
    _eventSubscription = IrService.eventStream.listen((event) {
      if (event == 'AC_OFF_FIRED') {
        if (mounted) {
          setState(() {
            _power = false;
            _sleepTimerHours = null;
            _sleepTargetTime = null;
          });
          _countdownTicker?.cancel();
        }
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

  Future<void> _sendSignal() async {
    HapticFeedback.lightImpact();

    final pattern = AcProtocolHelper.generateAcSignal(
      brand: _selectedBrand,
      power: _power,
      mode: _mode,
      temperature: _temperature,
      fanSpeed: _fanSpeed,
      swing: _swing,
    );

    try {
      await IrService.transmit(
        frequency: AcProtocolHelper.defaultFrequency,
        pattern: pattern,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sinyal IR terkirim'),
            duration: Duration(milliseconds: 700),
            backgroundColor: Color(0xFF10B981),
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
    setState(() {
      _power = !_power;
      if (!_power && _sleepTimerHours != null) {
        _cancelSleepTimer();
      }
    });
    _sendSignal();
  }

  Future<void> _setSleepTimer(int hours) async {
    if (!_power) return;

    final seconds = hours * 3600;
    // Generate pattern untuk matikan AC (power = false)
    final offPattern = AcProtocolHelper.generateAcSignal(
      brand: _selectedBrand,
      power: false,
      mode: _mode,
      temperature: _temperature,
      fanSpeed: _fanSpeed,
      swing: _swing,
    );

    try {
      await IrService.scheduleSleepTimer(
        delaySeconds: seconds,
        frequency: AcProtocolHelper.defaultFrequency,
        pattern: offPattern,
      );

      setState(() {
        _sleepTimerHours = hours;
        _sleepTargetTime = DateTime.now().add(Duration(seconds: seconds));
      });

      _countdownTicker?.cancel();
      _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_sleepTargetTime == null) {
          timer.cancel();
          return;
        }
        if (DateTime.now().isAfter(_sleepTargetTime!)) {
          timer.cancel();
          setState(() {
            _power = false;
            _sleepTimerHours = null;
            _sleepTargetTime = null;
          });
        } else {
          setState(() {}); // refresh sisa waktu
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep timer disetel: $hours jam ke depan (Background Alarm aktif)'),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal set timer: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _cancelSleepTimer() async {
    try {
      await IrService.cancelSleepTimer();
    } catch (_) {}

    _countdownTicker?.cancel();
    setState(() {
      _sleepTimerHours = null;
      _sleepTargetTime = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep timer dibatalkan'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _changeTemperature(int delta) {
    if (!_power) return;
    final newTemp = _temperature + delta;
    if (newTemp >= 16 && newTemp <= 30) {
      setState(() {
        _temperature = newTemp;
      });
      _sendSignal();
    }
  }

  void _changeMode(AcMode mode) {
    if (!_power) return;
    setState(() {
      _mode = mode;
    });
    _sendSignal();
  }

  void _changeFanSpeed(AcFanSpeed fanSpeed) {
    if (!_power) return;
    setState(() {
      _fanSpeed = fanSpeed;
    });
    _sendSignal();
  }

  void _toggleSwing() {
    if (!_power) return;
    setState(() {
      _swing = !_swing;
    });
    _sendSignal();
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
          PopupMenuButton<String>(
            initialValue: _selectedBrand,
            tooltip: 'Pilih Merk AC',
            icon: const Icon(Icons.settings_remote, color: Color(0xFF38BDF8)),
            onSelected: (val) {
              setState(() {
                _selectedBrand = val;
              });
            },
            itemBuilder: (context) => _brands
                .map((b) => PopupMenuItem(value: b, child: Text(b)))
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
              _buildIrStatusBanner(),
              const SizedBox(height: 16),
              _buildAcDisplay(),
              const SizedBox(height: 24),
              _buildPowerAndTempControls(),
              const SizedBox(height: 20),
              _buildModeSelector(),
              const SizedBox(height: 20),
              _buildFanSpeedSelector(),
              const SizedBox(height: 20),
              _buildSleepTimerSelector(),
              const SizedBox(height: 20),
              _buildExtraControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIrStatusBanner() {
    if (_isCheckingIr) {
      return Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: const Text('Memeriksa sensor IR...', style: TextStyle(color: Colors.white70)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _hasIr ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasIr ? const Color(0xFF059669) : const Color(0xFFDC2626),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasIr ? Icons.check_circle : Icons.warning_amber_rounded,
            color: _hasIr ? Colors.greenAccent : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _hasIr
                  ? 'IR Blaster Terdeteksi (Device Siap)'
                  : 'HP tidak memiliki IR Blaster internal. (Gunakan IR dongle USB/Audio Jack jika perlu)',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _power
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E1E24), const Color(0xFF121214)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _power ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: _power
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
                _selectedBrand.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: _power ? const Color(0xFF94A3B8) : Colors.white24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _power ? const Color(0xFF0284C7) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _power ? 'ON' : 'OFF',
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
                _power ? '$_temperature' : '--',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  color: _power ? Colors.white : Colors.white24,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '°C',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _power ? const Color(0xFF38BDF8) : Colors.white24,
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
                label: _mode.name.toUpperCase(),
                active: _power,
              ),
              _buildIndicator(
                icon: Icons.air,
                label: 'FAN: ${_fanSpeed.name.toUpperCase()}',
                active: _power,
              ),
              _buildIndicator(
                icon: Icons.swap_vert,
                label: _swing ? 'SWING ON' : 'SWING OFF',
                active: _power && _swing,
              ),
              if (_sleepTargetTime != null)
                _buildIndicator(
                  icon: Icons.timer,
                  label: _getFormattedRemainingTime(),
                  active: _power,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFormattedRemainingTime() {
    if (_sleepTargetTime == null) return '';
    final diff = _sleepTargetTime!.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
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

  Widget _buildPowerAndTempControls() {
    return Row(
      children: [
        // Power Button
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: _togglePower,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _power ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: _power
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
                    color: _power ? Colors.white : const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _power ? 'TURN OFF' : 'TURN ON',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: _power ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Temperature controls
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
                    onTap: _power ? () => _changeTemperature(-1) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add,
                    label: 'UP',
                    onTap: _power ? () => _changeTemperature(1) : null,
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

  Widget _buildModeSelector() {
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
            final isSelected = _mode == mode;
            final isEnabled = _power;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: isEnabled ? () => _changeMode(mode) : null,
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
                          mode.name.toUpperCase(),
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

  Widget _buildFanSpeedSelector() {
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
            final isSelected = _fanSpeed == speed;
            final isEnabled = _power;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: isEnabled ? () => _changeFanSpeed(speed) : null,
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
                      speed.name.toUpperCase(),
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

  Widget _buildSleepTimerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SLEEP TIMER (AUTO TURN OFF)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            if (_sleepTargetTime != null)
              GestureDetector(
                onTap: _cancelSleepTimer,
                child: const Text(
                  'BATALKAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [1, 2, 3, 5, 8].map((hours) {
            final isSelected = _sleepTimerHours == hours;
            final isEnabled = _power;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: isEnabled
                      ? () {
                          if (isSelected) {
                            _cancelSleepTimer();
                          } else {
                            _setSleepTimer(hours);
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected && isEnabled
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected && isEnabled
                            ? const Color(0xFF2DD4BF)
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.nights_stay,
                          size: 18,
                          color: isEnabled
                              ? (isSelected ? Colors.white : Colors.tealAccent.shade100)
                              : Colors.white24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hours}H',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isEnabled
                                ? (isSelected ? Colors.white : Colors.white)
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

  Widget _buildExtraControls() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _power ? _toggleSwing : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _swing && _power ? const Color(0xFF0D9488) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_vert,
                    size: 20,
                    color: _power ? Colors.white : Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SWING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: _power ? Colors.white : Colors.white24,
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
            onTap: _power ? _sendSignal : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _power ? const Color(0xFF38BDF8) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    size: 18,
                    color: _power ? const Color(0xFF38BDF8) : Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RESEND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: _power ? const Color(0xFF38BDF8) : Colors.white24,
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
}
