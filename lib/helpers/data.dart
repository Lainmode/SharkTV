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

  parseChannels(channels, streams, logos, dbCountries, dbCategories);

  return dbCountries;
}

List<Channel> parseChannels(
  List<dynamic> channels,
  List<dynamic> streams,
  List<dynamic> logos,
  List<Country> dbCountries,
  List<Category> dbCategories,
) {
  // Index countries once
  final countryByIso2 = <String, Country>{
    for (final c in dbCountries) c.iso2: c,
  };

  final antarctica =
      countryByIso2["AQ"] ??
      (throw StateError('Country with iso2 "AQ" not found'));

  // Index channels by id once (assumes channel["id"] is unique)
  final channelById = <dynamic, dynamic>{for (final c in channels) c["id"]: c};

  // Index logos by channel once (first wins)
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
