// quoteInfo.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'utils.dart';

class QuoteInfoPage extends StatelessWidget {
  final Map<String, dynamic> quote;

  const QuoteInfoPage({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildQuoteCard(context, quote),
          ),
          buildToolBar(),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, Map<String, dynamic> quote) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuoteInfoPage(quote: quote),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0),
        height: 250.0,
        child: Card(
          elevation: 2.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
             decoration: BoxDecoration(
                image: DecorationImage(
                  image: quote['image'] != null && quote['image'].startsWith('http')
                      ? NetworkImage(quote['image']) as ImageProvider<Object>
                      : const AssetImage('assets/images/default_image.jpg') as ImageProvider<Object>,
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
                          Text(
                            quote['quote'] ?? 'No quote available',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}