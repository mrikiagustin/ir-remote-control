import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_remote/models/ac_state.dart';
import 'package:mobile_remote/services/ac_protocol_helper.dart';

void main() {
  group('AcProtocolHelper Sharp & Gree Signals', () {
    test('buildGreeYb1faSignal produces valid pattern length and header', () {
      final pattern = AcProtocolHelper.buildGreeYb1faSignal(
        power: true,
        mode: AcMode.cool,
        temperature: 24,
        fanSpeed: AcFanSpeed.auto,
        swing: false,
      );

      // Gree YB1FA:
      // Header: 2 pulses (9000, 4500)
      // Block 1: 4 bytes = 32 bits = 64 pulses
      // Footer: 3 bits = 6 pulses
      // Inter-gap: 2 pulses (620, 19980)
      // Block 2: 4 bytes = 32 bits = 64 pulses
      // Final gap: 2 pulses (620, 19980)
      // Total: 2 + 64 + 6 + 2 + 64 + 2 = 140 entries
      expect(pattern.length, equals(140));
      expect(pattern[0], equals(9000));
      expect(pattern[1], equals(4500));
    });

    test('buildSharpStandardSignal produces valid pattern for A907', () {
      final pattern = AcProtocolHelper.generateAcSignal(
        brand: AcBrand.sharpA907,
        power: true,
        mode: AcMode.cool,
        temperature: 24,
        fanSpeed: AcFanSpeed.auto,
        swing: false,
      );

      // Sharp Standard:
      // Header: 2 pulses (3800, 1900)
      // 13 bytes = 104 bits = 208 pulses
      // Stop: 2 pulses (470, 10000)
      // Total: 2 + 208 + 2 = 212 entries
      expect(pattern.length, equals(212));
      expect(pattern[0], equals(3800));
      expect(pattern[1], equals(1900));
    });

    test('generateAcSignal handles all Sharp variants without error', () {
      for (final brand in [
        AcBrand.sharpYb1fa,
        AcBrand.sharpA907,
        AcBrand.sharpA903,
        AcBrand.sharpA705,
      ]) {
        final pattern = AcProtocolHelper.generateAcSignal(
          brand: brand,
          power: true,
          mode: AcMode.cool,
          temperature: 24,
          fanSpeed: AcFanSpeed.auto,
          swing: false,
        );
        expect(pattern.isNotEmpty, isTrue);
      }
    });
  });
}
