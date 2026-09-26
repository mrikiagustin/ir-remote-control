enum AcMode { cool, dry, fan, auto, heat }
enum AcFanSpeed { auto, low, medium, high }

class AcProtocolHelper {
  // Standar NEC: 38kHz
  static const int defaultFrequency = 38000;

  /// Konversi raw bytes menjadi NEC timing pattern (microsecond)
  /// Format NEC: 
  /// Header: 9000us MARK, 4500us SPACE
  /// Bit 0: 560us MARK, 560us SPACE
  /// Bit 1: 560us MARK, 1690us SPACE
  /// Stop bit: 560us MARK
  static List<int> necEncodeBytes(List<int> bytes) {
    final List<int> pattern = [];

    // Header
    pattern.add(9000);
    pattern.add(4500);

    for (final byte in bytes) {
      for (int i = 0; i < 8; i++) {
        final bit = (byte >> i) & 1;
        pattern.add(560); // Mark
        if (bit == 1) {
          pattern.add(1690); // Space for 1
        } else {
          pattern.add(560); // Space for 0
        }
      }
    }

    // Stop bit
    pattern.add(560);
    pattern.add(10000); // Trailing quiet space

    return pattern;
  }

  /// Membuat payload byte untuk profil Gree AC (standard YAA/YB protocol NEC variant)
  static List<int> buildGreePayload({
    required bool power,
    required AcMode mode,
    required int temperature,
    required AcFanSpeed fanSpeed,
    required bool swing,
  }) {
    // Mode mapping: Auto=0, Cool=1, Dry=2, Fan=3, Heat=4
    int modeVal = 1;
    switch (mode) {
      case AcMode.auto:
        modeVal = 0;
        break;
      case AcMode.cool:
        modeVal = 1;
        break;
      case AcMode.dry:
        modeVal = 2;
        break;
      case AcMode.fan:
        modeVal = 3;
        break;
      case AcMode.heat:
        modeVal = 4;
        break;
    }

    // Fan mapping: Auto=0, Low=1, Med=2, High=3
    int fanVal = 0;
    switch (fanSpeed) {
      case AcFanSpeed.auto:
        fanVal = 0;
        break;
      case AcFanSpeed.low:
        fanVal = 1;
        break;
      case AcFanSpeed.medium:
        fanVal = 2;
        break;
      case AcFanSpeed.high:
        fanVal = 3;
        break;
    }

    int tempVal = (temperature.clamp(16, 30) - 16) & 0x0F;
    int powerVal = power ? 1 : 0;

    // Byte 0: mode (3 bits), power (1 bit), fan (2 bits), swing (1 bit), sleep (1 bit)
    int b0 = (modeVal & 0x07) | ((powerVal & 0x01) << 3) | ((fanVal & 0x03) << 4) | ((swing ? 1 : 0) << 6);
    // Byte 1: temp (4 bits)
    int b1 = tempVal & 0x0F;
    // Byte 2: timer / extra options
    int b2 = 0x20;
    // Byte 3: checksum or identifier
    int b3 = (b0 + b1 + b2) & 0xFF;

    return [b0, b1, b2, b3];
  }

  /// Format protokol universal AC untuk demo/standar (Samsung/Panasonic/LG/Gree generic)
  static List<int> generateAcSignal({
    required String brand,
    required bool power,
    required AcMode mode,
    required int temperature,
    required AcFanSpeed fanSpeed,
    required bool swing,
  }) {
    final payload = buildGreePayload(
      power: power,
      mode: mode,
      temperature: temperature,
      fanSpeed: fanSpeed,
      swing: swing,
    );
    return necEncodeBytes(payload);
  }
}
