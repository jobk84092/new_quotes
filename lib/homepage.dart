import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:new_quotes/categories.dart';
import 'package:new_quotes/categoryquotes.dart';
import 'package:new_quotes/pages/quotes_list_page.dart';
import 'package:new_quotes/pages/favorites_page.dart';
import 'package:new_quotes/pages/search_page.dart';
import 'package:new_quotes/quoteInfo.dart';
import 'package:new_quotes/utils.dart';
import 'package:new_quotes/widgets/ad_banner.dart';
import 'package:new_quotes/widgets/quote_card.dart';
import 'package:new_quotes/widgets/support_card.dart';
import 'package:new_quotes/theme/app_theme.dart';

class HomePageData {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> quotes;

  HomePageData({required this.categories, required this.quotes});
}

// HomePage - offline mode, loads from bundled JSON.
class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomePageData> _dataFuture;

  @override
  void initState() {
    super.initState();
    // Load images + categories + initial quotes from bundled JSON
    _dataFuture = _loadHomePageData();
  }

  Future<HomePageData> _loadHomePageData() async {
    final categoriesFuture = getCategories();
    final quotesFuture = getQuotes(limit: 100, offset: 0);
    await loadNeutralImages(); // Mutates neutralImages global
    final categories = await categoriesFuture;
    final quotes = await quotesFuture;
    return HomePageData(categories: categories, quotes: quotes);
  }

  @override
  Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
    child: Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo/playstore.png',
                width: 26,
                height: 26,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Daily Quotes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<HomePageData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitThreeBounce(
                color: Colors.purpleAccent,
                size: 50.0,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          } else {
            final data = snapshot.data!;
            final globalQuotes = List<Map<String, dynamic>>.from(data.quotes)..shuffle();
            final top10quotes = globalQuotes
                .where((quote) => (quote['quote']?.length ?? 0) <= 50)
                .take(10)
                .map<Map<String, String>>((quote) {
                  final rawTags = quote['tags'];
                  final tags = rawTags is List ? rawTags.join(', ') : (rawTags?.toString() ?? '');
                  final isPremium = quote['is_premium'];
                  return {
                    'author': quote['author'] ?? 'Unknown Author',
                    'category': quote['category'] ?? 'Uncategorized',
                    'quote': quote['quote'] ?? 'No quote available',
                    'is_premium': isPremium == null ? 'false' : isPremium.toString(),
                    'created_at': _formatCreatedAt(quote['created_at']),
                    'tags': tags,
                  };
                }).toList();

            return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _getSalutation(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SupportCard(),
                      // Quote Of The Day
                      _buildQuoteOfTheDayCard(context, globalQuotes),
                      const SizedBox(height: 8.0),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'All Categories',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoriesPage(initialCategories: data.categories),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.lightBlueAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Categories Row
                      _buildAllCategoriesRow(context, data.categories, globalQuotes),
                      // Top Quotes Section
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Top Quotes',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                  builder: (context) => const QuotesListPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.lightBlueAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Horizontal Slider of Quotes
                      QuotesSlider(
                        quotes: top10quotes,
                      ),
                      // Top Categories Section
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top Categories',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            _buildTopCategoriesCards(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      // Top Categories Section
                      // Vertical List of Quotes
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Quotes Digest",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            _buildTopQuotesList(globalQuotes),
                          ],
                        ),
                      ),
                    ],
                  );
          }
        },
      ),
      bottomNavigationBar: const AdBanner(),
    ),
  );
}


// WIDGET TREE END
  String _formatCreatedAt(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    if (value is String) return value;
    return value.toString();
  }

  String _getSalutation() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  // SALUTATIONS END
  Widget _buildQuoteOfTheDayCard(BuildContext context, List<Map<String, dynamic>> globalQuotes) {
    final picked = globalQuotes.cast<Map<String, dynamic>>().firstWhere(
      (q) => ((q['quote'] ?? '').toString().trim().length) <= 70,
      orElse: () => globalQuotes.isNotEmpty ? globalQuotes.first : <String, dynamic>{},
    );

    final quoteText = (picked['quote'] ?? '').toString().trim();
    final author = (picked['author'] ?? 'Unknown').toString().trim();
    final bg = getRandomNeutralImage(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: QuoteCard(
        quote: quoteText.isEmpty ? 'Welcome to Daily Quotes.' : quoteText,
        author: author.isEmpty ? 'Unknown' : author,
        backgroundImage: bg,
        onTap: quoteText.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuoteInfoPage(
                      quote: {
                        'quote': quoteText,
                        'author': author,
                        'image': bg,
                      },
                    ),
                  ),
                );
              },
        showToolbar: false,
      ),
    );
  }

  // Widget _buildQuoteOfTheDayCard END
  Widget _buildAllCategoriesRow(BuildContext context, List<Map<String, dynamic>> categories, List<Map<String, dynamic>> globalQuotes) {
    // Sort categories by the count of quotes (match by id or name, case-insensitive)
    categories.sort((a, b) {
      String idA = (a['id'] ?? a['name'] ?? '').toString().toLowerCase();
      String idB = (b['id'] ?? b['name'] ?? '').toString().toLowerCase();
      int countA = globalQuotes.where((q) => (q['category'] ?? '').toString().toLowerCase() == idA).length;
      int countB = globalQuotes.where((q) => (q['category'] ?? '').toString().toLowerCase() == idB).length;
      return countB.compareTo(countA);
    });

    // List to store selected random images
    List<String> selectedImages = [];

    // Allocate a random image to each category
    categories.forEach((category) {
      String randomImage;
      do {
        randomImage = getRandomNeutralImage(1);
      } while (selectedImages.contains(randomImage) && selectedImages.length < neutralImages.length);

      selectedImages.add(randomImage);
      category['image'] = randomImage;
      print('Selected image: $randomImage'); // Print the selected image
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: categories.map((category) {
          String categoryId = (category['id'] ?? category['name'] ?? '').toString().toLowerCase();
          List<Map<String, dynamic>> categoryQuotes = globalQuotes.where((q) => (q['category'] ?? '').toString().toLowerCase() == categoryId).toList();
          return _buildAllCategoriesItem(context, category, categoryQuotes);
        }).toList(),
      ),
    );
  }

  // Widget _buildAllCategoriesRow END

  Widget _buildAllCategoriesItem(BuildContext context, Map<String, dynamic> category, List<Map<String, dynamic>> categoryQuotes) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryQuotesPage(
            categoryName: category['name'] ?? 'Unknown Category',
            categoryId: (category['id'] ?? category['name'] ?? '').toString(),
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40.0,
            backgroundImage: category['image'] != null && category['image'].startsWith('http')
                ? NetworkImage(category['image']) as ImageProvider<Object>
                : AssetImage(category['image']) as ImageProvider<Object>,
          ),
          const SizedBox(height: 8.0),
          SizedBox(
            height: 40.0, // Fixed height to ensure consistent size
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cleanCapitalizeAndBreak(category['name'] ?? 'Unknown Category'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  // Widget _buildAllCategoriesItem END
Widget _buildTopQuotesList(List<Map<String, dynamic>> quotes) {
  final shuffled = List<Map<String, dynamic>>.from(quotes)..shuffle();
  shuffled.sort((a, b) => (a['quote']?.length ?? 0).compareTo(b['quote']?.length ?? 0));

  List<Map<String, String>> topQuotes = shuffled.map<Map<String, String>>((quote) {
    return {
      'quote': quote['quote'] ?? 'No quote available',
      'author': quote['author'] ?? 'Unknown Author',
      'image': quote['image'] ?? 'assets/images/topquoteone.png',
    };
  }).toList();

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    // Disable scrolling for the ListView
    itemCount: topQuotes.length,
    itemBuilder: (context, index) {
      return _buildQuoteCard(context, topQuotes[index]);
    },
  );
}

// Widget _buildTopQuotesList END
  Widget _buildTopCategoriesCards() {
    // Replace the placeholders with actual top categories and corresponding images
    List<Map<String, String>> topCategories = [
      {'slug': 'love', 'name': 'Love', 'image': getRandomNeutralImage(1)},
      {'slug': 'motivation', 'name': 'Motivation', 'image': getRandomNeutralImage(1)},
      {'slug': 'wisdom', 'name': 'Wisdom', 'image': getRandomNeutralImage(1)},
      {'slug': 'focus', 'name': 'Focus', 'image': getRandomNeutralImage(1)},
      {'slug': 'inspiration', 'name': 'Inspiration', 'image': getRandomNeutralImage(1)},
      {'slug': 'growth', 'name': 'Growth', 'image': getRandomNeutralImage(1)},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two cards per row
        crossAxisSpacing: 2.0,
      ),
      itemCount: topCategories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () {
          // Navigate to the category quotes page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryQuotesPage(
                categoryName: topCategories[index]['name'] ?? 'Unknown Category',
                categoryId: topCategories[index]['slug'] ?? '',
              ),
            ),
          );
        },
        child: _buildTopCategoryCard(topCategories[index]),
      );
      },
    );
  }

  // Widget _buildTopCategoriesCards END
  Widget _buildTopCategoryCard(Map<String, String> category) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                category['image'] ?? 'assets/images/bg6.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    category['name'] ?? 'Unknown Category',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildTopCategoryCard END
  String _getShortQuote(List<Map<String, dynamic>> globalQuotes) {
    const int maxCharacters = 70;
    String shortQuote = '';

    for (int i = 0; i < globalQuotes.length; i++) {
      if (globalQuotes[i]['quote'].length <= maxCharacters) {
        shortQuote = globalQuotes[i]['quote'];
        break;
      }
    }

    return shortQuote;
  }

  // _getShortQuote END
  String capitalize(String s) {
    return s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
  }


Widget _buildQuoteCard(BuildContext context, Map<String, String> quote) {
  String randomImage = getRandomNeutralImage(1);
  return QuoteCard(
    quote: (quote['quote'] ?? '').toString(),
    author: (quote['author'] ?? '').toString(),
    backgroundImage: randomImage,
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuoteInfoPage(
            quote: {
              ...quote,
              'image': randomImage,
            },
          ),
        ),
      );
    },
  );
}}

class QuotesSlider extends StatefulWidget {
  final List<Map<String, String>> quotes;

  const QuotesSlider({super.key, required this.quotes});

  @override
  _QuotesSliderState createState() => _QuotesSliderState();
}

class _QuotesSliderState extends State<QuotesSlider> {
  @override
  void initState() {
    super.initState();
    // Load the neutral images asynchronously
    loadNeutralImages();
  }



  math.Random random = math.Random();
  String randomNeutralImage = '';
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    randomNeutralImage = neutralImages.isNotEmpty
        ? neutralImages[random.nextInt(neutralImages.length)]
        : 'assets/images/topquoteone.png';

    return Column(
      children: [
        SizedBox(
          height: 200.0,
          child: PageView.builder(
            itemCount: widget.quotes.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QuoteInfoPage(quote: widget.quotes[index]),
                    ),
                  );
                },
                child: _buildQuoteCard(widget.quotes[index]),
              );
            },
          ),
        ),
        DotsIndicator(
          dotsCount: widget.quotes.length,
          position: currentIndex.toDouble(),
          decorator: const DotsDecorator(
            color: Colors.grey, // Inactive color
            activeColor: Colors.blue, // Active color
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(Map<String, String> quote) {
    final q = (quote['quote'] ?? '').toString();
    final a = (quote['author'] ?? '').toString();
    final bg = (quote['image'] ?? randomNeutralImage).toString();

    return QuoteCard(
      quote: q,
      author: a,
      backgroundImage: bg,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuoteInfoPage(
              quote: {
                ...quote,
                'image': bg,
              },
            ),
          ),
        );
      },
      showToolbar: false,
    );
  }
}
