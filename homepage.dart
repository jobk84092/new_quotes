import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'categories.dart';
import 'categoryquotes.dart';
import 'quotes.dart';
import 'quoteInfo.dart';
import 'utils.dart';


List<Map<String, String>> top10quotes = [];
// Define a global variable to store the quotes
List<Map<String, dynamic>> globalQuotes = [];
// Function to fetch quotes and store them in the global variable
Future<void> fetchAndStoreQuotes() async {
  globalQuotes = await getQuotes();
}

// HomePage Stateless Widget START
class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late Future<void> _loadImagesFuture;

  @override
  void initState() {
    super.initState();
    _loadImagesFuture = loadNeutralImages();
    fetchAndStoreQuotes();
  }


  // ToDO Delete this dummy data
  List<Map<String, String>> quo = [
    {
      'quote': 'Quote 1',
      'author': 'Author 1',
      'image': 'assets/images/bg4.jpg'
    },
    {
      'quote': 'Quote 2',
      'author': 'Author 2',
      'image': 'assets/images/bg2.jpg'
    },
    {
      'quote': 'Quote 2',
      'author': 'Author 2',
      'image': 'assets/images/bg5.jpg'
    },
    {
      'quote': 'Quote 2',
      'author': 'Author 2',
      'image': 'assets/images/bg7.jpg'
    },
    {
      'quote': 'Quote 2',
      'author': 'Author 2',
      'image': 'assets/images/bg3.jpg'
    },
    {
      'quote': 'Quote 2',
      'author': 'Author 2',
      'image': 'assets/images/bg6.jpg'
    },
    // Add more quotes as needed
  ];

  @override
  Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Colors.blue, Colors.pink],
      ),
    ),
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inspirational & Motivational Quotes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _loadImagesFuture,
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
          } else {
            return FutureBuilder<List<List<Map<String, dynamic>>>>(
              future: Future.wait([getCategories(), getQuotes()]),
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
                } else {

                  // Convert the dynamic list to a list of type Map<String, String>
               globalQuotes.shuffle();

                List<Map<String, String>> top10quotes = globalQuotes
                  .where((quote) => (quote['quote']?.length ?? 0) <= 50)
                  .take(10)
                  .map<Map<String, String>>((quote) {
                    String tags = (quote['tags'] as List<dynamic>?)?.join(', ') ?? '';

                    Map<String, String> formattedQuote = {
                      'author': quote['author'] ?? 'Unknown Author',
                      'category': quote['category'] ?? 'Uncategorized',
                      'quote': quote['quote'] ?? 'No quote available',
                      'is_premium': quote['is_premium'].toString() ?? 'false',
                      'created_at': quote['created_at']?.toString() ?? '',
                      'tags': tags,
                    };

                    print(formattedQuote);

                    return formattedQuote;
                  }).toList();
                  // Print the quotes to the console
                  for (var quote in quotes) {
                    print('Quote---------: $quote');
                  }

                  for (var category in categories) {
                    print('category---------: $category');
                  }

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
                                  // Navigate to the CategoriesPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoriesPage(categories: categories, quotes: globalQuotes),
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
                      _buildAllCategoriesRow(context, categories, globalQuotes),
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
                                // Navigate to the QuotesPage

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
                                    future: getQuotes(),
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
                                        List<Map<String, String>> quotes = snapshot.data!.map((quote) => quote.cast<String, String>()).toList();
                                        quotes.shuffle(); // Shuffle the quotes
                                        return QuotesPage(quotes: quotes, backgroundImages: neutralImages);
                                      }
                                    },
                                  ),
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
                            _buildTopQuotesList(),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            );
          }
        },
      ),
    ),
  );
}


// WIDGET TREE END
  String _getSalutation() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Eveninggg,';
    }
  }

  // SALUTATIONS END
  Widget _buildQuoteOfTheDayCard(BuildContext context, List<Map<String, dynamic>> globalQuotes) {
    final math.Random random = math.Random();
    final int randomImageIndex = random.nextInt(18) + 1;

    final String backgroundImagePath =
        'assets/images/backgrounds/qotd/qotd$randomImageIndex.jpg';

    String shortQuote = _getShortQuote(globalQuotes);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImagePath),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Card(
            elevation: 0,
            color: Colors.black.withOpacity(0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
              height: 200.0,
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          shortQuote,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 2.0,
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -6.0),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: const Icon(
                                  Icons.format_quote,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              '- ${shortQuote.isNotEmpty ? globalQuotes.firstWhere((quote) => quote['quote'] == shortQuote)['author'] : 'Unknown Author'}',
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildQuoteOfTheDayCard END
  Widget _buildAllCategoriesRow(BuildContext context, List<Map<String, dynamic>> categories, List<Map<String, dynamic>> globalQuotes) {
    // Sort categories by the count of quotes
    categories.sort((a, b) {
      String categoryA = a['name'] ?? '';
      String categoryB = b['name'] ?? '';

      int countA = globalQuotes.where((quote) => (quote['category'] == categoryA)).length;
      int countB = globalQuotes.where((quote) => (quote['category'] == categoryB)).length;

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
          String categoryName = category['name'] ?? 'Unknown Category';

          // Filter globalQuotes based on categoryName
          List<Map<String, dynamic>> categoryQuotes = globalQuotes.where((quote) => (quote['category'] == categoryName)).toList();

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
            categoryQuotes: getCategoryQuotes(category['name'] ?? 'Unknown Category'),
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
Widget _buildTopQuotesList() {
  // Shuffle the globalQuotes list twice to randomize
  globalQuotes.shuffle();
  globalQuotes.shuffle();

  // Sort the quotes by the length of the 'quote' field to ensure short to medium length quotes are first
  globalQuotes.sort((a, b) => (a['quote']?.length ?? 0).compareTo(b['quote']?.length ?? 0));

  // Convert the dynamic list to a list of type Map<String, String>
  List<Map<String, String>> topQuotes = globalQuotes.map<Map<String, String>>((quote) {
    return {
      'quote': quote['quote'] ?? 'No quote available',
      'author': quote['author'] ?? 'Unknown Author',
      'image': quote['image'] ?? 'assets/images/default_image.jpg',
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
      {'slug': 'wisdom', 'name': 'Wisdom', 'image': 'assets/images/backgrounds/top_categories/wisdom.jpg'},
      {'slug': 'life', 'name': 'Life', 'image': 'assets/images/backgrounds/top_categories/life.jpg'},
      {'slug': 'love', 'name': 'Love', 'image': 'assets/images/backgrounds/top_categories/love.jpg'},
      {'slug': 'inspiration', 'name': 'Inspiration', 'image': 'assets/images/bg4.jpg'},
      {'slug': 'humor', 'name': 'Humor', 'image': 'assets/images/backgrounds/top_categories/humor.jpg'},
      {'slug': 'hope', 'name': 'Hope', 'image': 'assets/images/backgrounds/top_categories/hope.jpg'},
      {'slug': 'success', 'name': 'Success', 'image': 'assets/images/backgrounds/top_categories/lion.jpg'},
      {'slug': 'philosophy', 'name': 'Philosophy', 'image': 'assets/images/backgrounds/top_categories/philosophy.jpg'},
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
                categoryQuotes: getCategoryQuotes(topCategories[index]['slug'] ?? ''),
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.blueGrey,
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
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuoteInfoPage(  quote: {
            ...quote,
            'image': randomImage,
          },
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
                    image: randomImage.startsWith('http')
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
}}

class QuotesSlider extends StatefulWidget {
  final List<Map<String, String>> quotes;

  const QuotesSlider({super.key, required this.quotes});

  @override
  _QuotesSliderState createState() => _QuotesSliderState();
}

class _QuotesSliderState extends State<QuotesSlider> {
  List<String> neutralImages = [];

  @override
  void initState() {
    super.initState();
    // Load the neutral images asynchronously
    loadNeutralImages();
  }



  // Randomly select an image from neutralImages
  math.Random random = math.Random();
  String randomNeutralImage = '';
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    randomNeutralImage = neutralImages.isNotEmpty
        ? neutralImages[random.nextInt(neutralImages.length)]
        : 'assets/images/topquoteone.jpg';

    print('randomNeutralImage: ---------- $randomNeutralImage');

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
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0), // Adjust the radius as needed
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: (quote['image'] != null && quote['image']!.startsWith('http'))
                    ? NetworkImage(quote['image']!) as ImageProvider<Object>
                    : AssetImage(quote['image'] ?? randomNeutralImage) as ImageProvider<Object>,
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
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 2.0,
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -6.0),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: const Icon(
                                  Icons.format_quote,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              '- ${quote['author'] ?? 'Unknown Author'}',
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
    );
  }
}
