import 'package:flutter/material.dart';
import 'package:new_quotes/quoteInfo.dart';
import 'package:new_quotes/services/favorites_service.dart';
import 'package:new_quotes/utils.dart';
import 'package:new_quotes/widgets/ad_banner.dart';
import 'package:new_quotes/widgets/quote_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    loadNeutralImages();
    _future = FavoritesService.instance.loadFavorites();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = FavoritesService.instance.loadFavorites();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return const Center(child: Text('No favorites yet'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final q = items[index];
              final quoteText = (q['quote'] ?? '').toString();
              final author = (q['author'] ?? 'Unknown').toString();
              final category = (q['category'] ?? '').toString();
              final bg = getRandomNeutralImage(1);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Stack(
                  children: [
                    QuoteCard(
                      quote: quoteText,
                      author: author,
                      backgroundImage: bg,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuoteInfoPage(
                              quote: {
                                'quote': quoteText,
                                'author': author,
                                'category': category,
                                'image': bg,
                                'tags': q['tags'],
                                'created_at': q['created_at'],
                                'is_premium': q['is_premium'],
                              },
                            ),
                          ),
                        );
                      },
                      showToolbar: false,
                    ),
                    Positioned(
                      top: 10,
                      right: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: IconButton(
                          tooltip: 'Remove favorite',
                          icon: const Icon(Icons.favorite, color: Colors.white),
                          onPressed: () async {
                            await FavoritesService.instance.toggleFavorite(q);
                            if (!mounted) return;
                            await _refresh();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }
}

