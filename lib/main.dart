
import 'package:flutter/material.dart';

void main() {
  runApp(const DNWatchOS());
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
        border: Border.all(color: cyan.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: cyan.withOpacity(0.06),
            blurRadius: 15,
          )
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
              Text(title,
                  style: TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  )),
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
          Text(value, style: TextStyle(color: cyan)),
        ],
      ),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 10),
        Text('DN WATCH OS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cyan,
              fontSize: 27,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            )),
        const SizedBox(height: 5),
        const Text('OMNI STARK SMART SYSTEM',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, letterSpacing: 2)),
        const SizedBox(height: 30),
        Center(
          child: Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cyan, width: 3),
              boxShadow: [
                BoxShadow(color: cyan.withOpacity(0.3), blurRadius: 30)
              ],
            ),
            child: Icon(Icons.watch, size: 85, color: cyan),
          ),
        ),
        const SizedBox(height: 25),
        panel('SYSTEM STATUS',
            Column(children: [
              statusRow('Application', 'ONLINE', Icons.phone_android),
              statusRow('Safety Shield',
                  safetyShield ? 'ACTIVE' : 'INACTIVE', Icons.security),
              statusRow('Bluetooth', 'NOT CONNECTED', Icons.bluetooth),
              statusRow('Firmware', 'PROTECTED', Icons.verified_user),
            ]),
            icon: Icons.monitor_heart),
        panel('WELCOME, SIR',
            const Text(
              'Your DN WATCH OS control center is ready.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            icon: Icons.auto_awesome),
      ],
    );
  }

  Widget watchPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        panel('WATCH CONNECTION',
            Column(children: [
              const Icon(Icons.watch, color: Colors.cyanAccent, size: 65),
              const SizedBox(height: 12),
              const Text('Fire-Boltt Axiom',
                  style: TextStyle(fontSize: 21, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Connection not started',
                  style: TextStyle(color: Colors.orangeAccent)),
              const SizedBox(height: 15),
              const Text(
                'Bluetooth scanning and connection will be added in a later update.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ]),
            icon: Icons.bluetooth),
        panel('DEVICE INFORMATION',
            Column(children: [
              statusRow('Watch model', 'Axiom', Icons.watch),
              statusRow('Protocol', 'Not verified', Icons.memory),
              statusRow('Firmware access', 'Disabled', Icons.lock),
            ]),
            icon: Icons.info_outline),
      ],
    );
  }

  Widget jarvisPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        panel('J.A.R.V.I.S.',
            Column(children: [
              Icon(Icons.smart_toy, color: cyan, size: 75),
              const SizedBox(height: 15),
              const Text('JARVIS CORE',
                  style: TextStyle(fontSize: 23, color: Colors.white)),
              const SizedBox(height: 10),
              const Text(
                'AI assistant integration is planned for a future update.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ]),
            icon: Icons.psychology),
      ],
    );
  }

  Widget studioPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        panel('WATCH STUDIO',
            Column(children: [
              Icon(Icons.wallpaper, color: cyan, size: 65),
              const SizedBox(height: 12),
              const Text('Watch Face Studio',
                  style: TextStyle(color: Colors.white, fontSize: 21)),
              const SizedBox(height: 10),
              const Text(
                'Custom watch-face and photo transfer support is not available yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ]),
            icon: Icons.brush),
      ],
    );
  }

  Widget toolsPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text('SECURITY CENTER',
            style: TextStyle(
                color: cyan, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        panel(
          'SAFETY SHIELD',
          Column(
            children: [
              Icon(Icons.shield, size: 75, color: safetyShield ? cyan : Colors.orange),
              const SizedBox(height: 12),
              Text(
                safetyShield ? 'PROTECTION MODE ON' : 'PROTECTION MODE OFF',
                style: TextStyle(
                  color: safetyShield ? cyan : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Safety Shield'),
                subtitle: const Text(
                  'App security preference only; not a BLE firewall yet.',
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
        panel('SECURITY RULES',
            Column(children: [
              statusRow('Unknown commands', 'NOT SENT', Icons.block),
              statusRow('Firmware flashing', 'DISABLED', Icons.lock),
              statusRow('Unknown BLE writes', 'NOT IMPLEMENTED', Icons.warning),
              statusRow('Watch reset', 'NOT AVAILABLE', Icons.restart_alt),
            ]),
            icon: Icons.gpp_good),
        panel(
          'IMPORTANT WARNING',
          const Text(
            'Never send unknown Bluetooth commands or flash unofficial firmware. This app currently does not write to your watch.',
            style: TextStyle(color: Colors.orangeAccent, height: 1.5),
          ),
          icon: Icons.warning_amber,
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
        title: Text('DN WATCH OS',
            style: TextStyle(
                color: cyan, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF081522),
        indicatorColor: cyan.withOpacity(0.15),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
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
