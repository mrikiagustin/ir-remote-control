import 'package:flutter/services.dart';

class IrService {
  static const MethodChannel _channel = MethodChannel('com.example.mobile_remote/ir');
  static const EventChannel _eventChannel = EventChannel('com.example.mobile_remote/events');

  static Stream<dynamic>? _eventStream;

  static Stream<dynamic> get eventStream {
    _eventStream ??= _eventChannel.receiveBroadcastStream();
    return _eventStream!;
  }

  static Future<bool> hasIrEmitter() async {
    try {
      final bool hasIr = await _channel.invokeMethod('hasIrEmitter');
      return hasIr;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> transmit({
    required int frequency,
    required List<int> pattern,
  }) async {
    try {
      final bool success = await _channel.invokeMethod('transmit', {
        'frequency': frequency,
        'pattern': pattern,
      });
      return success;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Gagal mengirim sinyal IR');
    }
  }

  static Future<bool> scheduleSleepTimer({
    required int delaySeconds,
    required int frequency,
    required List<int> pattern,
  }) async {
    try {
      final bool success = await _channel.invokeMethod('scheduleSleepTimer', {
        'delaySeconds': delaySeconds,
        'frequency': frequency,
        'pattern': pattern,
      });
      return success;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Gagal menjadwalkan sleep timer');
    }
  }

  static Future<bool> cancelSleepTimer() async {
    try {
      final bool success = await _channel.invokeMethod('cancelSleepTimer');
      return success;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Gagal membatalkan timer');
    }
  }
}
