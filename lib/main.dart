import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Diagnostics.install();
  runApp(const DNWatchOS());
}

class Diagnostics {
  static final List<String> logs = [];

  static void add(String title, String details) {
    logs.insert(0, '${DateTime.now()}\n$title\n$details');
    if (logs.length > 50) logs.removeLast();
  }

  static void install() {
    FlutterError.onError = (details) {
      add('FLUTTER ERROR', details.exceptionAsString());
      FlutterError.presentError(details);
    };

    ui.PlatformDispatcher.instance.onError = (error, stack) {
      add('SYSTEM ERROR', '$error\n$stack');
      return true;
    };

    add('SYSTEM ONLINE', 'Error monitoring active.');
  }
}

class DNWatchOS extends StatelessWidget {
  const DNWatchOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DN WATCH OS',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050B12),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.cyanAccent,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF081522),
          indicatorColor: Color(0x3333FFFF),
        ),
      ),
      home: const WatchHome(),
    );
  }
}

class WatchHome extends StatefulWidget {
  const WatchHome({super.key});

  @override
  State<WatchHome> createState() => _WatchHomeState();
}

class _WatchHomeState extends State<WatchHome> {
  final Color cyan = Colors.cyanAccent;

  int selectedIndex = 0;
  bool safetyShield = true;
  bool scanning = false;
  bool connecting = false;
  bool connected = false;
  bool readingInfo = false;

  List<ScanResult> devices = [];
  List<BluetoothService> discoveredServices = [];

  BluetoothDevice? connectedDevice;

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<bool>? scanningSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;

  final Map<String, String> readValues = {};

  // JARVIS VOICE CORE

  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  bool speechAvailable = false;
  bool isListening = false;
  String heardText = '';
  String jarvisReply = 'Hello Sir. JARVIS voice system is ready.';

  @override
  void initState() {
    super.initState();
    initializeVoice();

    scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (!mounted) return;
        setState(() => devices = results);
      },
      onError: (error) {
        Diagnostics.add('BLE SCAN ERROR', '$error');
      },
    );

    scanningSubscription = FlutterBluePlus.isScanning.listen((value) {
      if (mounted) setState(() => scanning = value);
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    scanningSubscription?.cancel();
    connectionSubscription?.cancel();
    FlutterBluePlus.stopScan();
    speech.stop();
    tts.stop();
    super.dispose();
  }

  // JARVIS VOICE FUNCTIONS

  Future<void> initializeVoice() async {
    try {
      speechAvailable = await speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            isListening = status == 'listening';
          });
        },
        onError: (error) {
          Diagnostics.add('SPEECH ERROR', error.errorMsg);
          if (mounted) {
            setState(() => isListening = false);
            showMessage('Voice recognition error.');
          }
        },
      );

      await tts.setLanguage('hi-IN');
      await tts.setSpeechRate(0.45);
      await tts.setPitch(1.0);

      if (mounted) setState(() {});
    } catch (e) {
      Diagnostics.add('VOICE INIT ERROR', '$e');
    }
  }

  Future<void> speak(String message) async {
    try {
      if (mounted) {
        setState(() {
          jarvisReply = message;
          isListening = false;
        });
      }

      await speech.stop();
      await tts.stop();
      await tts.speak(message);
    } catch (e) {
      Diagnostics.add('TTS ERROR', '$e');
    }
  }

  Future<void> startJarvisListening() async {
    try {
      final permission = await Permission.microphone.request();

      if (!permission.isGranted) {
        showMessage('Microphone permission required.');
        return;
      }

      if (!speechAvailable) {
        await initializeVoice();
      }

      if (!speechAvailable) {
        showMessage('Speech recognition is not available on this phone.');
        return;
      }

      await tts.stop();

      setState(() {
        heardText = '';
        isListening = true;
      });

      await speech.listen(
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            heardText = result.recognizedWords;
          });

          if (result.finalResult) {
            handleJarvisCommand(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
      );
    } catch (e) {
      Diagnostics.add('LISTEN ERROR', '$e');
      if (mounted) setState(() => isListening = false);
      showMessage('Could not start microphone.');
    }
  }

  Future<void> handleJarvisCommand(String command) async {
    final text = command.toLowerCase().trim();

    if (text.isEmpty) {
      await speak('Sir, I did not hear anything.');
      return;
    }

    if (text.contains('hello') ||
        text.contains('नमस्ते') ||
        text.contains('namaste') ||
        text.contains('jarvis')) {
      await speak('Hello Sir. JARVIS is online. How can I help you?');
    } else if (text.contains('time') ||
        text.contains('समय') ||
        text.contains('samay') ||
        text.contains('टाइम')) {
      final now = DateTime.now();
      final minute = now.minute.toString().padLeft(2, '0');
      await speak('Sir, the time is ${now.hour}:$minute.');
    } else if (text.contains('date') ||
        text.contains('तारीख') ||
        text.contains('tarikh') ||
        text.contains('आज की तारीख')) {
      final now = DateTime.now();
      await speak('Today is ${now.day}, ${now.month}, ${now.year}.');
    } else if (text.contains('home') ||
        text.contains('होम') ||
        text.contains('ghar')) {
      setState(() => selectedIndex = 0);
      await speak('Opening home screen, Sir.');
    } else if (text.contains('watch') ||
        text.contains('घड़ी') ||
        text.contains('ghadi')) {
      setState(() => selectedIndex = 1);
      await speak('Opening watch control, Sir.');
    } else if (text.contains('tool') || text.contains('टूल')) {
      setState(() => selectedIndex = 4);
      await speak('Opening security tools, Sir.');
    } else if (text.contains('stop') ||
        text.contains('बंद') ||
        text.contains('रुको')) {
      await stopJarvisListening();
      await speak('Voice recognition stopped, Sir.');
    } else if (text.contains('help') || text.contains('मदद')) {
      await speak(
        'You can ask me for the time, date, home, watch or tools.',
      );
    } else {
      await speak('Sorry Sir. This command is not available yet.');
    }
  }

  Future<void> stopJarvisListening() async {
    await speech.stop();
    if (mounted) setState(() => isListening = false);
  }

  // COMMON UI

  Widget panel(String title, Widget child, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF101C29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cyan.withOpacity(.4)),
        boxShadow: [
          BoxShadow(color: cyan.withOpacity(.06), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: cyan),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget statusRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: cyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: cyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget outlineButton(String label, IconData icon, VoidCallback? action) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: action,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: cyan,
          side: BorderSide(color: cyan, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF15283A),
      ),
    );
  }
    // ==========================================
  // BLUETOOTH PERMISSIONS
  // ==========================================

  Future<bool> requestBluetoothPermissions() async {
    try {
      final permissions = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final granted = permissions.values.every(
        (status) => status.isGranted,
      );

      if (!granted) {
        showMessage('Bluetooth permissions are required.');
      }

      return granted;
    } catch (e) {
      showMessage('Permission error: $e');
      return false;
    }
  }

  // ==========================================
  // BLE SCANNER
  // ==========================================

  Future<void> startBleScan() async {
    if (scanning) return;

    final permissionGranted = await requestBluetoothPermissions();
    if (!permissionGranted) return;

    try {
      setState(() {
        scanning = true;
        devices.clear();
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 12),
      );

      FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;

        setState(() {
          for (final result in results) {
            final device = result.device;

            final exists = devices.any(
              (item) => item.remoteId == device.remoteId,
            );

            if (!exists) {
              devices.add(device);
            }
          }
        });
      });

      await Future.delayed(const Duration(seconds: 12));

      if (!mounted) return;

      setState(() {
        scanning = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        scanning = false;
      });

      showMessage('Bluetooth scan failed: $e');
    }
  }

  Future<void> stopBleScan() async {
    try {
      await FlutterBluePlus.stopScan();

      if (!mounted) return;

      setState(() {
        scanning = false;
      });
    } catch (e) {
      showMessage('Unable to stop scan: $e');
    }
  }

  // ==========================================
  // CONNECT WATCH
  // ==========================================

  Future<void> connectDevice(BluetoothDevice device) async {
    if (connecting) return;

    setState(() {
      connecting = true;
    });

    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      connectedDevice = device;

      final services = await device.discoverServices();

      if (!mounted) return;

      setState(() {
        connected = true;
        connecting = false;
        discoveredServices = services;
        readValues.clear();
      });

      showMessage('Watch connected successfully.');

      await readSafeInformation();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        connecting = false;
        connected = false;
      });

      showMessage('Connection failed: $e');
    }
  }

  // ==========================================
  // DISCONNECT WATCH
  // ==========================================

  Future<void> disconnectWatch() async {
    try {
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
      }

      if (!mounted) return;

      setState(() {
        connected = false;
        connecting = false;
        readingInfo = false;
        connectedDevice = null;
        discoveredServices.clear();
        readValues.clear();
      });

      showMessage('Watch disconnected.');
    } catch (e) {
      showMessage('Disconnect error: $e');
    }
  }

  // ==========================================
  // BLE DATA HELPERS
  // ==========================================

  String bytesToHex(List<int> bytes) {
    return bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join('-')
        .toUpperCase();
  }

  String decodeText(List<int> bytes) {
    try {
      return String.fromCharCodes(bytes)
          .replaceAll(RegExp(r'[\x00-\x1F]'), '')
          .trim();
    } catch (_) {
      return '';
    }
  }

  String characteristicName(Guid uuid) {
    final value = uuid.str.toUpperCase();

    switch (value) {
      case '00002A29-0000-1000-8000-00805F9B34FB':
        return 'Manufacturer Name';
      case '00002A24-0000-1000-8000-00805F9B34FB':
        return 'Model Number';
      case '00002A26-0000-1000-8000-00805F9B34FB':
        return 'Firmware Revision';
      case '00002A27-0000-1000-8000-00805F9B34FB':
        return 'Hardware Revision';
      case '00002A28-0000-1000-8000-00805F9B34FB':
        return 'Software Revision';
      case '00002A25-0000-1000-8000-00805F9B34FB':
        return 'Serial Number';
      default:
        return 'BLE Characteristic';
    }
  }

  String interpretValue(List<int> value) {
    if (value.isEmpty) return 'EMPTY';

    final text = decodeText(value);

    if (text.isNotEmpty &&
        text.runes.every((rune) => rune >= 32 && rune <= 126)) {
      return text;
    }

    return bytesToHex(value);
  }

  // ==========================================
  // SAFE INFORMATION READER
  // READ ONLY - NO UNKNOWN BLE COMMANDS
  // ==========================================

  Future<void> readSafeInformation() async {
    if (!connected || connectedDevice == null) {
      showMessage('Connect your watch first.');
      return;
    }

    if (readingInfo) return;

    setState(() {
      readingInfo = true;
      readValues.clear();
    });

    try {
      for (final service in discoveredServices) {
        for (final characteristic in service.characteristics) {
          if (!characteristic.properties.read) continue;

          try {
            final value = await characteristic.read();

            if (value.isNotEmpty) {
              final label = characteristicName(
                characteristic.uuid,
              );

              final serviceId = service.uuid.str;
              final characteristicId = characteristic.uuid.str;

              readValues[
                '$label | $serviceId | $characteristicId'
              ] = interpretValue(value);
            }
          } catch (e) {
            debugPrint('Read skipped: $e');
          }
        }
      }

      if (!mounted) return;

      showMessage('Safe device information scan completed.');
    } catch (e) {
      showMessage('Information scan error: $e');
    } finally {
      if (mounted) {
        setState(() {
          readingInfo = false;
        });
      }
    }
  }

  // ==========================================
  // FIRMWARE FINGERPRINT SCANNER
  // READ ONLY ANALYSIS
  // ==========================================

  Widget firmwareFingerprintPanel() {
    String findValue(String label) {
      for (final entry in readValues.entries) {
        if (entry.key.toLowerCase().startsWith(
              label.toLowerCase(),
            )) {
          return entry.value;
        }
      }

      return 'NOT DETECTED';
    }

    final manufacturer = findValue('Manufacturer Name');
    final model = findValue('Model Number');
    final firmware = findValue('Firmware Revision');
    final hardware = findValue('Hardware Revision');
    final software = findValue('Software Revision');

    final feeaServices = discoveredServices.where(
      (service) => service.uuid.str
          .toUpperCase()
          .replaceAll('-', '')
          .contains('FEEA'),
    ).toList();

    final characteristics = feeaServices
        .expand((service) => service.characteristics)
        .toList();

    final feeaFound = feeaServices.isNotEmpty;

    final canRead = characteristics.any(
      (characteristic) => characteristic.properties.read,
    );

    final canWrite = characteristics.any(
      (characteristic) =>
          characteristic.properties.write ||
          characteristic.properties.writeWithoutResponse,
    );

    final canNotify = characteristics.any(
      (characteristic) =>
          characteristic.properties.notify ||
          characteristic.properties.indicate,
    );

    final platform = (
      manufacturer.toUpperCase().contains('MOYOUNG') ||
      firmware.toUpperCase().contains('MOY') ||
      software.toUpperCase().contains('MOY')
    )
        ? 'MOYOUNG FAMILY INDICATOR'
        : 'NOT CONFIRMED';

    final compatibility = !connected
        ? 'CONNECT WATCH FIRST'
        : !feeaFound
            ? 'FEEA SERVICE NOT FOUND'
            : 'BLE PROTOCOL FOUND - APP SUPPORT UNKNOWN';

    Widget resultRow(String title, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget capabilityRow(String title, bool available) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              available ? Icons.check_circle : Icons.cancel,
              size: 17,
              color: available ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              available ? 'AVAILABLE' : 'NOT FOUND',
              style: TextStyle(
                color: available ? Colors.greenAccent : Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return panel(
      'FIRMWARE FINGERPRINT SCANNER',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.memory,
            color: Colors.cyanAccent,
            size: 35,
          ),
          const SizedBox(height: 12),

          const Text(
            'DEVICE IDENTITY',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          resultRow('Manufacturer', manufacturer),
          resultRow('Model', model),
          resultRow('Firmware', firmware),
          resultRow('Hardware', hardware),
          resultRow('Software', software),

          const Divider(color: Colors.white12, height: 25),

          const Text(
            'PLATFORM ANALYSIS',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),

          resultRow('Platform indicator', platform),
          resultRow('FEEA service', feeaFound ? 'DETECTED' : 'NOT FOUND'),
          resultRow('Compatibility', compatibility),

          const Divider(color: Colors.white12, height: 25),

          const Text(
            'BLE CAPABILITIES',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          capabilityRow('Read capability', canRead),
          capabilityRow('Write capability', canWrite),
          capabilityRow('Notify / Indicate', canNotify),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              border: Border.all(
                color: Colors.orangeAccent.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'SAFETY NOTICE\n'
              'This scanner only reads available device information. '
              'BLE capabilities do not confirm third-party app support, '
              'watch CPU, RAM, operating system, or standalone AI support. '
              'No unknown commands or firmware changes are performed.',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: outlineButton(
              readingInfo ? 'SCANNING...' : 'SCAN DEVICE AGAIN',
              readingInfo ? null : readSafeInformation,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BLE DEVICE CARD
  // ==========================================

  Widget deviceCard(BluetoothDevice device) {
    final name = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown BLE Device';

    final isThisDevice =
        connectedDevice?.remoteId == device.remoteId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF101D2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isThisDevice
              ? Colors.cyanAccent
              : Colors.white24,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.watch,
            color: Colors.cyanAccent,
            size: 28,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.remoteId.str,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 100,
            child: outlineButton(
              isThisDevice
                  ? 'CONNECTED'
                  : connecting
                      ? 'WAIT...'
                      : 'CONNECT',
              isThisDevice || connecting
                  ? null
                  : () => connectDevice(device),
            ),
          ),
        ],
      ),
    );
  }
    // ==========================================
  // HOME PAGE
  // ==========================================

  Widget homePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          panel(
            'DN WATCH OS',
            Column(
              children: [
                const Icon(
                  Icons.watch_rounded,
                  color: Colors.cyanAccent,
                  size: 75,
                ),
                const SizedBox(height: 12),
                const Text(
                  'WELCOME TO DN WATCH OS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Smartwatch Companion',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      connected ? Icons.bluetooth_connected : Icons.bluetooth,
                      color: connected
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connected ? 'WATCH CONNECTED' : 'WATCH DISCONNECTED',
                      style: TextStyle(
                        color: connected
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          panel(
            'QUICK ACTIONS',
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: outlineButton(
                    'CONNECT YOUR WATCH',
                    () {
                      setState(() {
                        selectedIndex = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: outlineButton(
                    'OPEN JARVIS ASSISTANT',
                    () {
                      setState(() {
                        selectedIndex = 2;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: outlineButton(
                    'OPEN DEVICE TOOLS',
                    () {
                      setState(() {
                        selectedIndex = 4;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          panel(
            'SYSTEM STATUS',
            Column(
              children: [
                statusRow(
                  'Bluetooth',
                  connected ? 'Connected' : 'Disconnected',
                ),
                statusRow(
                  'Nearby Devices',
                  '${devices.length}',
                ),
                statusRow(
                  'Services Found',
                  '${discoveredServices.length}',
                ),
                statusRow(
                  'Read Values',
                  '${readValues.length}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WATCH PAGE
  // ==========================================

  Widget watchPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          panel(
            'WATCH CONNECTION',
            Column(
              children: [
                Icon(
                  connected
                      ? Icons.watch
                      : Icons.watch_outlined,
                  size: 55,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 10),
                Text(
                  connected
                      ? 'WATCH CONNECTED'
                      : 'NO WATCH CONNECTED',
                  style: TextStyle(
                    color: connected
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (connectedDevice != null)
                  Text(
                    connectedDevice!.platformName.isNotEmpty
                        ? connectedDevice!.platformName
                        : connectedDevice!.remoteId.str,
                    style: const TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: outlineButton(
                    connected ? 'DISCONNECT WATCH' : 'SCAN FOR WATCH',
                    connected ? disconnectWatch : startBleScan,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          panel(
            'NEARBY BLE DEVICES',
            Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Available Bluetooth devices',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    if (scanning)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.cyanAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (devices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(15),
                    child: Text(
                      'No devices found. Start scanning.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ...devices.map((device) => deviceCard(device)),
                if (scanning)
                  SizedBox(
                    width: double.infinity,
                    child: outlineButton(
                      'STOP SCANNING',
                      stopBleScan,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          panel(
            'DISCOVERED SERVICES',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!connected)
                  const Text(
                    'Connect your watch to discover BLE services.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ...discoveredServices.map((service) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101D2B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SERVICE: ${service.uuid.str}',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...service.characteristics.map((characteristic) {
                          final properties = characteristic.properties;
                          final features = <String>[];

                          if (properties.read) features.add('READ');
                          if (properties.write) features.add('WRITE');
                          if (properties.writeWithoutResponse) {
                            features.add('WRITE NO RESPONSE');
                          }
                          if (properties.notify) features.add('NOTIFY');
                          if (properties.indicate) features.add('INDICATE');

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              '${characteristic.uuid.str}\n'
                              '${features.isEmpty ? "NO PROPERTIES" : features.join(" • ")}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                height: 1.5,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          firmwareFingerprintPanel(),

          const SizedBox(height: 16),

          panel(
            'READ DEVICE DATA',
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: outlineButton(
                    readingInfo ? 'READING...' : 'READ SAFE INFORMATION',
                    readingInfo ? null : readSafeInformation,
                  ),
                ),
                const SizedBox(height: 12),
                if (readValues.isEmpty)
                  const Text(
                    'No readable information available.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ...readValues.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const Divider(color: Colors.white12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          panel(
            'DEVICE SAFETY',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Colors.greenAccent,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'READ-ONLY DEVICE INSPECTION',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DN WATCH OS does not send unknown commands '
                  'or flash firmware to your smartwatch.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // JARVIS PAGE
  // ==========================================

  Widget jarvisPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          panel(
            'J.A.R.V.I.S. ASSISTANT',
            Column(
              children: [
                const Icon(
                  Icons.graphic_eq,
                  size: 85,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 15),
                const Text(
                  'J.A.R.V.I.S.',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'YOUR SMART WATCH COMPANION',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Use the voice assistant controls configured '
                  'in this application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Try commands: Hello Jarvis, Time, Date, '
                  'Home, Watch, Tools, Help, Stop.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STUDIO PAGE
  // ==========================================

  Widget studioPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          panel(
            'WATCH STUDIO',
            Column(
              children: [
                const Icon(
                  Icons.dashboard_customize,
                  color: Colors.cyanAccent,
                  size: 55,
                ),
                const SizedBox(height: 12),
                const Text(
                  'PERSONALIZE YOUR WATCH EXPERIENCE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This section is ready for future watch-face '
                  'and customization features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIAGNOSTICS PANEL
  // ==========================================

  Widget diagnosticsPanel() {
    return panel(
      'SYSTEM DIAGNOSTICS',
      Column(
        children: [
          statusRow('Application', 'DN WATCH OS'),
          statusRow('Bluetooth', connected ? 'CONNECTED' : 'DISCONNECTED'),
          statusRow('BLE devices', '${devices.length}'),
          statusRow('BLE services', '${discoveredServices.length}'),
          statusRow('Read records', '${readValues.length}'),
          statusRow('Scanner', scanning ? 'ACTIVE' : 'IDLE'),
          statusRow('Connection process', connecting ? 'ACTIVE' : 'IDLE'),
        ],
      ),
    );
  }

  // ==========================================
  // TOOLS PAGE
  // ==========================================

  Widget toolsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          panel(
            'ADVANCED DEVICE TOOLS',
            Column(
              children: [
                const Icon(
                  Icons.build_circle_outlined,
                  color: Colors.cyanAccent,
                  size: 55,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: outlineButton(
                    'FIRMWARE FINGERPRINT SCANNER',
                    () {
                      setState(() {
                        selectedIndex = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: outlineButton(
                    'READ DEVICE INFORMATION',
                    connected ? readSafeInformation : null,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: outlineButton(
                    'DISCONNECT WATCH',
                    connected ? disconnectWatch : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          diagnosticsPanel(),
        ],
      ),
    );
  }

  // ==========================================
  // MAIN APP BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      watchPage(),
      jarvisPage(),
      studioPage(),
      toolsPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.watch,
              color: Colors.cyanAccent,
            ),
            SizedBox(width: 10),
            Text(
              'DN WATCH OS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 17,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Icon(
              connected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: connected
                  ? Colors.greenAccent
                  : Colors.white54,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          border: Border(
            top: BorderSide(
              color: Colors.white12,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0D1117),
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white54,
          selectedFontSize: 10,
          unselectedFontSize: 9,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.watch_outlined),
              activeIcon: Icon(Icons.watch),
              label: 'Watch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.graphic_eq),
              label: 'JARVIS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Studio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              label: 'Tools',
            ),
          ],
        ),
      ),
    );
  }
}
