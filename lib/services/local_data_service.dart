import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LocalDataService {
  Future<List<Map<String, dynamic>>> loadQuotes() async {
    final raw = await rootBundle.loadString('assets/data/quotes.json');
    final List<dynamic> data = jsonDecode(raw);
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> loadCategories() async {
    final raw = await rootBundle.loadString('assets/data/categories.json');
    final List<dynamic> data = jsonDecode(raw);
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
