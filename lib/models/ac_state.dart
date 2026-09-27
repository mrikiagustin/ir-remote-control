enum AcMode {
  cool,
  dry,
  fan,
  auto,
  heat;

  String get displayName => name.toUpperCase();
}

enum AcFanSpeed {
  auto,
  low,
  medium,
  high;

  String get displayName => name.toUpperCase();
}

enum AcBrand {
  sharpYb1fa('Sharp (YB1FA / Gree OEM)'),
  sharpA907('Sharp (CRMC-A907 / Standar)'),
  sharpA903('Sharp (CRMC-A903 / A820)'),
  sharpA705('Sharp (CRMC-A705)'),
  gree('Gree'),
  daikin('Daikin'),
  panasonic('Panasonic'),
  samsung('Samsung'),
  lg('LG');

  final String label;
  const AcBrand(this.label);
}

class AcState {
  final AcBrand brand;
  final bool power;
  final int temperature;
  final AcMode mode;
  final AcFanSpeed fanSpeed;
  final bool swing;

  const AcState({
    this.brand = AcBrand.sharpYb1fa,
    this.power = true,
    this.temperature = 24,
    this.mode = AcMode.cool,
    this.fanSpeed = AcFanSpeed.auto,
    this.swing = false,
  });

  AcState copyWith({
    AcBrand? brand,
    bool? power,
    int? temperature,
    AcMode? mode,
    AcFanSpeed? fanSpeed,
    bool? swing,
  }) {
    return AcState(
      brand: brand ?? this.brand,
      power: power ?? this.power,
      temperature: temperature ?? this.temperature,
      mode: mode ?? this.mode,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      swing: swing ?? this.swing,
    );
  }
}
