import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fullscreen_window/fullscreen_window.dart';
import 'package:media_kit/media_kit.dart';
import 'package:outlined_text/outlined_text.dart';
import 'package:sharktv_flutter/helpers/data.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlayerScreen extends StatefulWidget {
  final List<Channel> channels;

  const PlayerScreen({super.key, required this.channels});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  List<Channel> channels = [];
  Channel? currentChannel;
  bool isFullScreen = false;

  late final Player player = Player();
  late final VideoController videoController = VideoController(player);

  bool _menuOpen = false;
  String? error;

  bool _uiVisible = true;
  Timer? _hideTimer;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  bool _muted = false;

  static const Duration _uiHideDelay = Duration(seconds: 2);
  static const Duration _fadeDuration = Duration(milliseconds: 250);
  static const Duration _menuAnimDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _showUiAndScheduleHide();

    _searchCtrl.addListener(() {
      final v = _searchCtrl.text;
      if (v == _query) return;
      setState(() => _query = v);
    });

    setState(() {
      channels = widget.channels;
      _playChannel(channels.first);
    });

    player.stream.error.listen((var err) {
      setState(() {
        error = err;
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _searchCtrl.dispose();
    player.stop();
    player.dispose();
    super.dispose();
  }

  void _showUiAndScheduleHide() {
    if (!mounted) return;

    if (!_uiVisible) {
      setState(() => _uiVisible = true);
    }

    _hideTimer?.cancel();
    _hideTimer = Timer(_uiHideDelay, () {
      if (!mounted) return;
      setState(() => _uiVisible = false);
    });
  }

  void _toggleMenu() {
    _showUiAndScheduleHide();
    setState(() => _menuOpen = !_menuOpen);
  }

  void _playChannel(Channel ch) {
    _showUiAndScheduleHide();
    setState(() {
      error = null;
      currentChannel = ch;
    });
    Map<String, String>? referer = ch.referer != null
        ? {"Referer": ?ch.referer}
        : null;
    player.open(
      Media(
        ch.url,
        // httpHeaders: {
        //   'User-Agent':
        //       ch.userAgent ??
        //       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.70",
        //   ...?referer,
        // },
      ),
    );
  }

  List<Channel> get _filteredChannels {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return channels;
    return channels.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    const double menuWidth = 320;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (_) => _showUiAndScheduleHide(),
        onPointerMove: (_) => _showUiAndScheduleHide(),
        onPointerSignal: (_) => _showUiAndScheduleHide(),
        child: MouseRegion(
          onHover: (_) => _showUiAndScheduleHide(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _showUiAndScheduleHide,
            child: Stack(
              children: [
                Row(
                  children: [
                    // MENU
                    AnimatedContainer(
                      duration: _menuAnimDuration,
                      curve: Curves.easeOutCubic,
                      width: _menuOpen ? menuWidth : 0,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1,
                          child: IgnorePointer(
                            ignoring: !_menuOpen,
                            child: _SideMenu(
                              channels: _filteredChannels,
                              currentChannel: currentChannel,
                              searchCtrl: _searchCtrl,
                              onSelect: _playChannel,
                              onClose: _toggleMenu,
                              onAnyInteraction: _showUiAndScheduleHide,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: ClipRect(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _menuOpen = false);
                                },
                                child: Stack(
                                  children: [
                                    Video(
                                      controls: (state) {
                                        return Container();
                                      },

                                      controller: videoController,

                                      // onCreated: (player) {
                                      //   player.error.addListener(
                                      //     () => setState(
                                      //       () => error = player.error.value,
                                      //     ),
                                      //   );
                                      // },
                                    ),

                                    if (error != null)
                                      Center(
                                        child: Card(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.info, size: 42),
                                                SizedBox(height: 12),
                                                Text(error!),
                                                SizedBox(height: 12),

                                                ElevatedButton(
                                                  onPressed: () {
                                                    _playChannel(
                                                      currentChannel!,
                                                    );
                                                  },
                                                  child: Text("Retry"),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: !_uiVisible,
                                child: AnimatedOpacity(
                                  opacity: _uiVisible ? 1 : 0,
                                  duration: _fadeDuration,
                                  curve: Curves.easeOut,
                                  child: SafeArea(
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Row(
                                            children: [
                                              _OverlayButton(
                                                icon: Icons.arrow_back,
                                                onTap: () =>
                                                    Navigator.pop(context),
                                              ),
                                              SizedBox(width: 12),
                                              OutlinedText(
                                                text: Text(
                                                  currentChannel?.name ?? "",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Positioned(
                                          left: 6,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: _menuOpen
                                                ? const SizedBox.shrink()
                                                : _OverlayButton(
                                                    icon: Icons.chevron_right,
                                                    onTap: _toggleMenu,
                                                  ),
                                          ),
                                        ),

                                        Positioned(
                                          bottom: 12,
                                          left: 12,
                                          right: 12,
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                90,
                                                14,
                                                14,
                                                14,
                                              ),
                                              border: Border.all(
                                                color: Colors.white12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            width: double.maxFinite,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            player.setVolume(
                                                              player.state.volume ==
                                                                      0
                                                                  ? 100
                                                                  : 0,
                                                            );
                                                          });
                                                        },
                                                        icon: Icon(
                                                          player.state.volume ==
                                                                  0
                                                              ? Icons.volume_off
                                                              : Icons.volume_up,
                                                        ),
                                                      ),
                                                      Spacer(),

                                                      IconButton(
                                                        onPressed: () {
                                                          isFullScreen =
                                                              !isFullScreen;
                                                          FullScreenWindow.setFullScreen(
                                                            isFullScreen,
                                                          );
                                                        },
                                                        icon: Icon(
                                                          Icons.fullscreen,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideMenu extends StatefulWidget {
  final List<Channel> channels;
  final Channel? currentChannel;
  final TextEditingController searchCtrl;
  final VoidCallback onClose;
  final void Function(Channel) onSelect;
  final VoidCallback onAnyInteraction;

  const _SideMenu({
    required this.channels,
    required this.currentChannel,
    required this.searchCtrl,
    required this.onClose,
    required this.onSelect,
    required this.onAnyInteraction,
    super.key,
  });

  @override
  State<_SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<_SideMenu>
    with AutomaticKeepAliveClientMixin<_SideMenu> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: const Color(0xFF0E0E0E),
      child: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Text(
                    widget.currentChannel?.country.value?.name ?? "-",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: _SearchField(controller: widget.searchCtrl),
                ),

                const Divider(height: 1, color: Colors.white12),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.channels.length,
                    itemBuilder: (context, index) {
                      final item = widget.channels[index];
                      final bool selected = item == widget.currentChannel;

                      return InkWell(
                        onTap: () {
                          widget.onAnyInteraction();
                          widget.onSelect(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          color: selected
                              ? Colors.white.withOpacity(0.08)
                              : Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              Text(item.quality),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: _OverlayButton(
                  icon: Icons.chevron_left,
                  onTap: () {
                    widget.onAnyInteraction();
                    widget.onClose();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        isDense: true,
        hintText: "Search channels...",
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.22)),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
