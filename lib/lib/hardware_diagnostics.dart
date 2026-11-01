
class HardwareDiagnostics {
  HardwareDiagnostics._();

  static const Map<String, String> knownCharacteristics = {
    '2A29': 'Manufacturer Name',
    '2A24': 'Model Number',
    '2A25': 'Serial Number',
    '2A26': 'Firmware Revision',
    '2A27': 'Hardware Revision',
    '2A28': 'Software Revision',
    '2A19': 'Battery Level',
    '2A37': 'Heart Rate Measurement',
    '2A38': 'Body Sensor Location',
  };

  static String formatBytes(List<int> bytes) {
    if (bytes.isEmpty) return 'EMPTY';

    return bytes
        .map((value) =>
            value.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join('-');
  }

  static String decodeText(List<int> bytes) {
    if (bytes.isEmpty) return 'Not available';

    return String.fromCharCodes(
      bytes.where((value) => value >= 32 && value <= 126),
    ).trim();
  }

  static String identifyCharacteristic(String uuid) {
    final shortUuid = uuid
        .replaceAll('-', '')
        .toUpperCase();

    for (final entry in knownCharacteristics.entries) {
      if (shortUuid.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Unknown Characteristic';
  }

  static String interpretValue(String uuid, List<int> bytes) {
    final shortUuid = uuid
        .replaceAll('-', '')
        .toUpperCase();

    if (shortUuid.contains('2A19')) {
      if (bytes.isEmpty) return 'Battery data unavailable';

      final battery = bytes.first;

      if (battery > 100) return 'Invalid battery value';

      return '$battery%';
    }

    if (bytes.isEmpty) return 'No data';

    if (shortUuid.contains('2A29') ||
        shortUuid.contains('2A24') ||
        shortUuid.contains('2A26') ||
        shortUuid.contains('2A27') ||
        shortUuid.contains('2A28')) {
      final text = decodeText(bytes);
      return text.isEmpty ? formatBytes(bytes) : text;
    }

    return formatBytes(bytes);
  }

  static String hardwareLimitations() {
    return 'CPU model, RAM capacity, internal storage and bootloader '
        'cannot be confirmed through standard BLE information alone. '
        'The watch firmware must expose these details.';
  }
}
