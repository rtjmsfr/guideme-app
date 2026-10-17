import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class Place {
  final String id;
  final String name;
  double rating;
  final int reviewCount;
  final String type;
  final List<String> imageUrls;
  final bool isFavorite;
  final String description;

  Place({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.type,
    required this.imageUrls,
    required this.isFavorite,
    required this.description,
  });
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? '', // لازم تتأكدي إنه بينضاف في كود الـ Cubit قبل الاستخدام
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: (json['reviewCount'] ?? 0).toInt(),
      type: json['type'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      description: json['description'] ?? '',
    );
  }
  factory Place.fromCsv(List<dynamic> row) {
    final name = row[0].toString();
    final id = _generateIdFromName(name);
    return Place(
      id: id,
      name: name,
      rating: double.tryParse(row[1].toString()) ?? 0,
      reviewCount: int.tryParse(row[2].toString()) ?? 0,
      type: row[3],
      imageUrls: List<String>.from(json.decode(row[4].replaceAll("'", '"'))),
      isFavorite: row[5].toString().toLowerCase() == 'true',
      description: row[6],
    );
  }
  static String _generateIdFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '-')
        .trim();
  }
}

Future<List<Place>> loadPlacesFromCsv() async {
  final rawData = await rootBundle.loadString('assets/data/Saudi_All_Attractions_Merged.csv');
  final List<List<dynamic>> csvTable = const CsvToListConverter().convert(rawData, eol: '\n');
  final places = csvTable.skip(1).map((row) {
    final place = Place.fromCsv(row);
    return place;
  }).toList();

  return places;
}
