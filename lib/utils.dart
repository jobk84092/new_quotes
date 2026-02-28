// utils.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:new_quotes/services/local_data_service.dart';
import 'package:new_quotes/services/purchase_service.dart';
import 'package:new_quotes/services/premium_db_service.dart';
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
  final List<String> neutral = <String>[];
  final List<String> other = <String>[];

  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets();

    for (final key in allAssets) {
      if (key.startsWith('assets/images/') && (key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.png'))) {
        if (key.startsWith('assets/images/neutrals/')) {
          neutral.add(key);
        } else {
          other.add(key);
        }
      }
    }
  } catch (_) {}

  if (neutral.isEmpty && other.isEmpty) {
    neutralImages = ['assets/images/topquoteone.png'];
    return;
  }

  final out = <String>[];
  for (final p in neutral) {
    if (out.length >= count) break;
    out.add(p);
  }
  for (final p in other) {
    if (out.length >= count) break;
    out.add(p);
  }
  neutralImages = out.isEmpty ? ['assets/images/topquoteone.png'] : out;
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

List<Map<String, dynamic>>? _quotesCache;
List<Map<String, dynamic>>? _categoriesCache;

const int freeQuotesCap = 100000;

bool _premiumActive() {
  if (kIsWeb) return false;
  return PurchaseService.instance.premiumActive.value;
}

Future<List<Map<String, dynamic>>> _loadQuotesCached() async {
  final existing = _quotesCache;
  if (existing != null) return existing;
  final local = LocalDataService();
  final qs = await local.loadQuotes();
  final mapped = qs.map((q) => {
    'quote': q['text'] ?? '',
    'author': q['author'] ?? 'Unknown',
    'category': q['category'] ?? '',
    'tags': q['tags'] ?? <dynamic>[],
    'is_premium': q['is_premium'] ?? false,
    'created_at': q['created_at'],
  }).toList();
  _quotesCache = mapped;
  return mapped;
}

Future<List<Map<String, dynamic>>> _loadCategoriesCached() async {
  final existing = _categoriesCache;
  if (existing != null) return existing;
  final local = LocalDataService();
  final cats = await local.loadCategories();
  final mapped = cats.map((c) => {
    'id': c['id'] ?? '',
    'name': c['name'] ?? '',
  }).toList();
  _categoriesCache = mapped;
  return mapped;
}

Future<List<Map<String, dynamic>>> getQuotes({int limit = 50, int offset = 0}) async {
  final premium = _premiumActive();
  if (premium) {
    final hasDb = await PremiumDbService.instance.hasDb();
    if (hasDb) {
      return PremiumDbService.instance.getQuotesPage(limit: limit, offset: offset);
    }
  }

  final mapped = await _loadQuotesCached();
  final visible = premium
      ? mapped
      : mapped.where((q) => (q['is_premium'] == true) ? false : true).toList();

  final capped = visible.length > freeQuotesCap ? visible.sublist(0, freeQuotesCap) : visible;
  if (offset >= capped.length) return [];
  final end = (offset + limit).clamp(0, capped.length);
  return capped.sublist(offset, end);
}

Future<List<Map<String, dynamic>>> getCategories() async {
  final premium = _premiumActive();
  if (premium) {
    final hasDb = await PremiumDbService.instance.hasDb();
    if (hasDb) {
      return PremiumDbService.instance.getCategories();
    }
  }
  return _loadCategoriesCached();
}

Future<List<Map<String, dynamic>>> getCategoryQuotes(
  String categoryId, {
  int limit = 50,
  int offset = 0,
}) async {
  final premium = _premiumActive();
  if (premium) {
    final hasDb = await PremiumDbService.instance.hasDb();
    if (hasDb) {
      return PremiumDbService.instance.getQuotesByCategory(
        categoryId: categoryId,
        limit: limit,
        offset: offset,
      );
    }
  }

  final all = await _loadQuotesCached();
  final visible = premium
      ? all
      : all.where((q) => (q['is_premium'] == true) ? false : true).toList();
  final capped = visible.length > freeQuotesCap ? visible.sublist(0, freeQuotesCap) : visible;
  final filtered = capped.where((q) => q['category'] == categoryId).toList();
  if (offset >= filtered.length) return [];
  final end = (offset + limit).clamp(0, filtered.length);
  final page = filtered.sublist(offset, end);
  page.shuffle();
  return page;
}
