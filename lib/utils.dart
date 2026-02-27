// utils.dart
import 'dart:math' as math;
import 'package:new_quotes/services/db_service.dart';
import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:flutter/material.dart';

List<Map<String, dynamic>> quotes = [];
List<Map<String, dynamic>> categories = [];
List<String> neutralImages = [];

String getRandomNeutralImage([int count = 50]) {
  math.Random random = math.Random();
  if (neutralImages.isNotEmpty) {
    int fetchCount = math.min(count, neutralImages.length);
    List<String> selectedImages = List.generate(fetchCount, (_) => neutralImages[random.nextInt(neutralImages.length)]);
    String selectedImage = selectedImages[random.nextInt(selectedImages.length)];
    return selectedImage;
  } else {
    return 'assets/images/topquoteone.png';
  }
}

// Offline: load neutral images from bundled assets
Future<void> loadNeutralImages([int count = 50]) async {
  final List<String> imagePaths = <String>[];

  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets();

    for (final key in allAssets) {
      if (key.startsWith('assets/images/') && (key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.png'))) {
        imagePaths.add(key);
      }
    }
  } catch (_) {}

  neutralImages = imagePaths.isEmpty ? ['assets/images/topquoteone.png'] : imagePaths.take(count).toList();
}

Future<List<String>> fetchNeutralImages([int count = 50]) async {
  if (neutralImages.isEmpty) {
    await loadNeutralImages(count);
  }
  return neutralImages.take(count).toList();
}

Widget buildToolBar() {
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      width: double.infinity,
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.photo), onPressed: () {}),
          IconButton(icon: const Icon(Icons.format_align_left), onPressed: () {}),
          IconButton(icon: const Icon(Icons.file_download), onPressed: () {}),
          IconButton(icon: const Icon(Icons.bookmark), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
    ),
  );
}

String capitalize(String s) {
  if (s.isEmpty) return 'Empty String';
  return s[0].toUpperCase() + s.substring(1);
}

String cleanCapitalizeAndBreak(String s) {
  if (s.isEmpty) return 'Unknown Category';
  List<String> words = s.split('-').map((word) => word[0].toUpperCase() + word.substring(1)).toList();
  String result = words.join(' ');
  if (words.isNotEmpty && words[0].length > 6) {
    result = result.replaceFirst(' ', '\n');
  }
  return result;
}

Future<List<Map<String, dynamic>>> getQuotes({
  int limit = 50,
  int offset = 0,
}) async {
  return DBService.instance.getQuotesPage(limit: limit, offset: offset);
}

Future<List<Map<String, dynamic>>> getCategories() async {
  return DBService.instance.getCategories();
}

Future<List<Map<String, dynamic>>> getCategoryQuotes(
  String categoryId, {
  int limit = 50,
  int offset = 0,
}) async {
  return DBService.instance.getQuotesByCategory(
    categoryId: categoryId,
    limit: limit,
    offset: offset,
  );
}
