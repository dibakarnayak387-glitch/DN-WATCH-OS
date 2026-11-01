import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Diagnostics.install();
  runApp(const DNWatchOS());
}

class Diagnostics {
  static final List<String> logs = [];

  static void add(String title, String details) {
    logs.insert(
      0,
      '${DateTime.now()}\n$title\n$details',
    );
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

  @override
  void initState() {
    super.initState();

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
      if (mounted) {
        setState(() => scanning = value);
      }
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    scanningSubscription?.cancel();
    connectionSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Widget panel(
    String title,
    Widget child, {
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF101C29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cyan.withOpacity(.4)),
        boxShadow: [
          BoxShadow(
            color: cyan.withOpacity(.06),
            blurRadius: 15,
          ),
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
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
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

  Widget outlineButton(
    String label,
    IconData icon,
    VoidCallback? action,
  ) {
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

  Future<bool> requestBluetoothPermissions() async {
    try {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();

      if (scan.isGranted && connect.isGranted) {
        return true;
      }

      if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
        if (mounted) await openAppSettings();
      }

      return false;
    } catch (e) {
      Diagnostics.add('PERMISSION ERROR', '$e');
      return false;
    }
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
        timeout: const Duration(seconds: 15),
      );

      if (!mounted) return;

      connectedDevice = device;

      connectionSubscription?.cancel();

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

        Diagnostics.add(
          'CONNECTION STATE',
          state.toString(),
        );
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
      if (mounted) {
        setState(() => connecting = false);
      }
    }
  }

  Future<void> disconnectWatch() async {
    try {
      final device = connectedDevice;

      if (device != null) {
        await device.disconnect();
      }

      connectionSubscription?.cancel();

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

            final key =
                '${service.serviceUuid.str} / ${characteristic.characteristicUuid.str}';

            readValues[key] = value.isEmpty
                ? 'EMPTY'
                : bytesToHex(value);

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
      if (mounted) {
        setState(() => readingInfo = false);
      }
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
        border: Border.all(
          color: isAxiom ? cyan : Colors.white24,
        ),
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
                ...discoveredServices.map((service) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: SelectableText(
                      service.serviceUuid.str.toUpperCase(),
                      style: TextStyle(color: cyan, fontSize: 13),
                    ),
                  );
                }),
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
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        entry.key,
                        style: TextStyle(
                          color: cyan,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        entry.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            icon: Icons.data_object,
          ),
        panel(
          'DEVICE SAFETY',
          const Text(
            'This version scans, connects, discovers BLE services and reads characteristics marked as readable. It does not send unknown commands, write characteristics, change watch settings or flash firmware.',
            style: TextStyle(
              color: Colors.orangeAccent,
              height: 1.5,
            ),
          ),
          icon: Icons.shield,
        ),
      ],
    );
  }

  Widget jarvisPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        panel(
          'J.A.R.V.I.S.',
          Column(
            children: [
              Icon(Icons.smart_toy, color: cyan, size: 75),
              const SizedBox(height: 15),
              const Text(
                'JARVIS CORE',
                style: TextStyle(fontSize: 23, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Standalone watch AI is not enabled yet. Hardware and firmware compatibility must be verified first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, height: 1.5),
              ),
              const SizedBox(height: 15),
              statusRow(
                'Watch connection',
                connected ? 'ACTIVE' : 'INACTIVE',
                Icons.bluetooth,
              ),
              statusRow(
                'AI engine',
                'NOT INSTALLED',
                Icons.psychology,
              ),
              statusRow(
                'Internet',
                'NOT REQUIRED FOR THIS PAGE',
                Icons.cloud_off,
              ),
            ],
          ),
          icon: Icons.psychology,
        ),
      ],
    );
  }

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
                'Custom watch-face transfer is not available yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
          icon: Icons.brush,
        ),
      ],
    );
  }

  Widget diagnosticsPanel() {
    return StatefulBuilder(
      builder: (context, refresh) {
        return panel(
          'AUTO ERROR DETECTION',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App errors are recorded here.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 12),
              outlineButton(
                'RUN SAFE APP CHECK',
                Icons.health_and_safety,
                () {
                  Diagnostics.add(
                    'SAFE CHECK COMPLETED',
                    'App is responsive. BLE connection: $connected.',
                  );
                  refresh(() {});
                  showMessage('Safe check completed.');
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
                ...Diagnostics.logs.take(10).map((log) {
                  return Container(
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
                  );
                }),
            ],
          ),
          icon: Icons.bug_report,
        );
      },
    );
  }

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
                onChanged: (value) {
                  setState(() => safetyShield = value);
                },
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
      ],
    );
  }

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
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch),
            label: 'Watch',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy),
            label: 'JARVIS',
          ),
          NavigationDestination(
            icon: Icon(Icons.brush),
            label: 'Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.security),
            label: 'Tools',
          ),
        ],
      ),
    );
  }
}
