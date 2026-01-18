import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sharktv_flutter/helpers/data.dart';
import 'package:sharktv_flutter/livetv.dart';
import 'package:sharktv_flutter/settings.dart';
// import 'package:sharktv_flutter/livetv.dart';
// import 'package:sharktv_flutter/settings.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isWindows) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    // If using proxy.exe:
    final proxyPath = p.join(
      exeDir,
      'proxy',
      'proxy.exe --port 8523 --req-insecure',
    );

    Process _proc = await Process.start(
      proxyPath,
      [],
      workingDirectory: p.join(exeDir, 'proxy'),
      environment: {'PORT': '8523', 'TARGET': 'http://localhost'},
      runInShell: true,
    );

    final lifecycleHandler = AppLifecycleHandler(
      onExit: () async {
        _proc.kill(ProcessSignal.sigkill);
      },
    );

    WidgetsBinding.instance.addObserver(lifecycleHandler);
  }

  runApp(const IPTVApp());
}

class AppLifecycleHandler extends WidgetsBindingObserver {
  final Future<void> Function() onExit;

  AppLifecycleHandler({required this.onExit});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      onExit();
    }
  }
}

class IPTVApp extends StatelessWidget {
  const IPTVApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Player',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    setup();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Country>? _countries;

  @override
  void initState() {
    super.initState();
    setup().then((value) {
      value.sort(
        (a, b) => b.rawChannels.length.compareTo(a.rawChannels.length),
      );
      final favIndex = value.indexWhere((c) => c.iso2 == "FV");
      if (favIndex > 0) {
        final fav = value.removeAt(favIndex);
        value.insert(0, fav);
      }
      if (!mounted) return;
      setState(() => _countries = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black, Colors.blue]),
        ),
        child: Material(
          child: Row(
            children: [
              // Side Navigation for larger screens
              if (MediaQuery.of(context).size.width > 600)
                NavigationRail(
                  backgroundColor: Colors.transparent,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),

                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.live_tv_outlined),
                      selectedIcon: Icon(Icons.live_tv),
                      label: Text('Live TV'),
                    ),

                    // NavigationRailDestination(
                    //   icon: Icon(Icons.settings_outlined),
                    //   selectedIcon: Icon(Icons.settings),
                    //   label: Text('Settings'),
                    // ),
                  ],
                ),
              Expanded(
                child: _countries == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text("Loading Channels..."),
                          ],
                        ),
                      )
                    : LiveTVScreen(countries: _countries!),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? NavigationBar(
              backgroundColor: Colors.black,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.live_tv_outlined),
                  selectedIcon: Icon(Icons.live_tv),
                  label: 'Live TV',
                ),

                // NavigationDestination(
                //   icon: Icon(Icons.settings_outlined),
                //   selectedIcon: Icon(Icons.settings),
                //   label: 'Settings',
                // ),
              ],
            )
          : null,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('IPTV Player'),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {},
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeaturedSection(context),
                const SizedBox(height: 24),
                _buildContentRow('Continue Watching'),
                const SizedBox(height: 24),
                _buildContentRow('Popular Live Channels'),
                const SizedBox(height: 24),
                _buildContentRow('Trending Movies'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF2A2A2A),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Featured Content',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your favorite shows and movies',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Now'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentRow(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2A2A2A),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          color: const Color(0xFF3A3A3A),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 48,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Content ${index + 1}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

extension ThemeContext on BuildContext {
  ThemeData get currentTheme => Theme.of(this);
}
