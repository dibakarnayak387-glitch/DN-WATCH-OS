import 'dart:ui' as ui;
import 'package:flutter/material.dart';

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

    add('SYSTEM ONLINE', 'Automatic error monitoring started.');
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
  int selectedIndex = 0;
  bool safetyShield = true;
  final Color cyan = Colors.cyanAccent;

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
          BoxShadow(color: cyan.withOpacity(.06), blurRadius: 15)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, color: cyan),
              const SizedBox(width: 10),
            ],
            Text(title, style: TextStyle(
              color: cyan, fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            )),
          ]),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget statusRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: cyan, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(title,
            style: const TextStyle(color: Colors.white70))),
        Text(value, style: TextStyle(color: cyan)),
      ]),
    );
  }

  Widget homePage() {
    return ListView(padding: const EdgeInsets.all(18), children: [
      const SizedBox(height: 10),
      Text('DN WATCH OS', textAlign: TextAlign.center,
        style: TextStyle(color: cyan, fontSize: 27,
          fontWeight: FontWeight.bold, letterSpacing: 3)),
      const SizedBox(height: 5),
      const Text('OMNI STARK SMART SYSTEM',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, letterSpacing: 2)),
      const SizedBox(height: 30),
      Center(child: Container(
        height: 150, width: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cyan, width: 3),
          boxShadow: [BoxShadow(color: cyan.withOpacity(.3), blurRadius: 30)],
        ),
        child: Icon(Icons.watch, size: 85, color: cyan),
      )),
      const SizedBox(height: 25),
      panel('SYSTEM STATUS', Column(children: [
        statusRow('Application', 'ONLINE', Icons.phone_android),
        statusRow('Safety Shield',
            safetyShield ? 'ACTIVE' : 'INACTIVE', Icons.security),
        statusRow('Bluetooth', 'NOT CONNECTED', Icons.bluetooth),
        statusRow('Error Monitor', 'ACTIVE', Icons.monitor_heart),
      ]), icon: Icons.monitor_heart),
      panel('WELCOME, SIR', const Text(
        'Your DN WATCH OS control center is ready.',
        style: TextStyle(color: Colors.white70, fontSize: 15),
      ), icon: Icons.auto_awesome),
    ]);
  }

  Widget watchPage() {
    return ListView(padding: const EdgeInsets.all(18), children: [
      panel('WATCH CONNECTION', Column(children: [
        const Icon(Icons.watch, color: Colors.cyanAccent, size: 65),
        const SizedBox(height: 12),
        const Text('Fire-Boltt Axiom',
            style: TextStyle(fontSize: 21, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Connection not started',
            style: TextStyle(color: Colors.orangeAccent)),
        const SizedBox(height: 15),
        const Text('Bluetooth scanning and connection are not enabled yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60)),
      ]), icon: Icons.bluetooth),
      panel('DEVICE INFORMATION', Column(children: [
        statusRow('Watch model', 'Axiom', Icons.watch),
        statusRow('Protocol', 'Not verified', Icons.memory),
        statusRow('Firmware access', 'Disabled', Icons.lock),
      ]), icon: Icons.info_outline),
    ]);
  }

  Widget jarvisPage() {
    return ListView(padding: const EdgeInsets.all(18), children: [
      panel('J.A.R.V.I.S.', Column(children: [
        Icon(Icons.smart_toy, color: cyan, size: 75),
        const SizedBox(height: 15),
        const Text('JARVIS CORE',
            style: TextStyle(fontSize: 23, color: Colors.white)),
        const SizedBox(height: 10),
        const Text('AI assistant integration is planned.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60)),
      ]), icon: Icons.psychology),
    ]);
  }

  Widget studioPage() {
    return ListView(padding: const EdgeInsets.all(18), children: [
      panel('WATCH STUDIO', Column(children: [
        Icon(Icons.wallpaper, color: cyan, size: 65),
        const SizedBox(height: 12),
        const Text('Watch Face Studio',
            style: TextStyle(color: Colors.white, fontSize: 21)),
        const SizedBox(height: 10),
        const Text('Custom watch-face transfer is not available yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60)),
      ]), icon: Icons.brush),
    ]);
  }

  Widget diagnosticsPanel() {
    return StatefulBuilder(builder: (context, refresh) {
      return panel('AUTO ERROR DETECTION', Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App errors will be recorded here. You can view the error details and share them for repair.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Diagnostics.add('SAFE CHECK COMPLETED',
                'App is responsive. BLE and watch protocol have not been tested.');
              refresh(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Safe check completed')),
              );
            },
            icon: const Icon(Icons.health_and_safety),
            label: const Text('RUN SAFE APP CHECK'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cyan,
              side: BorderSide(color: cyan),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text('ERROR LOGS: ${Diagnostics.logs.length}',
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold))),
            TextButton(
              onPressed: () {
                Diagnostics.logs.clear();
                refresh(() {});
              },
              child: const Text('CLEAR'),
            ),
          ]),
          if (Diagnostics.logs.isEmpty)
            const Text('No errors recorded yet.',
              style: TextStyle(color: Colors.greenAccent))
          else
            ...Diagnostics.logs.take(10).map((log) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(log,
                style: const TextStyle(color: Colors.orangeAccent,
                  fontSize: 12)),
            )),
        ],
      ), icon: Icons.bug_report);
    });
  }

  Widget toolsPage() {
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text('SECURITY & DIAGNOSTICS',
        style: TextStyle(color: cyan, fontSize: 21,
          fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      panel('SAFETY SHIELD', Column(children: [
        Icon(Icons.shield, size: 65,
            color: safetyShield ? cyan : Colors.orange),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable Safety Shield'),
          subtitle: const Text(
            'App preference only; not a BLE firewall yet.',
            style: TextStyle(color: Colors.white54)),
          value: safetyShield,
          activeColor: cyan,
          onChanged: (value) => setState(() => safetyShield = value),
        ),
      ]), icon: Icons.security),
      diagnosticsPanel(),
      panel('SECURITY RULES', Column(children: [
        statusRow('Unknown commands', 'NOT SENT', Icons.block),
        statusRow('Firmware flashing', 'DISABLED', Icons.lock),
        statusRow('Unknown BLE writes', 'NOT IMPLEMENTED', Icons.warning),
        statusRow('Watch reset', 'NOT AVAILABLE', Icons.restart_alt),
      ]), icon: Icons.gpp_good),
      panel('WATCH SAFETY', const Text(
        'This app does not send Bluetooth write commands to your watch. Unknown commands and unofficial firmware are not used.',
        style: TextStyle(color: Colors.orangeAccent, height: 1.5),
      ), icon: Icons.warning_amber),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(), watchPage(), jarvisPage(), studioPage(), toolsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF081522),
        title: Text('DN WATCH OS',
          style: TextStyle(color: cyan, fontWeight: FontWeight.bold,
            letterSpacing: 2)),
        centerTitle: true,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF081522),
        indicatorColor: cyan.withOpacity(.15),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.watch), label: 'Watch'),
          NavigationDestination(icon: Icon(Icons.smart_toy), label: 'JARVIS'),
          NavigationDestination(icon: Icon(Icons.brush), label: 'Studio'),
          NavigationDestination(icon: Icon(Icons.security), label: 'Tools'),
        ],
      ),
    );
  }
}
