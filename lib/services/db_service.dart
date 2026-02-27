import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBService {
  DBService._internal();

  static final DBService instance = DBService._internal();

  static const String _dbAssetPath = 'assets/db/quotes.db';
  static const String _dbFileName = 'quotes.db';
  static const String _quoteFields =
      'id, text as quote, author, category_id as category, tags, is_premium, created_at';

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _openDatabase();
    _db = opened;
    return opened;
  }

  Future<String> _dbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_dbFileName';
  }

  Future<Database> _openDatabase() async {
    final path = await _dbPath();
    final file = File(path);
    if (!await file.exists()) {
      await _copyDbFromAssets(path);
    }
    return openDatabase(path, readOnly: true);
  }

  Future<void> _copyDbFromAssets(String path) async {
    final directory = Directory(path).parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final data = await rootBundle.load(_dbAssetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.rawQuery('SELECT id, name FROM categories ORDER BY name');
  }

  Future<List<Map<String, dynamic>>> getQuotesPage({
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    return db.rawQuery(
      'SELECT $_quoteFields FROM quotes ORDER BY id LIMIT ? OFFSET ?',
      [limit, offset],
    );
  }

  Future<List<Map<String, dynamic>>> getQuotesByCategory({
    required String categoryId,
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    return db.rawQuery(
      'SELECT $_quoteFields FROM quotes WHERE category_id = ? ORDER BY id LIMIT ? OFFSET ?',
      [categoryId, limit, offset],
    );
  }

  Future<Map<String, dynamic>?> getRandomQuote({String? categoryId}) async {
    final db = await database;
    final List<Map<String, dynamic>> rows;
    if (categoryId == null || categoryId.isEmpty) {
      rows = await db.rawQuery(
        'SELECT $_quoteFields FROM quotes ORDER BY RANDOM() LIMIT 1',
      );
    } else {
      rows = await db.rawQuery(
        'SELECT $_quoteFields FROM quotes WHERE category_id = ? ORDER BY RANDOM() LIMIT 1',
        [categoryId],
      );
    }
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> searchQuotes(
    String q, {
    int limit = 50,
    int offset = 0,
  }) async {
    final query = q.trim();
    if (query.isEmpty) return [];
    final db = await database;
    final like = '%$query%';
    return db.rawQuery(
      'SELECT $_quoteFields FROM quotes WHERE text LIKE ? OR author LIKE ? LIMIT ? OFFSET ?',
      [like, like, limit, offset],
    );
  }
}
