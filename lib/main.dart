
import 'package:flutter/material.dart';

void main() {
  runApp(const DNWatchOS());
}

const cyan = Color(0xFF00E5FF);
const bg = Color(0xFF050A13);
const panel = Color(0xFF101C2B);

class DNWatchOS extends StatelessWidget {
  const DNWatchOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DN WATCH OS',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
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

class _WatchHomeState extends State<WatchHome>
    with SingleTickerProviderStateMixin {
  int tab = 0;
  bool scanning = false;
  bool connected = false;

  late AnimationController animation;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF123348),
      ),
    );
  }

  void scanWatch() async {
    setState(() => scanning = true);
    message('BLE Scanner integration coming next!');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(),
      bluetoothPage(),
      aiPage(),
      studioPage(),
      toolsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        title: const Row(
          children: [
            Icon(Icons.blur_on, color: cyan, size: 30),
            SizedBox(width: 9),
            Text(
              'DN WATCH OS',
              style: TextStyle(
                color: cyan,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => message('Settings coming soon'),
            icon: const Icon(Icons.settings_outlined, color: cyan),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[tab],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0B1421),
        indicatorColor: cyan.withOpacity(0.15),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: cyan),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bluetooth),
            label: 'Watch',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt),
            label: 'JARVIS',
          ),
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            label: 'Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'Tools',
          ),
        ],
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'WELCOME BACK, CREATOR',
          style: TextStyle(
            color: cyan,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your Watch.\nYour Control.',
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFF123C55), Color(0xFF101827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: cyan.withOpacity(.45)),
          ),
          child: Column(
            children: [
              RotationTransition(
                turns: animation,
                child: const Icon(
                  Icons.blur_circular,
                  color: cyan,
                  size: 105,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'STARK WATCH CORE',
                style: TextStyle(
                  color: cyan,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                connected ? 'WATCH CONNECTED' : 'WATCH NOT CONNECTED',
                style: TextStyle(
                  color: connected ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => setState(() => tab = 1),
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('CONNECT WATCH'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cyan,
                  side: const BorderSide(color: cyan),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'CONTROL CENTER',
          style: TextStyle(color: cyan, letterSpacing: 2),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            featureCard(Icons.bluetooth, 'Bluetooth', 'Watch connection',
                () => setState(() => tab = 1)),
            featureCard(Icons.smart_toy, 'JARVIS AI', 'AI assistant',
                () => setState(() => tab = 2)),
            featureCard(Icons.photo_library, 'Photo Studio', 'Custom faces',
                () => setState(() => tab = 3)),
            featureCard(Icons.gamepad, 'Game Center', 'Mini games',
                () => setState(() => tab = 4)),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'SYSTEM STATUS',
          style: TextStyle(color: cyan, letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        statusTile('Bluetooth Module', 'Not initialized'),
        statusTile('AI Core', 'Ready for integration'),
        statusTile('Watch Protocol', 'FEEA detected'),
      ],
    );
  }

  Widget bluetoothPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.bluetooth_searching, size: 65, color: cyan),
        const SizedBox(height: 15),
        const Text(
          'WATCH CONNECTION',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 25),
        infoCard(
          'FIRE-BOLTT AXIOM',
          'Device ID: 6F:5F:4B:97:9C:BA',
          Icons.watch,
        ),
        infoCard(
          'BLE SERVICE',
          'UUID: FEEA',
          Icons.settings_bluetooth,
        ),
        infoCard(
          'NOTIFY CHARACTERISTIC',
          'FEE1 / FEE3',
          Icons.notifications_active,
        ),
        infoCard(
          'WRITE CHARACTERISTIC',
          'FEE2 - Write Without Response',
          Icons.send,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: scanning ? null : scanWatch,
          icon: Icon(scanning ? Icons.hourglass_top : Icons.search),
          label: Text(scanning ? 'SCANNING...' : 'SCAN FOR WATCH'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cyan,
            side: const BorderSide(color: cyan),
            padding: const EdgeInsets.all(17),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Bluetooth communication will be enabled in the next development phase.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget aiPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.psychology_alt, color: cyan, size: 90),
        const SizedBox(height: 15),
        const Text(
          'J.A.R.V.I.S.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            color: cyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const Text(
          'PERSONAL WATCH AI',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, letterSpacing: 2),
        ),
        const SizedBox(height: 30),
        infoCard('VOICE ASSISTANT', 'Coming soon', Icons.mic),
        infoCard('AI CHAT', 'Coming soon', Icons.chat),
        infoCard('SMART NOTIFICATIONS', 'Coming soon', Icons.notifications),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => message('JARVIS AI integration coming soon'),
          icon: const Icon(Icons.power_settings_new),
          label: const Text('INITIALIZE JARVIS'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cyan,
            side: const BorderSide(color: cyan),
            padding: const EdgeInsets.all(17),
          ),
        ),
      ],
    );
  }

  Widget studioPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.wallpaper, color: cyan, size: 80),
        const SizedBox(height: 15),
        const Text(
          'PHOTO STUDIO',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Create your own Fire-Boltt Axiom watch face.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 25),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: cyan.withOpacity(.4)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 70, color: cyan),
              SizedBox(height: 12),
              Text('YOUR PHOTO PREVIEW'),
              Text(
                'Select a photo in the next update',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => message('Photo picker coming next'),
          icon: const Icon(Icons.photo),
          label: const Text('CHOOSE PHOTO'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cyan,
            side: const BorderSide(color: cyan),
            padding: const EdgeInsets.all(17),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => message('Watch face sync requires protocol support'),
          icon: const Icon(Icons.sync),
          label: const Text('SYNC WATCH FACE'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cyan,
            side: const BorderSide(color: cyan),
            padding: const EdgeInsets.all(17),
          ),
        ),
      ],
    );
  }

  Widget toolsPage() {
    final tools = [
      ['Games', Icons.gamepad],
      ['Music Control', Icons.music_note],
      ['Camera Control', Icons.camera_alt],
      ['Notifications', Icons.notifications],
      ['Health Data', Icons.favorite],
      ['App Center', Icons.apps],
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'ADVANCED TOOLS',
          style: TextStyle(
            color: cyan,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        ...tools.map((tool) => infoCard(
          tool[0] as String,
          'Compatibility check required',
          tool[1] as IconData,
        )),
      ],
    );
  }

  Widget featureCard(
      IconData icon, String title, String subtitle, VoidCallback action) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: action,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cyan.withOpacity(.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cyan, size: 29),
            const SizedBox(height: 9),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoCard(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: cyan.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cyan, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget statusTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 9, color: cyan),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
