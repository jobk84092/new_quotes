import 'package:flutter/material.dart';
import 'categoryquotes.dart';
import 'utils.dart';

class CategoriesPage extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> quotes;

  const CategoriesPage({super.key, required this.categories, required this.quotes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Quote Categories'),
      ),
      body: _buildCategoriesGridView(context),
    );
  }

  Widget _buildCategoriesGridView(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(context, categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    // Filter quotes by category name to get its quotes batch
    List<Map<String, dynamic>> categoryQuotesForThisCategory = quotes.where((quote) {
      return quote['category'] == category['name'];
    }).toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryQuotesPage(
              categoryName: category['name'] ?? 'Unknown Category',
              categoryQuotes: getCategoryQuotes(category['name']),
            ),
          ),
        );
      }, // onTap
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             Expanded(
                child: Image(
                  image: (category['image'] != null && category['image']!.startsWith('http'))
                      ? NetworkImage(category['image']!) as ImageProvider<Object>
                      : AssetImage(category['image'] ?? 'assets/images/default_image.jpg') as ImageProvider<Object>,
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
                      cleanCapitalizeAndBreak(category['name'] ?? 'Unknown Category'),
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}