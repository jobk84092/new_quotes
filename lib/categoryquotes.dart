import 'dart:ui';

import 'package:flutter/material.dart';
import 'quoteInfo.dart';
import 'utils.dart';
import 'package:new_quotes/widgets/ad_banner.dart';
import 'package:new_quotes/widgets/quote_card.dart';

class CategoryQuotesPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryQuotesPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryQuotesPage> createState() => _CategoryQuotesPageState();
}

class _CategoryQuotesPageState extends State<CategoryQuotesPage> {
  static const int _pageSize = 50;
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _quotes = [];

  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    loadNeutralImages();
    _loadNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final page = await getCategoryQuotes(
        widget.categoryId,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _quotes.addAll(page);
        _offset += page.length;
        _hasMore = page.length == _pageSize;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Viewing ${cleanCapitalizeAndBreak(widget.categoryName)} Quotes';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(),
      bottomNavigationBar: const AdBanner(),
    );
  }

  Widget _buildBody() {
    if (_quotes.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_quotes.isEmpty && _error != null) {
      return _buildErrorState();
    }
    if (_quotes.isEmpty && !_hasMore) {
      return const Center(child: Text('No quotes available'));
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _quotes.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _quotes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildQuoteCard(context, _quotes[index]);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $_error'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadNextPage,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, Map<String, dynamic> quote) {
    final randomImage = getRandomNeutralImage(1);
    final quoteWithImage = {
      ...quote,
      'image': randomImage,
    };
    return QuoteCard(
      quote: (quote['quote'] ?? '').toString(),
      author: (quote['author'] ?? '').toString(),
      backgroundImage: randomImage,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuoteInfoPage(quote: quoteWithImage),
          ),
        );
      },
    );
  }
}