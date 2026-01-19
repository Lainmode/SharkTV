import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sharktv_flutter/helpers/data.dart';
import 'package:sharktv_flutter/livetv.dart';
import 'package:sharktv_flutter/settings.dart';

import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isWindows) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    supervisor = ProxySupervisor(exeDir: exeDir, port: 8523);
    await supervisor!.start();

    final lifecycleHandler = AppLifecycleHandler(
      onExit: () async {
        await supervisor!.stop();
      },
    );

    WidgetsBinding.instance.addObserver(lifecycleHandler);
  }

  runApp(const IPTVApp());
}

ProxySupervisor? supervisor;

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

class ProxySupervisor {
  ProxySupervisor({
    required this.exeDir,
    this.port = 8523,
    this.verbosity = 3,
    this.maxLogFiles = 5,
  });

  final String exeDir;
  final int port;
  final int verbosity;

  final int maxLogFiles;

  Process? _proc;

  IOSink? _logSink;
  String? _logPath;

  bool _starting = false;
  Future<void>? _startFuture;

  /// Call from anywhere.
  /// If proxy is already running (or port is already listening), returns immediately.
  /// Otherwise starts it (awaits) exactly once (no races).
  Future<void> ensureStarted() async {
    // Fast-path: if our process handle exists & is alive, we’re good.
    if (await _isOurProcessAlive()) return;

    // If something (maybe not us) is already listening on the port, treat as "running".
    // (You can decide if you prefer to kill & replace, but your requirement says
    // only kill-on-startup. So here we just return.)
    if (await _isPortListening(port)) return;

    // Serialize concurrent callers:
    final existing = _startFuture;
    if (existing != null) return existing;

    final fut = _ensureStartedInternal();
    _startFuture = fut;
    try {
      await fut;
    } finally {
      _startFuture = null;
    }
  }

  /// Optional: call this once at app startup if you want.
  /// It prunes logs, opens the log file, kills port occupier (Windows), then starts.
  Future<void> start() async {
    await _initLoggingIfNeeded();

    _writeLog('--- start() requested (port=$port, verbosity=$verbosity) ---');

    if (Platform.isWindows) {
      // Your requirement: if the port is taken by another process, end it.
      await _killPortOccupierIfAny(port);
    }

    await _startOnce();
  }

  Future<void> stop() async {
    _writeLog('--- stop() requested ---');
    await _killProcessTree();
    _proc = null;

    await _logSink?.flush();
    await _logSink?.close();
    _logSink = null;
  }

  // ---------------- Internal ----------------

  Future<void> _ensureStartedInternal() async {
    // If someone started it between checks, no-op.
    if (await _isOurProcessAlive()) return;
    if (await _isPortListening(port)) return;

    // This path might be called without start(), so ensure logging exists.
    await _initLoggingIfNeeded();

    // IMPORTANT: per your requirement “kill occupier on startup”.
    // If you mean “any time we attempt to start”, keep this here.
    // If you mean “only once at app launch”, move this call into your app’s startup flow.
    if (Platform.isWindows) {
      await _killPortOccupierIfAny(port);
    }

    await _startOnce();
  }

  Future<void> _initLoggingIfNeeded() async {
    if (_logSink != null) return;

    await _pruneOldLogs(keep: maxLogFiles);

    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    _logPath = p.join(exeDir, 'proxy', 'proxy$ts.log');
    _logSink = File(_logPath!).openWrite(mode: FileMode.append);

    _writeLog('--- logging initialized ---');
  }

  Future<void> _startOnce() async {
    // Final guard: if port is already taken, do NOT start.
    if (await _isPortListening(port)) {
      _writeLog('--- NOT starting: port $port is already LISTENING ---');
      return;
    }

    final proxyExe = p.join(exeDir, 'proxy', 'proxy.exe');
    final workDir = p.join(exeDir, 'proxy');

    final args = <String>[
      '-v',
      '$verbosity',
      '--port',
      '$port',
      '--req-insecure',
    ];

    try {
      final proc = await Process.start(
        proxyExe,
        args,
        workingDirectory: workDir,
        environment: {
          'PORT': '$port',
          'TARGET': 'http://localhost',
          ...Platform.environment,
        },
        runInShell: false,
      );

      _proc = proc;

      _writeLog(
        '--- started proxy.exe pid=${proc.pid} args=${args.join(" ")} ---',
      );

      _pipeToLog(proc.stdout, streamName: 'stdout', pid: proc.pid);
      _pipeToLog(proc.stderr, streamName: 'stderr', pid: proc.pid);

      // No auto-restart. We only observe exit for logging.
      unawaited(() async {
        final code = await proc.exitCode;
        _writeLog('--- proxy.exe pid=${proc.pid} exited code=$code ---');
        if (identical(_proc, proc)) {
          _proc = null; // allow future ensureStarted() to restart it
        }
      }());
    } catch (e) {
      _writeLog('--- spawn failed: $e ---');
      rethrow;
    }
  }

  void _pipeToLog(
    Stream<List<int>> stream, {
    required String streamName,
    required int pid,
  }) {
    stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => _writeLog('[$streamName pid=$pid] $line'),
          onError: (e) =>
              _writeLog('[$streamName pid=$pid] <stream error: $e>'),
        );
  }

  void _writeLog(String line) {
    final ts = DateTime.now().toIso8601String();
    _logSink?.writeln('[$ts] $line');
  }

  /// True if _proc exists and hasn’t exited.
  Future<bool> _isOurProcessAlive() async {
    final proc = _proc;
    if (proc == null) return false;

    // If exitCode completes immediately, it exited already.
    // Use a zero-timeout to probe without waiting.
    try {
      final code = await proc.exitCode.timeout(Duration.zero);
      _writeLog(
        '--- cached process pid=${proc.pid} already exited code=$code ---',
      );
      _proc = null;
      return false;
    } catch (_) {
      // timeout => still running
      return true;
    }
  }

  /// Windows: check LISTENING
  /// Non-Windows: bind check.
  Future<bool> _isPortListening(int port) async {
    if (Platform.isWindows) {
      final res = await Process.run('cmd', [
        '/c',
        'netstat -ano -p TCP | findstr "LISTENING" | findstr ":$port"',
      ], runInShell: true);

      final out = (res.stdout ?? '').toString().trim();
      return out.isNotEmpty;
    } else {
      try {
        final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
        await s.close();
        return false;
      } catch (_) {
        return true;
      }
    }
  }

  /// WINDOWS ONLY:
  /// Finds PIDs listening on :port and kills them (taskkill /F).
  /// Note: netstat output can contain multiple PIDs; we kill them all.
  Future<void> _killPortOccupierIfAny(int port) async {
    if (!Platform.isWindows) return;

    // netstat lines look like:
    // TCP    0.0.0.0:8523    0.0.0.0:0    LISTENING    1234
    final res = await Process.run('cmd', [
      '/c',
      'netstat -ano -p TCP | findstr "LISTENING" | findstr ":$port"',
    ], runInShell: true);

    final out = (res.stdout ?? '').toString();
    final lines = out
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      _writeLog('--- no port occupier found for :$port ---');
      return;
    }

    final pids = <int>{};
    for (final line in lines) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;
      final pidStr = parts.last;
      final pid = int.tryParse(pidStr);
      if (pid != null && pid > 0) {
        // Don’t kill our own cached process if it matches
        if (_proc?.pid == pid) continue;
        pids.add(pid);
      }
    }

    if (pids.isEmpty) return;

    for (final pid in pids) {
      _writeLog('--- killing port occupier pid=$pid on :$port ---');
      try {
        await Process.run('taskkill', [
          '/PID',
          '$pid',
          '/T',
          '/F',
        ], runInShell: true);
      } catch (e) {
        _writeLog('--- failed taskkill pid=$pid: $e ---');
      }
    }
  }

  /// Keeps only the newest [keep] proxy*.log files in exeDir/proxy.
  Future<void> _pruneOldLogs({required int keep}) async {
    if (keep <= 0) return;

    final dir = Directory(p.join(exeDir, 'proxy'));
    if (!await dir.exists()) return;

    final files = <File>[];
    await for (final ent in dir.list(followLinks: false)) {
      if (ent is! File) continue;
      final name = p.basename(ent.path);
      if (!name.startsWith('proxy') || p.extension(name) != '.log') continue;
      files.add(ent);
    }

    if (files.length < keep) return;

    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    // keep - 1 old + new file = keep total
    final toDelete = files.length - (keep - 1);
    for (int i = 0; i < toDelete; i++) {
      try {
        await files[i].delete();
      } catch (_) {}
    }
  }

  Future<void> _killProcessTree() async {
    final proc = _proc;
    if (proc == null) return;

    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', [
          '/PID',
          '${proc.pid}',
          '/T',
          '/F',
        ], runInShell: true);
      } catch (_) {
        try {
          proc.kill(ProcessSignal.sigkill);
        } catch (_) {}
      }
    } else {
      try {
        proc.kill(ProcessSignal.sigkill);
      } catch (_) {}
    }
  }
}
