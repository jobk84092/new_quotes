import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'quoteInfo.dart';
import 'dart:math' as math;
import 'utils.dart';
import 'package:dots_indicator/dots_indicator.dart';

class CategoryQuotesPage extends StatelessWidget {
  final String categoryName;
  final Future<List<Map<String, dynamic>>> categoryQuotes;

  CategoryQuotesPage({super.key, required String categoryName, required this.categoryQuotes})
      : categoryName = 'Viewing ${cleanCapitalizeAndBreak(categoryName)} Quotes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: categoryQuotes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: DotsIndicator(
                dotsCount: 3, // Example count for loading state
                position: 1.0, // Example position for loading state
                decorator: const DotsDecorator(
                  color: Colors.grey, // Inactive color
                  activeColor: Colors.blue, // Active color
                ),
              ),
            );

          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No quotes available'));
          } else {
              return FutureBuilder<List<String>>(
                future: fetchNeutralImages(),
                builder: (context, imageSnapshot) {
                  if (imageSnapshot.connectionState == ConnectionState.waiting) {
                    // return const Center(child: CircularProgressIndicator());
                    return Center(
                      child: DotsIndicator(
                        dotsCount: 3, // Example count for loading state
                        position: 1.0, // Example position for loading state
                        decorator: const DotsDecorator(
                          color: Colors.grey, // Inactive color
                          activeColor: Colors.blue, // Active color
                        ),
                      ),
                    );
                  } else if (imageSnapshot.hasError) {
                    return Center(child: Text('Error: ${imageSnapshot.error}'));
                  } else {
                    List<String> neutralImages = imageSnapshot.data!;
                    List<Map<String, dynamic>> quotes = snapshot.data!;

                    // Assign random neutral images to quotes without images
                    math.Random random = math.Random();
                    for (var quote in quotes) {
                      if (quote['image'] == null || quote['image'].isEmpty) {
                        quote['image'] = neutralImages[random.nextInt(neutralImages.length)];
                      }
                    }

                    return _buildCategoryQuotesList(quotes);
                  }
                },
              );
          }
        },
      ),
    );
  }

  // Future<List<String>> loadNeutralImages() async {
  //   const folderPath = 'assets/images/backgrounds/neutrals/';
  //   final List<String> imagePaths = <String>[];
  //
  //   try {
  //     final manifestContent = await rootBundle.loadString('AssetManifest.json');
  //     final Map<String, dynamic> manifestMap = json.decode(manifestContent);
  //
  //     for (final String key in manifestMap.keys) {
  //       if (key.startsWith(folderPath)) {
  //         imagePaths.add(key);
  //       }
  //     }
  //   } catch (e) {
  //     print('Error loading neutral images: $e');
  //   }
  //
  //   return imagePaths;
  // }

  Widget _buildCategoryQuotesList(List<Map<String, dynamic>> quotes) {
    return ListView.builder(
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        return _buildQuoteCard(context, quotes[index]);
      },
    );
  }

  Widget _buildQuoteCard(BuildContext context, Map<String, dynamic> quote) {
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 150.0), // Set minimum height
                  decoration: BoxDecoration(
                    image: DecorationImage(
                   image: (quote['image'] != null && quote['image']!.startsWith('http'))
                          ? NetworkImage(quote['image']!) as ImageProvider<Object>
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
                _buildToolBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolBar() {
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