import '../models/ac_state.dart';

enum SharpModelVariant {
  a907,
  a903,
  a705,
}

class AcProtocolHelper {
  static const int defaultFrequency = 38000;

  /// Protokol Gree YB1FA / YBOFB / YAW1F (8 byte / 67-bit)
  /// Header: 9000us MARK, 4500us SPACE
  /// Bit 0: 620us MARK, 540us SPACE
  /// Bit 1: 620us MARK, 1600us SPACE
  /// Mid-message Footer: bit 0b010 (3 bit) + 19980us SPACE
  /// Block 2 (32-bit): Data + 620us MARK + 19980us SPACE
  static List<int> buildGreeYb1faSignal({
    required bool power,
    required AcMode mode,
    required int temperature,
    required AcFanSpeed fanSpeed,
    required bool swing,
  }) {
    final List<int> state = List.filled(8, 0);

    // Byte 0: Mode (3 bit), Power (1 bit), Fan (2 bit), SwingAuto (1 bit), Sleep (1 bit)
    int modeVal;
    switch (mode) {
      case AcMode.auto:
        modeVal = 0; // kGreeAuto
        break;
      case AcMode.cool:
        modeVal = 1; // kGreeCool
        break;
      case AcMode.dry:
        modeVal = 2; // kGreeDry
        break;
      case AcMode.fan:
        modeVal = 3; // kGreeFan
        break;
      case AcMode.heat:
        modeVal = 4; // kGreeHeat
        break;
    }

    int fanVal;
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

    final int powerBit = power ? 1 : 0;
    final int swingBit = swing ? 1 : 0;
    state[0] = (modeVal & 0x07) |
        (powerBit << 3) |
        ((fanVal & 0x03) << 4) |
        (swingBit << 6);

    // Byte 1: Temp (4 bit), Timer bits
    final int tempC = temperature.clamp(16, 30);
    final int tempVal = tempC - 16;
    state[1] = tempVal & 0x0F;

    // Byte 2: Timer hours, Turbo, Light (bit 5 = 1)
    state[2] = 0x20; // Light ON default on Gree YB1FA

    // Byte 3: unknown1 = 0b0101 (high nibble = 0x50)
    state[3] = 0x50;

    // Byte 4: Swing vertical/horizontal
    state[4] = swing ? 0x01 : 0x00;

    // Byte 5: unknown2 = 0b100 (bits 3..5 = 0x20)
    state[5] = 0x20;

    // Byte 6: 0x00
    state[6] = 0x00;

    // Byte 7: Checksum (Kelvinator block checksum)
    // sum = 10 + sum(low 4 bits of bytes 0..3) + sum(high 4 bits of bytes 4..6)
    int sum = 10;
    for (int i = 0; i < 4; i++) {
      sum += state[i] & 0x0F;
    }
    for (int i = 4; i < 7; i++) {
      sum += (state[i] >> 4) & 0x0F;
    }
    final int checksum = sum & 0x0F;
    state[7] = (checksum << 4) & 0xF0;

    // Encode ke timing Gree YB1FA
    final List<int> pattern = [];

    // Header
    pattern.add(9000);
    pattern.add(4500);

    // Block #1: 4 bytes (32 bits, LSB first per byte)
    for (int b = 0; b < 4; b++) {
      final byte = state[b];
      for (int i = 0; i < 8; i++) {
        final bit = (byte >> i) & 1;
        pattern.add(620);
        pattern.add(bit == 1 ? 1600 : 540);
      }
    }

    // Mid-block footer: 3 bits 0b010 (LSB first: 0, 1, 0)
    const int footer = 2; // 0b010
    for (int i = 0; i < 3; i++) {
      final bit = (footer >> i) & 1;
      pattern.add(620);
      pattern.add(bit == 1 ? 1600 : 540);
    }

    // Inter-message gap
    pattern.add(620);
    pattern.add(19980);

    // Block #2: 4 bytes (bytes 4..7)
    for (int b = 4; b < 8; b++) {
      final byte = state[b];
      for (int i = 0; i < 8; i++) {
        final bit = (byte >> i) & 1;
        pattern.add(620);
        pattern.add(bit == 1 ? 1600 : 540);
      }
    }

    // Final mark & trailing gap
    pattern.add(620);
    pattern.add(19980);

    return pattern;
  }

  /// Protokol Sharp AC Asli (13 Byte / 104-bit, CRMC-A907 / A903 / A705)
  /// Header: 3800us MARK, 1900us SPACE
  /// Bit 0: 470us MARK, 500us SPACE
  /// Bit 1: 470us MARK, 1400us SPACE
  /// Stop mark: 470us MARK
  static List<int> buildSharpStandardSignal({
    required bool power,
    required AcMode mode,
    required int temperature,
    required AcFanSpeed fanSpeed,
    required bool swing,
    required SharpModelVariant variant,
  }) {
    final List<int> raw = List.filled(13, 0);

    // Header signature Sharp AC
    raw[0] = 0xAA;
    raw[1] = 0x5A;
    raw[2] = 0xCF;
    raw[3] = 0x10;

    // Byte 4: Temp (bits 0..3), Model (bit 4), bits 5..7
    final int tempClamped = temperature.clamp(15, 30);
    final int tempVal = tempClamped - 15;

    int byte4 = 0xC0; // default for A907 / A903
    if (variant == SharpModelVariant.a705) {
      byte4 = 0xD0;
    }
    if (mode == AcMode.auto || mode == AcMode.dry) {
      byte4 = 0x00;
    } else {
      byte4 = (byte4 & 0xF0) | (tempVal & 0x0F);
    }
    if (variant == SharpModelVariant.a705 || variant == SharpModelVariant.a903) {
      byte4 |= 0x10; // Model bit = 1
    }
    raw[4] = byte4;

    // Byte 5: PowerSpecial (bits 4..7)
    // kSharpAcPowerOff = 2 (0b0010), kSharpAcPowerOn = 3 (0b0011)
    final int powerSpecial = power ? 0x03 : 0x02;
    raw[5] = (powerSpecial << 4) | 0x01; // default low nibble is 1 in stateReset

    // Byte 6: Mode (bits 0..1), Clean (bit 3), Fan (bits 4..6)
    // Modes: Auto=0x00, Heat=0x01, Cool=0x02, Dry=0x03
    int modeVal;
    switch (mode) {
      case AcMode.auto:
        modeVal = (variant == SharpModelVariant.a705) ? 0x00 : 0x00;
        break;
      case AcMode.heat:
        modeVal = 0x01;
        break;
      case AcMode.cool:
        modeVal = 0x02;
        break;
      case AcMode.dry:
        modeVal = 0x03;
        break;
      case AcMode.fan:
        modeVal = (variant == SharpModelVariant.a705) ? 0x00 : 0x02;
        break;
    }

    int fanVal;
    switch (fanSpeed) {
      case AcFanSpeed.auto:
        fanVal = 0x02; // 2
        break;
      case AcFanSpeed.low:
        fanVal = (variant == SharpModelVariant.a705 || variant == SharpModelVariant.a903) ? 0x03 : 0x04;
        break;
      case AcFanSpeed.medium:
        fanVal = (variant == SharpModelVariant.a705 || variant == SharpModelVariant.a903) ? 0x05 : 0x03;
        break;
      case AcFanSpeed.high:
        fanVal = 0x05;
        break;
    }
    if (mode == AcMode.dry || mode == AcMode.auto) {
      fanVal = 0x02; // Dry/Auto forces Auto Fan
    }

    raw[6] = (modeVal & 0x03) | ((fanVal & 0x07) << 4);

    // Byte 7: Timer settings (0 for no timer)
    raw[7] = 0x00;

    // Byte 8: Swing (bits 0..2)
    // Swing toggle = 0x07, off = 0x02
    final int swingVal = swing ? 0x07 : 0x02;
    raw[8] = (swingVal & 0x07) | 0x08; // default bit 3 = 1

    // Byte 9: fixed 0x80
    raw[9] = 0x80;

    // Byte 10: Special command byte (0x00 = Power, 0x04 = Temp/Econo, 0x05 = Fan, 0x06 = Swing)
    raw[10] = 0x00;

    // Byte 11: Ion / Model2
    // default 0xE0, Model2 is bit 4
    int byte11 = 0xE0;
    if (variant != SharpModelVariant.a907) {
      byte11 |= 0x10; // Model2 = 1
    }
    raw[11] = byte11;

    // Byte 12: Checksum (calcChecksum in IRSharpAc)
    // xorsum = XOR(bytes 0..11)
    // xorsum ^= (raw[12] & 0x0F) -> 0x01
    // xorsum ^= (xorsum >> 4)
    // checksum = xorsum & 0x0F
    // raw[12] = (checksum << 4) | 0x01
    raw[12] = 0x01; // default low nibble
    int xorsum = 0;
    for (int i = 0; i < 12; i++) {
      xorsum ^= raw[i];
    }
    xorsum ^= (raw[12] & 0x0F);
    xorsum ^= (xorsum >> 4) & 0x0F;
    final int checksum = xorsum & 0x0F;
    raw[12] = (checksum << 4) | 0x01;

    // Encode ke timing Sharp
    final List<int> pattern = [];
    pattern.add(3800);
    pattern.add(1900);

    for (final byte in raw) {
      for (int i = 0; i < 8; i++) {
        final bit = (byte >> i) & 1;
        pattern.add(470);
        pattern.add(bit == 1 ? 1400 : 500);
      }
    }

    // Stop mark & gap
    pattern.add(470);
    pattern.add(10000);

    return pattern;
  }

  /// Konversi raw bytes menjadi NEC timing pattern (microsecond)
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
        pattern.add(560);
        pattern.add(bit == 1 ? 1690 : 560);
      }
    }

    // Stop bit
    pattern.add(560);
    pattern.add(10000);

    return pattern;
  }

  /// Membuat payload byte untuk profil Gree AC generic
  static List<int> buildGreePayload({
    required bool power,
    required AcMode mode,
    required int temperature,
    required AcFanSpeed fanSpeed,
    required bool swing,
  }) {
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

    final tempVal = (temperature.clamp(16, 30) - 16) & 0x0F;
    final powerVal = power ? 1 : 0;

    final b0 = (modeVal & 0x07) | ((powerVal & 0x01) << 3) | ((fanVal & 0x03) << 4) | ((swing ? 1 : 0) << 6);
    final b1 = tempVal & 0x0F;
    final b2 = 0x20;
    final b3 = (b0 + b1 + b2) & 0xFF;

    return [b0, b1, b2, b3];
  }

  static List<int> generateAcSignal({
    required AcBrand brand,
    required bool power,
    required AcMode mode,
    required int temperature,
    required AcFanSpeed fanSpeed,
    required bool swing,
  }) {
    switch (brand) {
      case AcBrand.sharpYb1fa:
      case AcBrand.gree:
        return buildGreeYb1faSignal(
          power: power,
          mode: mode,
          temperature: temperature,
          fanSpeed: fanSpeed,
          swing: swing,
        );

      case AcBrand.sharpA907:
        return buildSharpStandardSignal(
          power: power,
          mode: mode,
          temperature: temperature,
          fanSpeed: fanSpeed,
          swing: swing,
          variant: SharpModelVariant.a907,
        );

      case AcBrand.sharpA903:
        return buildSharpStandardSignal(
          power: power,
          mode: mode,
          temperature: temperature,
          fanSpeed: fanSpeed,
          swing: swing,
          variant: SharpModelVariant.a903,
        );

      case AcBrand.sharpA705:
        return buildSharpStandardSignal(
          power: power,
          mode: mode,
          temperature: temperature,
          fanSpeed: fanSpeed,
          swing: swing,
          variant: SharpModelVariant.a705,
        );

      case AcBrand.daikin:
      case AcBrand.panasonic:
      case AcBrand.samsung:
      case AcBrand.lg:
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
}
