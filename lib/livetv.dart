import 'package:flutter/material.dart';
import 'package:sharktv_flutter/playerscreen.dart';

class LiveTVScreen extends StatelessWidget {
  const LiveTVScreen({Key? key}) : super(key: key);

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
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildChannelCard(context, index);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(BuildContext context, int index) {
    var language = languages[index];
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(playlist: language),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv, size: 48, color: Color(0xFF6C63FF)),
            const SizedBox(height: 8),
            Text('${language["Language"]} ${index + 1}'),
            Text('${language["Channels"]}'),
          ],
        ),
      ),
    );
  }
}

class Channel {
  final String title;
  final String? logo;
  final String? group;
  final String link;

  final Map<String, String> vlcOpt;
  final Map<String, String> kodiProp;
  final List<String> metaLines;

  const Channel({
    required this.title,
    this.logo,
    this.group,
    required this.link,
    Map<String, String>? vlcOpt,
    Map<String, String>? kodiProp,
    List<String>? metaLines,
  }) : vlcOpt = vlcOpt ?? const {},
       kodiProp = kodiProp ?? const {},
       metaLines = metaLines ?? const [];
}

/// Extract attribute values from #EXTINF line, e.g. tvg-logo="..."
String? getAttr(String extinfLine, String name) {
  // Matches: name="value" OR name=value (rare, but seen)
  final re = RegExp('$name\\s*=\\s*"([^"]*)"|$name\\s*=\\s*([^\\s"]+)');
  final m = re.firstMatch(extinfLine);
  if (m == null) return null;
  final v = (m.group(1) ?? m.group(2) ?? '').trim();
  return v.isEmpty ? null : v;
}

({String key, String value}) parseKeyValueAfterPrefix(
  String line,
  String prefix,
) {
  final s = line.substring(prefix.length).trim(); // e.g. "http-user-agent=..."
  final idx = s.indexOf('=');
  if (idx < 0) {
    return (key: s, value: '');
  }
  final key = s.substring(0, idx).trim();
  final value = s.substring(idx + 1).trim();
  return (key: key, value: value);
}

List<Channel> convertM3u(String m3uText) {
  final lines = m3uText.split(RegExp(r'\r?\n'));
  final channels = <Channel>[];

  for (var i = 0; i < lines.length; i++) {
    final line = (lines[i]).trim();
    if (!line.startsWith('#EXTINF')) continue;

    final logo = getAttr(line, 'tvg-logo');
    final group = getAttr(line, 'group-title');

    final commaIdx = line.lastIndexOf(',');
    final title = commaIdx >= 0 ? line.substring(commaIdx + 1).trim() : '';

    final vlcOpt = <String, String>{};
    final kodiProp = <String, String>{};
    final metaLines = <String>[];

    var link = '';

    // scan forward until we hit the URL (first non-empty non-# line)
    for (var j = i + 1; j < lines.length; j++) {
      final l = (lines[j]).trim();
      if (l.isEmpty) continue;

      if (l.startsWith('#EXTVLCOPT:')) {
        metaLines.add(l);
        final kv = parseKeyValueAfterPrefix(l, '#EXTVLCOPT:');
        vlcOpt[kv.key] = kv.value;
        continue;
      }

      if (l.startsWith('#KODIPROP:')) {
        metaLines.add(l);
        final kv = parseKeyValueAfterPrefix(l, '#KODIPROP:');
        kodiProp[kv.key] = kv.value;
        continue;
      }

      if (l.startsWith('#')) {
        metaLines.add(l);
        continue;
      }

      // found URL
      link = l;
      i = j; // advance outer loop
      break;
    }

    if (link.isNotEmpty) {
      channels.add(
        Channel(
          title: title,
          logo: logo,
          group: group,
          link: link,
          vlcOpt: vlcOpt,
          kodiProp: kodiProp,
          metaLines: metaLines,
        ),
      );
    }
  }

  return channels;
}

const languages = [
  {
    "Language": "English",
    "Channels": "2350",
    "Playlist": "https://iptv-org.github.io/iptv/languages/eng.m3u",
  },
  {
    "Language": "Undefined",
    "Channels": "1860",
    "Playlist": "https://iptv-org.github.io/iptv/languages/undefined.m3u",
  },
  {
    "Language": "Spanish",
    "Channels": "1737",
    "Playlist": "https://iptv-org.github.io/iptv/languages/spa.m3u",
  },
  {
    "Language": "French",
    "Channels": "509",
    "Playlist": "https://iptv-org.github.io/iptv/languages/fra.m3u",
  },
  {
    "Language": "Arabic",
    "Channels": "366",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ara.m3u",
  },
  {
    "Language": "Russian",
    "Channels": "357",
    "Playlist": "https://iptv-org.github.io/iptv/languages/rus.m3u",
  },
  {
    "Language": "Italian",
    "Channels": "342",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ita.m3u",
  },
  {
    "Language": "German",
    "Channels": "323",
    "Playlist": "https://iptv-org.github.io/iptv/languages/deu.m3u",
  },
  {
    "Language": "Hindi",
    "Channels": "263",
    "Playlist": "https://iptv-org.github.io/iptv/languages/hin.m3u",
  },
  {
    "Language": "Portuguese",
    "Channels": "257",
    "Playlist": "https://iptv-org.github.io/iptv/languages/por.m3u",
  },
  {
    "Language": "Turkish",
    "Channels": "235",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tur.m3u",
  },
  {
    "Language": "Chinese",
    "Channels": "225",
    "Playlist": "https://iptv-org.github.io/iptv/languages/zho.m3u",
  },
  {
    "Language": "Persian",
    "Channels": "224",
    "Playlist": "https://iptv-org.github.io/iptv/languages/fas.m3u",
  },
  {
    "Language": "Dutch",
    "Channels": "180",
    "Playlist": "https://iptv-org.github.io/iptv/languages/nld.m3u",
  },
  {
    "Language": "Indonesian",
    "Channels": "176",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ind.m3u",
  },
  {
    "Language": "Greek",
    "Channels": "107",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ell.m3u",
  },
  {
    "Language": "Romanian",
    "Channels": "107",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ron.m3u",
  },
  {
    "Language": "Tamil",
    "Channels": "107",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tam.m3u",
  },
  {
    "Language": "Hungarian",
    "Channels": "102",
    "Playlist": "https://iptv-org.github.io/iptv/languages/hun.m3u",
  },
  {
    "Language": "Korean",
    "Channels": "89",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kor.m3u",
  },
  {
    "Language": "Polish",
    "Channels": "87",
    "Playlist": "https://iptv-org.github.io/iptv/languages/pol.m3u",
  },
  {
    "Language": "Urdu",
    "Channels": "81",
    "Playlist": "https://iptv-org.github.io/iptv/languages/urd.m3u",
  },
  {
    "Language": "Malayalam",
    "Channels": "76",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mal.m3u",
  },
  {
    "Language": "Vietnamese",
    "Channels": "76",
    "Playlist": "https://iptv-org.github.io/iptv/languages/vie.m3u",
  },
  {
    "Language": "Telugu",
    "Channels": "69",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tel.m3u",
  },
  {
    "Language": "Thai",
    "Channels": "69",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tha.m3u",
  },
  {
    "Language": "Catalan",
    "Channels": "63",
    "Playlist": "https://iptv-org.github.io/iptv/languages/cat.m3u",
  },
  {
    "Language": "Bengali",
    "Channels": "59",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ben.m3u",
  },
  {
    "Language": "Ukrainian",
    "Channels": "59",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ukr.m3u",
  },
  {
    "Language": "Mongolian",
    "Channels": "47",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mon.m3u",
  },
  {
    "Language": "Serbian",
    "Channels": "46",
    "Playlist": "https://iptv-org.github.io/iptv/languages/srp.m3u",
  },
  {
    "Language": "Albanian",
    "Channels": "44",
    "Playlist": "https://iptv-org.github.io/iptv/languages/sqi.m3u",
  },
  {
    "Language": "Slovak",
    "Channels": "40",
    "Playlist": "https://iptv-org.github.io/iptv/languages/slk.m3u",
  },
  {
    "Language": "Czech",
    "Channels": "37",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ces.m3u",
  },
  {
    "Language": "Panjabi",
    "Channels": "35",
    "Playlist": "https://iptv-org.github.io/iptv/languages/pan.m3u",
  },
  {
    "Language": "Macedonian",
    "Channels": "33",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mkd.m3u",
  },
  {
    "Language": "Kurdish",
    "Channels": "32",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kur.m3u",
  },
  {
    "Language": "Kannada",
    "Channels": "31",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kan.m3u",
  },
  {
    "Language": "Kazakh",
    "Channels": "28",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kaz.m3u",
  },
  {
    "Language": "Pashto",
    "Channels": "28",
    "Playlist": "https://iptv-org.github.io/iptv/languages/pus.m3u",
  },
  {
    "Language": "Finnish",
    "Channels": "26",
    "Playlist": "https://iptv-org.github.io/iptv/languages/fin.m3u",
  },
  {
    "Language": "Khmer",
    "Channels": "25",
    "Playlist": "https://iptv-org.github.io/iptv/languages/khm.m3u",
  },
  {
    "Language": "Bulgarian",
    "Channels": "24",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bul.m3u",
  },
  {
    "Language": "Croatian",
    "Channels": "24",
    "Playlist": "https://iptv-org.github.io/iptv/languages/hrv.m3u",
  },
  {
    "Language": "Japanese",
    "Channels": "24",
    "Playlist": "https://iptv-org.github.io/iptv/languages/jpn.m3u",
  },
  {
    "Language": "Marathi",
    "Channels": "24",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mar.m3u",
  },
  {
    "Language": "Uzbek",
    "Channels": "24",
    "Playlist": "https://iptv-org.github.io/iptv/languages/uzb.m3u",
  },
  {
    "Language": "Georgian",
    "Channels": "22",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kat.m3u",
  },
  {
    "Language": "Haitian",
    "Channels": "22",
    "Playlist": "https://iptv-org.github.io/iptv/languages/hat.m3u",
  },
  {
    "Language": "Swahili",
    "Channels": "20",
    "Playlist": "https://iptv-org.github.io/iptv/languages/swa.m3u",
  },
  {
    "Language": "Azerbaijani",
    "Channels": "17",
    "Playlist": "https://iptv-org.github.io/iptv/languages/aze.m3u",
  },
  {
    "Language": "Malay",
    "Channels": "17",
    "Playlist": "https://iptv-org.github.io/iptv/languages/msa.m3u",
  },
  {
    "Language": "Papiamento",
    "Channels": "17",
    "Playlist": "https://iptv-org.github.io/iptv/languages/pap.m3u",
  },
  {
    "Language": "Dari (Parsi)",
    "Channels": "16",
    "Playlist": "https://iptv-org.github.io/iptv/languages/prd.m3u",
  },
  {
    "Language": "Hebrew",
    "Channels": "16",
    "Playlist": "https://iptv-org.github.io/iptv/languages/heb.m3u",
  },
  {
    "Language": "Slovenian",
    "Channels": "15",
    "Playlist": "https://iptv-org.github.io/iptv/languages/slv.m3u",
  },
  {
    "Language": "Somali",
    "Channels": "15",
    "Playlist": "https://iptv-org.github.io/iptv/languages/som.m3u",
  },
  {
    "Language": "Swedish",
    "Channels": "15",
    "Playlist": "https://iptv-org.github.io/iptv/languages/swe.m3u",
  },
  {
    "Language": "Tajik",
    "Channels": "15",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tgk.m3u",
  },
  {
    "Language": "Bosnian",
    "Channels": "14",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bos.m3u",
  },
  {
    "Language": "Dhivehi",
    "Channels": "13",
    "Playlist": "https://iptv-org.github.io/iptv/languages/div.m3u",
  },
  {
    "Language": "Kirghiz",
    "Channels": "13",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kir.m3u",
  },
  {
    "Language": "Sinhala",
    "Channels": "13",
    "Playlist": "https://iptv-org.github.io/iptv/languages/sin.m3u",
  },
  {
    "Language": "Assamese",
    "Channels": "12",
    "Playlist": "https://iptv-org.github.io/iptv/languages/asm.m3u",
  },
  {
    "Language": "Danish",
    "Channels": "12",
    "Playlist": "https://iptv-org.github.io/iptv/languages/dan.m3u",
  },
  {
    "Language": "Gujarati",
    "Channels": "12",
    "Playlist": "https://iptv-org.github.io/iptv/languages/guj.m3u",
  },
  {
    "Language": "Letzeburgesch",
    "Channels": "12",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ltz.m3u",
  },
  {
    "Language": "Oriya (macrolanguage)",
    "Channels": "12",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ori.m3u",
  },
  {
    "Language": "Wolof",
    "Channels": "11",
    "Playlist": "https://iptv-org.github.io/iptv/languages/wol.m3u",
  },
  {
    "Language": "Bhojpuri",
    "Channels": "9",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bho.m3u",
  },
  {
    "Language": "Estonian",
    "Channels": "9",
    "Playlist": "https://iptv-org.github.io/iptv/languages/est.m3u",
  },
  {
    "Language": "Kinyarwanda",
    "Channels": "9",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kin.m3u",
  },
  {
    "Language": "Lithuanian",
    "Channels": "9",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lit.m3u",
  },
  {
    "Language": "Norwegian",
    "Channels": "9",
    "Playlist": "https://iptv-org.github.io/iptv/languages/nor.m3u",
  },
  {
    "Language": "Turkmen",
    "Channels": "9",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tuk.m3u",
  },
  {
    "Language": "Afrikaans",
    "Channels": "7",
    "Playlist": "https://iptv-org.github.io/iptv/languages/afr.m3u",
  },
  {
    "Language": "Burmese",
    "Channels": "7",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mya.m3u",
  },
  {
    "Language": "Latvian",
    "Channels": "7",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lav.m3u",
  },
  {
    "Language": "Amharic",
    "Channels": "6",
    "Playlist": "https://iptv-org.github.io/iptv/languages/amh.m3u",
  },
  {
    "Language": "Armenian",
    "Channels": "6",
    "Playlist": "https://iptv-org.github.io/iptv/languages/hye.m3u",
  },
  {
    "Language": "Basque",
    "Channels": "6",
    "Playlist": "https://iptv-org.github.io/iptv/languages/eus.m3u",
  },
  {
    "Language": "Lao",
    "Channels": "6",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lao.m3u",
  },
  {
    "Language": "Nepali",
    "Channels": "6",
    "Playlist": "https://iptv-org.github.io/iptv/languages/nep.m3u",
  },
  {
    "Language": "Tagalog",
    "Channels": "6",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tgl.m3u",
  },
  {
    "Language": "Yue Chinese",
    "Channels": "6",
    "Playlist": "https://iptv-org.github.io/iptv/languages/yue.m3u",
  },
  {
    "Language": "Bambara",
    "Channels": "5",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bam.m3u",
  },
  {
    "Language": "Ganda",
    "Channels": "5",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lug.m3u",
  },
  {
    "Language": "Icelandic",
    "Channels": "5",
    "Playlist": "https://iptv-org.github.io/iptv/languages/isl.m3u",
  },
  {
    "Language": "Lingala",
    "Channels": "5",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lin.m3u",
  },
  {
    "Language": "Maltese",
    "Channels": "5",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mlt.m3u",
  },
  {
    "Language": "Mandarin Chinese",
    "Channels": "5",
    "Playlist": "https://iptv-org.github.io/iptv/languages/cmn.m3u",
  },
  {
    "Language": "Javanese",
    "Channels": "4",
    "Playlist": "https://iptv-org.github.io/iptv/languages/jav.m3u",
  },
  {
    "Language": "Latin",
    "Channels": "4",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lat.m3u",
  },
  {
    "Language": "Pulaar",
    "Channels": "4",
    "Playlist": "https://iptv-org.github.io/iptv/languages/fuc.m3u",
  },
  {
    "Language": "Belarusian",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bel.m3u",
  },
  {
    "Language": "Faroese",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/fao.m3u",
  },
  {
    "Language": "Filipino",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/fil.m3u",
  },
  {
    "Language": "Gikuyu",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kik.m3u",
  },
  {
    "Language": "Hausa",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/hau.m3u",
  },
  {
    "Language": "Irish",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/gle.m3u",
  },
  {
    "Language": "Konkani (macrolanguage)",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kok.m3u",
  },
  {
    "Language": "Mandinka",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mnk.m3u",
  },
  {
    "Language": "Sundanese",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/sun.m3u",
  },
  {
    "Language": "Uighur",
    "Channels": "3",
    "Playlist": "https://iptv-org.github.io/iptv/languages/uig.m3u",
  },
  {
    "Language": "Afar",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/aar.m3u",
  },
  {
    "Language": "Dholuo",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/luo.m3u",
  },
  {
    "Language": "Dimili",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/zza.m3u",
  },
  {
    "Language": "Fon",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/fon.m3u",
  },
  {
    "Language": "Fulah",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ful.m3u",
  },
  {
    "Language": "Gaelic",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/gla.m3u",
  },
  {
    "Language": "Galician",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/glg.m3u",
  },
  {
    "Language": "Haryanvi",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bgc.m3u",
  },
  {
    "Language": "Kabyle",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kab.m3u",
  },
  {
    "Language": "Kongo",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kon.m3u",
  },
  {
    "Language": "Maori",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mri.m3u",
  },
  {
    "Language": "Morisyen",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mfe.m3u",
  },
  {
    "Language": "Mossi",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mos.m3u",
  },
  {
    "Language": "Samoan",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/smo.m3u",
  },
  {
    "Language": "Tachawit",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/shy.m3u",
  },
  {
    "Language": "Tamasheq",
    "Channels": "2",
    "Playlist": "https://iptv-org.github.io/iptv/languages/taq.m3u",
  },
  {
    "Language": "Acoli",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ach.m3u",
  },
  {
    "Language": "Adhola",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/adh.m3u",
  },
  {
    "Language": "Ahom",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/aho.m3u",
  },
  {
    "Language": "Alemannic",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/gsw.m3u",
  },
  {
    "Language": "Algerian Sign Language",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/asp.m3u",
  },
  {
    "Language": "Alur",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/alz.m3u",
  },
  {
    "Language": "Assyrian Neo-Aramaic",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/aii.m3u",
  },
  {
    "Language": "Ayizo Gbe",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ayb.m3u",
  },
  {
    "Language": "Aymara",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/aym.m3u",
  },
  {
    "Language": "Baatonum",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bba.m3u",
  },
  {
    "Language": "Bashkir",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bak.m3u",
  },
  {
    "Language": "Bisa",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bib.m3u",
  },
  {
    "Language": "Buamu",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/box.m3u",
  },
  {
    "Language": "Cebuano",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ceb.m3u",
  },
  {
    "Language": "Central Atlas Tamazight",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tzm.m3u",
  },
  {
    "Language": "Central Kurdish",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ckb.m3u",
  },
  {
    "Language": "Chenoua",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/cnu.m3u",
  },
  {
    "Language": "Chhattisgarhi",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/hne.m3u",
  },
  {
    "Language": "Chiga",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/cgg.m3u",
  },
  {
    "Language": "Dari (Persian)",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/prs.m3u",
  },
  {
    "Language": "Dhanwar (Nepal)",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/dhw.m3u",
  },
  {
    "Language": "Dyula",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/dyu.m3u",
  },
  {
    "Language": "Egyptian Arabic",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/arz.m3u",
  },
  {
    "Language": "Ewe",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ewe.m3u",
  },
  {
    "Language": "Fataleka",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/far.m3u",
  },
  {
    "Language": "Gen",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/gej.m3u",
  },
  {
    "Language": "Goan Konkani",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/gom.m3u",
  },
  {
    "Language": "Gourmanchéma",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/gux.m3u",
  },
  {
    "Language": "Guadeloupean Creole French",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/gcf.m3u",
  },
  {
    "Language": "Gun",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/guw.m3u",
  },
  {
    "Language": "Hmong",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/hmn.m3u",
  },
  {
    "Language": "Inuktitut",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/iku.m3u",
  },
  {
    "Language": "Isekiri",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/its.m3u",
  },
  {
    "Language": "Islander Creole English",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/icr.m3u",
  },
  {
    "Language": "Kabiyè",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kbp.m3u",
  },
  {
    "Language": "Kapampangan",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/pam.m3u",
  },
  {
    "Language": "Khorasani Turkish",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kmz.m3u",
  },
  {
    "Language": "Kituba (Congo)",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mkw.m3u",
  },
  {
    "Language": "Konabéré",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bbo.m3u",
  },
  {
    "Language": "Kumam",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/kdi.m3u",
  },
  {
    "Language": "Lahnda",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lah.m3u",
  },
  {
    "Language": "Lango (Uganda)",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/laj.m3u",
  },
  {
    "Language": "Lobi",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lob.m3u",
  },
  {
    "Language": "Luba-Lulua",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lua.m3u",
  },
  {
    "Language": "Lushai",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lus.m3u",
  },
  {
    "Language": "Lyélé",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/lee.m3u",
  },
  {
    "Language": "Maithili",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mai.m3u",
  },
  {
    "Language": "Marka",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/rkm.m3u",
  },
  {
    "Language": "Matya Samo",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/stj.m3u",
  },
  {
    "Language": "Maya Samo",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/sym.m3u",
  },
  {
    "Language": "Min Nan Chinese",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/nan.m3u",
  },
  {
    "Language": "Montenegrin",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/cnr.m3u",
  },
  {
    "Language": "Moroccan Sign Language",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/xms.m3u",
  },
  {
    "Language": "Mycenaean Greek",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/gmy.m3u",
  },
  {
    "Language": "Northern Dagara",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/dgi.m3u",
  },
  {
    "Language": "Nyankole",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/nyn.m3u",
  },
  {
    "Language": "Nyoro",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/nyo.m3u",
  },
  {
    "Language": "Quechua",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/que.m3u",
  },
  {
    "Language": "Romany",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/rom.m3u",
  },
  {
    "Language": "Saint Lucian Creole French",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/acf.m3u",
  },
  {
    "Language": "Santali",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/sat.m3u",
  },
  {
    "Language": "South African Sign Language",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/sfs.m3u",
  },
  {
    "Language": "South Ndebele",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/nbl.m3u",
  },
  {
    "Language": "Southern Samo",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/sbd.m3u",
  },
  {
    "Language": "Standard Arabic",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/arb.m3u",
  },
  {
    "Language": "Swati",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ssw.m3u",
  },
  {
    "Language": "Tachelhit",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/shi.m3u",
  },
  {
    "Language": "Tahitian",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tah.m3u",
  },
  {
    "Language": "Tamashek",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tmh.m3u",
  },
  {
    "Language": "Tarifit",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/rif.m3u",
  },
  {
    "Language": "Tatar",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tat.m3u",
  },
  {
    "Language": "Tibetan",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/bod.m3u",
  },
  {
    "Language": "Tigre",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tig.m3u",
  },
  {
    "Language": "Tigrinya",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tir.m3u",
  },
  {
    "Language": "Tooro",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ttj.m3u",
  },
  {
    "Language": "Tsonga",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/tso.m3u",
  },
  {
    "Language": "Tumzabt",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/mzb.m3u",
  },
  {
    "Language": "Venda",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/ven.m3u",
  },
  {
    "Language": "Welsh",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/cym.m3u",
  },
  {
    "Language": "Western Frisian",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/fry.m3u",
  },
  {
    "Language": "Xhosa",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/xho.m3u",
  },
  {
    "Language": "Yakut",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/sah.m3u",
  },
  {
    "Language": "Yoruba",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/yor.m3u",
  },
  {
    "Language": "Yucatec Maya",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/yua.m3u",
  },
  {
    "Language": "Zarma",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/dje.m3u",
  },
  {
    "Language": "Zulu",
    "Channels": "1",
    "Playlist": "https://iptv-org.github.io/iptv/languages/zul.m3u",
  },
];
