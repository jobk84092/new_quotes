// lib/quotes.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:new_quotes/quoteInfo.dart';
import 'utils.dart';

class QuotesPage extends StatelessWidget {
  final List<Map<String, String>> quotes;
  final List<String> backgroundImages;

  const QuotesPage({super.key, required this.quotes, required this.backgroundImages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Quotes'),
      ),
      body: _buildQuotesList(context),
    );
  }

  Widget _buildQuotesList(BuildContext context) {
    return ListView.builder(
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        return _buildQuoteCard(quotes[index], context);
      },
    );
  }

  Widget _buildQuoteCard(Map<String, String> quote, BuildContext context) {
    String randomImage = backgroundImages[math.Random().nextInt(backgroundImages.length)];
    quote['image'] = randomImage; // Append the selected randomImage to the quote object
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuoteInfoPage(
              quote: quote,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Card(
          elevation: 2.0,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 150.0), // Set minimum height
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: (randomImage.startsWith('http'))
                          ? NetworkImage(randomImage) as ImageProvider<Object>
                          : AssetImage(randomImage) as ImageProvider<Object>,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Text(
                                    quote['quote'] ?? 'No quote available',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '- ${quote['author'] ?? 'Unknown Author'}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              buildToolBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildToolBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal margins
        width: double.infinity,
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.photo),
              onPressed: () {
                // Add functionality for changing background photo
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_align_left),
              onPressed: () {
                // Add functionality for formatting text
              },
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () {
                // Add functionality for downloading quote
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmark),
              onPressed: () {
                // Add functionality for bookmarking quote
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Add functionality for sharing to socials
              },
            ),
          ],
        ),
      ),
    );
  }
}