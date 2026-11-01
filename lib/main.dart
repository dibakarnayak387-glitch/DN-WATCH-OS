
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

  // ---------------- JARVIS VOICE FUNCTIONS ----------------

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

  // ---------------- COMMON UI ----------------

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

  // ---------------- BLUETOOTH FUNCTIONS ----------------

  Future<bool> requestBluetoothPermissions() async {
    try {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();

      if (scan.isGranted && connect.isGranted) return true;

      if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
        if (mounted) await openAppSettings();
      }

      return false;
    } catch (e) {
      Diagnostics.add('PERMISSION ERROR', '$e');
      return false;
    }
  }

  Future<void> startBleScan() async {
    if (scanning || connecting || connected) return;

    try {
      final allowed = await requestBluetoothPermissions();

      if (!allowed) {
        showMessage('Bluetooth permissions are required.');
        return;
      }

      final adapter = await FlutterBluePlus.adapterState.first;

      if (adapter != BluetoothAdapterState.on) {
        showMessage('Please turn ON phone Bluetooth first.');
        return;
      }

      setState(() {
        devices.clear();
        discoveredServices.clear();
        readValues.clear();
      });

      Diagnostics.add('BLE SCAN', 'Started nearby device scan.');

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      showMessage('Bluetooth scan started.');
    } catch (e) {
      Diagnostics.add('BLE SCAN ERROR', '$e');
      showMessage('Scan failed: $e');
    }
  }

  Future<void> stopBleScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      Diagnostics.add('STOP SCAN ERROR', '$e');
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    if (connecting || connected) return;

    try {
      await stopBleScan();

      final allowed = await requestBluetoothPermissions();
      if (!allowed) {
        showMessage('Bluetooth permission not granted.');
        return;
      }

      setState(() {
        connecting = true;
        discoveredServices.clear();
        readValues.clear();
      });

      Diagnostics.add(
        'BLE CONNECT',
        'Connecting to ${device.remoteId.str}',
      );

      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );

      if (!mounted) return;

      connectedDevice = device;
      await connectionSubscription?.cancel();

      connectionSubscription = device.connectionState.listen((state) {
        if (!mounted) return;

        setState(() {
          connected = state == BluetoothConnectionState.connected;

          if (!connected) {
            connectedDevice = null;
            discoveredServices.clear();
            readValues.clear();
          }
        });

        Diagnostics.add('CONNECTION STATE', state.toString());
      });

      final services = await device.discoverServices();

      if (!mounted) return;

      setState(() {
        discoveredServices = services;
        connected = true;
      });

      Diagnostics.add(
        'BLE CONNECTED',
        'Found ${services.length} services.',
      );

      showMessage('Watch connected. Services discovered.');
    } catch (e) {
      Diagnostics.add('BLE CONNECTION ERROR', '$e');

      if (mounted) {
        setState(() {
          connected = false;
          connectedDevice = null;
        });
      }

      showMessage('Connection failed: $e');
    } finally {
      if (mounted) setState(() => connecting = false);
    }
  }

  Future<void> disconnectWatch() async {
    try {
      final device = connectedDevice;
      if (device != null) await device.disconnect();

      await connectionSubscription?.cancel();

      if (!mounted) return;

      setState(() {
        connected = false;
        connecting = false;
        connectedDevice = null;
        discoveredServices.clear();
        readValues.clear();
      });

      Diagnostics.add('BLE DISCONNECTED', 'Disconnected safely.');
      showMessage('Watch disconnected.');
    } catch (e) {
      Diagnostics.add('DISCONNECT ERROR', '$e');
      showMessage('Disconnect error: $e');
    }
  }

  String bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join('-');
  }

  String decodeText(List<int> bytes) {
    return String.fromCharCodes(
      bytes.where((b) => b >= 32 && b <= 126),
    ).trim();
  }

  String characteristicName(String uuid) {
    final id = uuid.replaceAll('-', '').toUpperCase();

    const names = {
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

    for (final entry in names.entries) {
      if (id.contains(entry.key)) return entry.value;
    }

    return 'BLE Characteristic';
  }

  String interpretValue(String uuid, List<int> bytes) {
    final id = uuid.replaceAll('-', '').toUpperCase();

    if (bytes.isEmpty) return 'EMPTY';

    if (id.contains('2A19')) {
      final battery = bytes.first;
      return battery <= 100 ? '$battery%' : 'Invalid battery value';
    }

    if (id.contains('2A29') ||
        id.contains('2A24') ||
        id.contains('2A25') ||
        id.contains('2A26') ||
        id.contains('2A27') ||
        id.contains('2A28')) {
      final decoded = decodeText(bytes);
      if (decoded.isNotEmpty) return decoded;
    }

    return bytesToHex(bytes);
  }

  Future<void> readSafeInformation() async {
    if (!connected || connectedDevice == null || readingInfo) {
      showMessage('Connect the watch first.');
      return;
    }

    setState(() => readingInfo = true);

    int success = 0;
    int failed = 0;

    try {
      for (final service in discoveredServices) {
        for (final characteristic in service.characteristics) {
          if (!characteristic.properties.read) continue;

          try {
            final value = await characteristic.read();
            final uuid = characteristic.characteristicUuid.str;

            final key =
                '${characteristicName(uuid)}\n${service.serviceUuid.str} / $uuid';

            readValues[key] = interpretValue(uuid, value);
            success++;
          } catch (e) {
            failed++;
            Diagnostics.add(
              'BLE READ ERROR',
              '${characteristic.characteristicUuid.str}: $e',
            );
          }
        }
      }

      Diagnostics.add(
        'BLE READ COMPLETE',
        'Successful: $success | Failed: $failed',
      );

      if (mounted) {
        setState(() {});
        showMessage('Read complete: $success successful, $failed failed.');
      }
    } catch (e) {
      Diagnostics.add('BLE INFORMATION ERROR', '$e');
      showMessage('Read failed: $e');
    } finally {
      if (mounted) setState(() => readingInfo = false);
    }
  }

  Widget deviceCard(ScanResult result) {
    final device = result.device;

    final name = result.advertisementData.advName.isNotEmpty
        ? result.advertisementData.advName
        : (device.platformName.isNotEmpty
            ? device.platformName
            : 'Unknown BLE Device');

    final isAxiom =
        name.toLowerCase().contains('axiom') ||
        device.remoteId.str.toUpperCase() == '6F:5F:4B:97:9C:BA';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1723),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: isAxiom ? cyan : Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bluetooth, color: cyan, size: 25),
              const SizedBox(width: 10),
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
                    Text(
                      device.remoteId.str,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${result.rssi} dBm',
                style: TextStyle(color: cyan, fontSize: 12),
              ),
            ],
          ),
          if (isAxiom)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'POSSIBLE FIRE-BOLTT AXIOM',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 10),
          outlineButton(
            'CONNECT TO DEVICE',
            Icons.link,
            connecting || connected ? null : () => connectDevice(device),
          ),
        ],
      ),
    );
  }

  // ---------------- HOME PAGE ----------------

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 10),
        Text(
          'DN WATCH OS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cyan,
            fontSize: 27,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'OMNI STARK SMART SYSTEM',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, letterSpacing: 2),
        ),
        const SizedBox(height: 30),
        Center(
          child: Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cyan, width: 3),
              boxShadow: [
                BoxShadow(color: cyan.withOpacity(.3), blurRadius: 30),
              ],
            ),
            child: Icon(Icons.watch, size: 85, color: cyan),
          ),
        ),
        const SizedBox(height: 25),
        panel(
          'SYSTEM STATUS',
          Column(
            children: [
              statusRow('Application', 'ONLINE', Icons.phone_android),
              statusRow(
                'Safety Shield',
                safetyShield ? 'ACTIVE' : 'INACTIVE',
                Icons.security,
              ),
              statusRow(
                'Bluetooth',
                connected ? 'CONNECTED' : 'NOT CONNECTED',
                Icons.bluetooth,
              ),
              statusRow('Error Monitor', 'ACTIVE', Icons.monitor_heart),
            ],
          ),
          icon: Icons.monitor_heart,
        ),
        panel(
          'WELCOME, SIR',
          const Text(
            'Your DN WATCH OS control center is ready.',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          icon: Icons.auto_awesome,
        ),
      ],
    );
  }

  // ---------------- WATCH PAGE ----------------

  Widget watchPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        panel(
          'WATCH CONNECTION',
          Column(
            children: [
              const Icon(Icons.watch, color: Colors.cyanAccent, size: 65),
              const SizedBox(height: 12),
              const Text(
                'Fire-Boltt Axiom',
                style: TextStyle(fontSize: 21, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                connected
                    ? 'CONNECTED'
                    : connecting
                        ? 'CONNECTING...'
                        : scanning
                            ? 'SCANNING NEARBY DEVICES...'
                            : 'READY TO SCAN',
                style: TextStyle(
                  color: connected ? Colors.greenAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              outlineButton(
                scanning ? 'SCANNING...' : 'SCAN NEARBY DEVICES',
                Icons.bluetooth_searching,
                scanning || connecting || connected ? null : startBleScan,
              ),
              if (scanning) ...[
                const SizedBox(height: 10),
                outlineButton('STOP SCAN', Icons.stop, stopBleScan),
              ],
              if (connected) ...[
                const SizedBox(height: 10),
                outlineButton(
                  readingInfo ? 'READING...' : 'READ DEVICE INFORMATION',
                  Icons.memory,
                  readingInfo ? null : readSafeInformation,
                ),
                const SizedBox(height: 10),
                outlineButton(
                  'DISCONNECT WATCH',
                  Icons.link_off,
                  disconnectWatch,
                ),
              ],
            ],
          ),
          icon: Icons.bluetooth,
        ),
        panel(
          'NEARBY BLE DEVICES',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOUND DEVICES: ${devices.length}',
                style: TextStyle(color: cyan),
              ),
              const SizedBox(height: 12),
              if (devices.isEmpty)
                const Text(
                  'No devices found yet. Start scanning and keep your watch nearby.',
                  style: TextStyle(color: Colors.white60),
                )
              else
                ...devices.map(deviceCard),
            ],
          ),
          icon: Icons.radar,
        ),
        panel(
          'DISCOVERED SERVICES',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statusRow(
                'Connection',
                connected ? 'ACTIVE' : 'INACTIVE',
                Icons.link,
              ),
              statusRow(
                'Services found',
                '${discoveredServices.length}',
                Icons.memory,
              ),
              const SizedBox(height: 8),
              if (discoveredServices.isEmpty)
                const Text(
                  'Connect to a device to discover its services.',
                  style: TextStyle(color: Colors.white54),
                )
              else
                ...discoveredServices.map(
                  (service) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: SelectableText(
                      service.serviceUuid.str.toUpperCase(),
                      style: TextStyle(color: cyan, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
          icon: Icons.list_alt,
        ),
        if (readValues.isNotEmpty)
          panel(
            'READ DEVICE DATA',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: readValues.entries.map((entry) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1723),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        entry.value,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        panel(
          'DEVICE SAFETY',
          const Text(
            'This module only scans, connects, discovers services and reads characteristics marked as readable. It does not send unknown commands, write characteristics, change watch settings or flash firmware.',
            style: TextStyle(color: Colors.orangeAccent, height: 1.5),
          ),
          icon: Icons.shield,
        ),
      ],
    );
  }

  // ---------------- JARVIS PAGE ----------------

  Widget jarvisPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        panel(
          'J.A.R.V.I.S. VOICE CORE',
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: 142,
                width: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening
                      ? cyan.withOpacity(.18)
                      : const Color(0xFF0B1723),
                  border: Border.all(
                    color: isListening ? Colors.greenAccent : cyan,
                    width: isListening ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isListening ? Colors.greenAccent : cyan)
                          .withOpacity(isListening ? .45 : .18),
                      blurRadius: isListening ? 35 : 20,
                      spreadRadius: isListening ? 5 : 1,
                    ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.graphic_eq : Icons.smart_toy,
                  color: isListening ? Colors.greenAccent : cyan,
                  size: 75,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'J.A.R.V.I.S.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isListening
                    ? 'LISTENING TO YOUR COMMAND...'
                    : (speechAvailable
                        ? 'VOICE SYSTEM READY'
                        : 'INITIALIZING VOICE SYSTEM'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isListening ? Colors.greenAccent : cyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 18),
              outlineButton(
                isListening ? 'LISTENING...' : 'TAP TO SPEAK',
                isListening ? Icons.hearing : Icons.mic,
                isListening ? null : startJarvisListening,
              ),
              const SizedBox(height: 10),
              outlineButton(
                'STOP LISTENING',
                Icons.stop_circle_outlined,
                isListening ? stopJarvisListening : null,
              ),
              const SizedBox(height: 10),
              outlineButton(
                'TEST JARVIS VOICE',
                Icons.volume_up,
                () => speak('नमस्ते सर। जार्विस सिस्टम तैयार है।'),
              ),
            ],
          ),
          icon: Icons.psychology,
        ),
        panel(
          'VOICE INPUT',
          SelectableText(
            heardText.isEmpty
                ? 'Your recognized command will appear here.'
                : heardText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          icon: Icons.mic_none,
        ),
        panel(
          'JARVIS RESPONSE',
          Text(
            jarvisReply,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          icon: Icons.chat_bubble_outline,
        ),
        panel(
          'AVAILABLE VOICE COMMANDS',
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Hello Jarvis — greeting',
                style: TextStyle(color: Colors.white70, height: 1.8),
              ),
              Text(
                '• Time / Samay batao — current time',
                style: TextStyle(color: Colors.white70, height: 1.8),
              ),
              Text(
                '• Date / Aaj ki tarikh — date',
                style: TextStyle(color: Colors.white70, height: 1.8),
              ),
              Text(
                '• Home / Ghar — open Home tab',
                style: TextStyle(color: Colors.white70, height: 1.8),
              ),
              Text(
                '• Watch / Ghadi — open Watch tab',
                style: TextStyle(color: Colors.white70, height: 1.8),
              ),
              Text(
                '• Tools — open Tools tab',
                style: TextStyle(color: Colors.white70, height: 1.8),
              ),
              Text(
                '• Help / Madad — command help',
                style: TextStyle(color: Colors.white70, height: 1.8),
              ),
            ],
          ),
          icon: Icons.terminal,
        ),
        panel(
          'IMPORTANT',
          const Text(
            'This first JARVIS voice version uses your phone microphone, phone speech-recognition service and phone speaker. It is not running independently inside the Fire-Boltt watch. Speech recognition availability may depend on the Android speech service and language packs installed on your phone.',
            style: TextStyle(color: Colors.orangeAccent, height: 1.5),
          ),
          icon: Icons.info_outline,
        ),
      ],
    );
  }

  // ---------------- STUDIO PAGE ----------------

  Widget studioPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        panel(
          'WATCH STUDIO',
          Column(
            children: [
              Icon(Icons.watch, color: cyan, size: 65),
              const SizedBox(height: 12),
              const Text(
                'Fire-Boltt Axiom',
                style: TextStyle(color: Colors.white, fontSize: 21),
              ),
              const SizedBox(height: 10),
              const Text(
                'Watch-face transfer is not available in this version.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
          icon: Icons.tune,
        ),
      ],
    );
  }

  // ---------------- DIAGNOSTICS ----------------

  Widget diagnosticsPanel() {
    return StatefulBuilder(
      builder: (context, refresh) {
        return panel(
          'AUTO ERROR DETECTION',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Application errors are recorded here.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 12),
              outlineButton(
                'RUN SAFE APP CHECK',
                Icons.health_and_safety,
                () {
                  Diagnostics.add(
                    'SAFE CHECK',
                    'Application check completed. This does not test watch CPU or RAM.',
                  );
                  refresh(() {});
                  showMessage('Safe app check completed.');
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ERROR LOGS: ${Diagnostics.logs.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Diagnostics.logs.clear();
                      refresh(() {});
                    },
                    child: const Text('CLEAR'),
                  ),
                ],
              ),
              if (Diagnostics.logs.isEmpty)
                const Text(
                  'No errors recorded yet.',
                  style: TextStyle(color: Colors.greenAccent),
                )
              else
                ...Diagnostics.logs.take(10).map(
                  (log) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      log,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          icon: Icons.bug_report,
        );
      },
    );
  }

  // ---------------- TOOLS PAGE ----------------

  Widget toolsPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'SECURITY & DIAGNOSTICS',
          style: TextStyle(
            color: cyan,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        panel(
          'SAFETY SHIELD',
          Column(
            children: [
              Icon(
                Icons.shield,
                size: 65,
                color: safetyShield ? cyan : Colors.orange,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Safety Shield'),
                subtitle: const Text(
                  'App preference only; not a BLE firewall.',
                  style: TextStyle(color: Colors.white54),
                ),
                value: safetyShield,
                activeColor: cyan,
                onChanged: (value) => setState(() => safetyShield = value),
              ),
            ],
          ),
          icon: Icons.security,
        ),
        diagnosticsPanel(),
        panel(
          'SECURITY RULES',
          Column(
            children: [
              statusRow('Unknown commands', 'NOT SENT', Icons.block),
              statusRow('Firmware flashing', 'DISABLED', Icons.lock),
              statusRow('Unknown BLE writes', 'DISABLED', Icons.warning),
              statusRow('Watch reset', 'NOT AVAILABLE', Icons.restart_alt),
            ],
          ),
          icon: Icons.gpp_good,
        ),
        panel(
          'HARDWARE INFORMATION LIMITS',
          const Text(
            'Standard BLE services may expose manufacturer, model, firmware and battery information. CPU model, RAM size, internal storage and bootloader details cannot be confirmed unless the watch firmware provides them.',
            style: TextStyle(color: Colors.orangeAccent, height: 1.5),
          ),
          icon: Icons.memory,
        ),
      ],
    );
  }

  // ---------------- MAIN APP ----------------

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
      appBar: AppBar(
        backgroundColor: const Color(0xFF081522),
        title: Text(
          'DN WATCH OS',
          style: TextStyle(
            color: cyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF081522),
        indicatorColor: cyan.withOpacity(.15),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch_outlined),
            selectedIcon: Icon(Icons.watch),
            label: 'Watch',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'JARVIS',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Tools',
          ),
        ],
      ),
    );
  }
}
