import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  FavoritesService._internal();
  static final FavoritesService instance = FavoritesService._internal();

  static const String _favIdsKey = 'favorite_quote_ids';
  static const String _favQuotePrefix = 'favorite_quote_'; // + id

  bool _loaded = false;
  Set<String> _ids = <String>{};

  /// In-memory cache of stored favorite quote payloads (keyed by id).
  final Map<String, Map<String, dynamic>> _cache = <String, Map<String, dynamic>>{};

  /// Returns a stable id for a quote based on its content.
  String quoteId({
    required String quote,
    required String author,
    required String category,
  }) {
    final input = '$quote|$author|$category';
    final bytes = utf8.encode(input);
    return _fnv1aHex(bytes);
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favIdsKey) ?? const <String>[];
    _ids = list.toSet();
    _loaded = true;
  }

  Future<Set<String>> getIds() async {
    await _ensureLoaded();
    return Set<String>.from(_ids);
  }

  Future<bool> isFavorite(Map<String, dynamic> quote) async {
    await _ensureLoaded();
    final id = quoteId(
      quote: (quote['quote'] ?? quote['text'] ?? '').toString(),
      author: (quote['author'] ?? 'Unknown').toString(),
      category: (quote['category'] ?? '').toString(),
    );
    return _ids.contains(id);
  }

  Future<bool> toggleFavorite(Map<String, dynamic> quote) async {
    await _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();

    final q = (quote['quote'] ?? quote['text'] ?? '').toString().trim();
    final a = (quote['author'] ?? 'Unknown').toString().trim();
    final c = (quote['category'] ?? '').toString().trim();

    if (q.isEmpty) return false;

    final id = quoteId(quote: q, author: a, category: c);
    final key = '$_favQuotePrefix$id';

    if (_ids.contains(id)) {
      _ids.remove(id);
      _cache.remove(id);
      await prefs.remove(key);
      await prefs.setStringList(_favIdsKey, _ids.toList(growable: false));
      return false;
    }

    final payload = <String, dynamic>{
      'quote': q,
      'author': a.isEmpty ? 'Unknown' : a,
      'category': c,
      'tags': quote['tags'] is List ? quote['tags'] : <dynamic>[],
      'created_at': quote['created_at'],
      'is_premium': quote['is_premium'] == true,
    };

    _ids.add(id);
    _cache[id] = payload;
    await prefs.setString(key, jsonEncode(payload));
    await prefs.setStringList(_favIdsKey, _ids.toList(growable: false));
    return true;
  }

  Future<List<Map<String, dynamic>>> loadFavorites() async {
    await _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    final out = <Map<String, dynamic>>[];

    for (final id in _ids) {
      final cached = _cache[id];
      if (cached != null) {
        out.add(cached);
        continue;
      }
      final raw = prefs.getString('$_favQuotePrefix$id');
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final m = Map<String, dynamic>.from(decoded as Map);
          _cache[id] = m;
          out.add(m);
        }
      } catch (_) {
        // ignore broken entries
      }
    }

    // Most recent first (best-effort). Since we don't store timestamps,
    // keep deterministic order by id.
    out.sort((a, b) {
      final aId = quoteId(
        quote: (a['quote'] ?? '').toString(),
        author: (a['author'] ?? '').toString(),
        category: (a['category'] ?? '').toString(),
      );
      final bId = quoteId(
        quote: (b['quote'] ?? '').toString(),
        author: (b['author'] ?? '').toString(),
        category: (b['category'] ?? '').toString(),
      );
      return bId.compareTo(aId);
    });

    return out;
  }
}

String _fnv1aHex(List<int> bytes) {
  const int fnvPrime = 0x01000193;
  int hash = 0x811c9dc5;
  for (final b in bytes) {
    hash ^= (b & 0xff);
    hash = (hash * fnvPrime) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

