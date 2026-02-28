import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PremiumDbService {
  PremiumDbService._internal();
  static final PremiumDbService instance = PremiumDbService._internal();

  static const MethodChannel _channel = MethodChannel('new_quotes/premium_db');

  // Hosted premium DB (GitHub Releases)
  static const String defaultUrl =
      'https://github.com/jobk84092/daily-quotes-assets/releases/download/db-v2/quotes_premium.db';

  Future<bool> hasDb() async {
    if (kIsWeb) return false;
    final ok = await _channel.invokeMethod<bool>('hasDb');
    return ok ?? false;
  }

  Future<bool> downloadDb({String url = defaultUrl}) async {
    if (kIsWeb) return false;
    final ok = await _channel.invokeMethod<bool>('downloadDb', {'url': url});
    return ok ?? false;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final list = await _channel.invokeMethod<List<dynamic>>('getCategories');
    return (list ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getQuotesPage({required int limit, required int offset}) async {
    final list = await _channel.invokeMethod<List<dynamic>>('getQuotesPage', {
      'limit': limit,
      'offset': offset,
    });
    return (list ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getQuotesByCategory({
    required String categoryId,
    required int limit,
    required int offset,
  }) async {
    final list = await _channel.invokeMethod<List<dynamic>>('getQuotesByCategory', {
      'categoryId': categoryId,
      'limit': limit,
      'offset': offset,
    });
    return (list ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

