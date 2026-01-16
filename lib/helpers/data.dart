import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:http/http.dart' as http;

Future<List<Country>> setup() async {
  var channels = await fetch("https://iptv-org.github.io/api/channels.json");
  var streams = await fetch("https://iptv-org.github.io/api/streams.json");
  var logos = await fetch("https://iptv-org.github.io/api/logos.json");

  var countries = await fetch("https://iptv-org.github.io/api/countries.json");
  var categories = await fetch(
    "https://iptv-org.github.io/api/categories.json",
  );

  var dbCategories = parseCategories(categories);
  var dbCountries = parseCountries(countries);
  dbCountries.add(Country("Unknown", "AQ", "AQ"));

  final favorites = Country("Pinned", "FV", "⭐");
  dbCountries.add(favorites);

  parseChannels(channels, streams, logos, dbCountries, dbCategories);

  final usaTvCatalog = await fetch(
    "https://848b3516657c-usatv.baby-beamup.club/catalog/tv/all.json",
  );
  parseUsaTvCatalogIntoFavorites(usaTvCatalog, favorites);

  return dbCountries;
}

List<Channel> parseUsaTvCatalogIntoFavorites(
  dynamic usaTvCatalogJson,
  Country favorites,
) {
  final metas = (usaTvCatalogJson is Map<String, dynamic>)
      ? (usaTvCatalogJson["metas"] as List<dynamic>? ?? const [])
      : const <dynamic>[];

  final created = <Channel>[];

  for (final meta in metas) {
    if (meta is! Map<String, dynamic>) continue;

    final channelName = (meta["name"] as String?) ?? "Unknown";
    final logo = (meta["logo"] as String?) ?? (meta["poster"] as String?);

    final streams = (meta["streams"] as List<dynamic>?) ?? const [];
    if (streams.isEmpty) continue;

    for (final s in streams) {
      if (s is! Map<String, dynamic>) continue;

      final url = s["url"] as String?;
      if (url == null || url.isEmpty) continue;

      final quality = (s["name"] as String?) ?? "Unknown Quality";
      final description = (s["description"] as String?) ?? "";
      final titleSuffix = description.isNotEmpty ? " • $description" : "";

      final ch = Channel(
        meta["id"] ?? channelName, // channel (internal id-ish)
        "$channelName$titleSuffix", // name (display)
        null, // altNames
        quality,
        logo,
        null, // launchedOn
        null, // closedOn
        null, // network
        null, // website
        url, // stream url
        null, // userAgent
        null, // referer
      );

      ch.country.value = favorites;
      favorites.rawChannels.add(ch);
      created.add(ch);
    }
  }

  return created;
}

List<Channel> parseChannels(
  List<dynamic> channels,
  List<dynamic> streams,
  List<dynamic> logos,
  List<Country> dbCountries,
  List<Category> dbCategories,
) {
  final countryByIso2 = <String, Country>{
    for (final c in dbCountries) c.iso2: c,
  };

  final antarctica =
      countryByIso2["AQ"] ??
      (throw StateError('Country with iso2 "AQ" not found'));

  final channelById = <dynamic, dynamic>{for (final c in channels) c["id"]: c};

  final logoByChannel = <dynamic, String?>{};
  for (final l in logos) {
    final key = l["channel"];
    logoByChannel.putIfAbsent(key, () => l["url"] as String?);
  }

  final dbChannels = <Channel>[];
  dbChannels.length = 0;

  for (final item in streams) {
    final channelId = item["channel"];
    final channel = channelById[channelId];

    final logo = logoByChannel[channelId];

    final iso2 = channel?["country"] as String?;
    final country = countryByIso2[iso2] ?? antarctica;

    final dbChannel = Channel(
      item["channel"] ?? item["title"],
      item["title"],
      channel?["alt_names"]?.toString(),
      item?["quality"] ?? "Unknown Quality",
      logo,
      DateTime.tryParse((item["launched"] ?? "") as String),
      DateTime.tryParse((item["closed"] ?? "") as String),
      channel?["network"],
      channel?["website"],
      item["url"],
      item["user_agent"],
      item["referrer"],
    );

    dbChannel.country.value = country;
    country.rawChannels.add(dbChannel);
    dbChannels.add(dbChannel);
  }

  return dbChannels;
}

List<Category> parseCategories(dynamic categories) {
  List<Category> categoryList = [];
  for (var item in categories) {
    categoryList.add(Category.fromJson(item));
  }
  return categoryList;
}

List<Country> parseCountries(dynamic countries) {
  List<Country> countryList = [];
  for (var item in countries) {
    countryList.add(Country.fromJson(item));
  }
  return countryList;
}

Future<dynamic> fetch(String url) async {
  var response = await http.get(Uri.parse(url));
  return jsonDecode(response.body);
}

@collection
class Country {
  Id id = Isar.autoIncrement;
  String name;
  String iso2;
  String flag;

  IsarLinks<Channel> channels = IsarLinks<Channel>();
  List<Channel> rawChannels = [];

  // IsarLinks<Language> languages = IsarLinks<Language>();

  Country(this.name, this.iso2, this.flag);

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(json["name"], json["code"], json["flag"]);
  }
}

// @collection
// class Language {
//   Id id = Isar.autoIncrement;
//   String name;
//   String code;
//   Language(this.name, this.code);
//   factory Language.fromJson(Map<String, dynamic> json) {
//     return Language(json["name"], json["code"]);
//   }
// }

@collection
class Category {
  Id id = Isar.autoIncrement;
  String stringId;
  String name;
  String description;

  Category(this.stringId, this.name, this.description);

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(json["id"], json["name"], json["description"]);
  }
}

@collection
class Channel {
  Id id = Isar.autoIncrement;
  String channel;
  String name;
  String? altNames;
  String quality = "Unknown Quality";
  String? logo;
  DateTime? launchedOn;
  DateTime? closedOn;

  String? network;
  String? website;

  // Stream Information
  String url;
  String? userAgent;
  String? referer;

  IsarLink<Country> country = IsarLink<Country>();
  IsarLinks<Category> categories = IsarLinks<Category>();

  Channel(
    this.channel,
    this.name,
    this.altNames,
    this.quality,
    this.logo,
    this.launchedOn,
    this.closedOn,
    this.network,
    this.website,
    this.url,
    this.userAgent,
    this.referer,
  );
}
