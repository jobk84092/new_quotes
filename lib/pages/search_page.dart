import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_quotes/quoteInfo.dart';
import 'package:new_quotes/utils.dart';
import 'package:new_quotes/widgets/ad_banner.dart';
import 'package:new_quotes/widgets/quote_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String _query = '';
  List<Map<String, dynamic>> _results = const [];

  @override
  void initState() {
    super.initState();
    loadNeutralImages();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String raw) async {
    final q = raw.trim();
    setState(() {
      _query = q;
      _loading = true;
    });

    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }

    // Use visible quotes only (free users don't see premium quotes).
    final all = await getQuotes(limit: freeQuotesCap, offset: 0);
    final needle = q.toLowerCase();

    final matches = <Map<String, dynamic>>[];
    for (final item in all) {
      final text = (item['quote'] ?? '').toString();
      final author = (item['author'] ?? '').toString();
      if (text.toLowerCase().contains(needle) || author.toLowerCase().contains(needle)) {
        matches.add(item);
        if (matches.length >= 120) break; // keep UI snappy
      }
    }

    if (!mounted) return;
    setState(() {
      _results = matches;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search quotes or authors…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _runSearch('');
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_query.isEmpty) {
      return const Center(child: Text('Type to search'));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No matches found'));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final q = _results[index];
        final bg = getRandomNeutralImage(1);
        final quoteText = (q['quote'] ?? '').toString();
        final author = (q['author'] ?? 'Unknown').toString();
        return QuoteCard(
          quote: quoteText,
          author: author,
          backgroundImage: bg,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuoteInfoPage(
                  quote: {
                    ...q,
                    'image': bg,
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

