import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:sharktv_flutter/helpers/data.dart';
import 'package:sharktv_flutter/playerscreen.dart';

class LiveTVScreen extends StatelessWidget {
  List<Country> countries;

  LiveTVScreen({super.key, required this.countries});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: false,
          pinned: true,
          title: const Text('Live TV'),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 500,
              childAspectRatio: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(childCount: countries.length, (
              context,
              index,
            ) {
              return _buildChannelCard(context, index);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(BuildContext context, int index) {
    final country = countries[index];
    final iso2 = country.iso2 == "UK" ? "GB" : country.iso2;
    final radius = BorderRadius.circular(8);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Flag background
          CountryFlag.fromCountryCode(iso2),

          // 2) Readability overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),

          // 3) Ripple layer (IMPORTANT: ripple paints on this Material)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlayerScreen(channels: country.rawChannels.toList()),
                    ),
                  );
                },
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle, size: 54),
                      Text(
                        country.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${country.rawChannels.length} channels',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4) Foreground content (above ripple)
        ],
      ),
    );
  }
}
