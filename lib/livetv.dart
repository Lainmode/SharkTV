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
          floating: true,
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
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.5,
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
    var country = countries[index];
    if (country.iso2 == "UK") {
      country.iso2 = "GB";
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PlayerScreen(channels: country.channels2.toList()),
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 37, 40, 41), Colors.blue[900]!],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CountryFlag.fromCountryCode(
              country.iso2,
              theme: ImageTheme(shape: RoundedRectangle(8)),
            ),

            const SizedBox(height: 8),
            Text(country.name),
            Text('${country.channels2.length}'),
          ],
        ),
      ),
    );
  }
}
