import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:new_quotes/utils.dart';

class QuoteCard extends StatelessWidget {
  final String quote;
  final String author;
  final String? backgroundImage;
  final Uint8List? backgroundBytes;
  final VoidCallback? onTap;
  final bool showToolbar;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.author,
    this.backgroundImage,
    this.backgroundBytes,
    this.onTap,
    this.showToolbar = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = (backgroundImage ?? '').trim().isEmpty
        ? 'assets/images/topquoteone.png'
        : backgroundImage!.trim();

    final quoteText = quote.trim().isEmpty ? 'No quote available' : quote.trim();
    final authorText = author.trim().isEmpty ? 'Unknown' : author.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Card(
          elevation: 2.0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (backgroundBytes != null && backgroundBytes!.isNotEmpty)
                      Image.memory(
                        backgroundBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(color: Colors.black12);
                        },
                      )
                    else if (bg.startsWith('http'))
                      Image.network(
                        bg,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(color: Colors.black12);
                        },
                      )
                    else
                      Image.asset(
                        bg,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(color: Colors.black12);
                        },
                      ),
                    // Contrast overlay for readability (no blur; keeps text crisp)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x66000000),
                            Color(0x99000000),
                            Color(0xCC000000),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            quoteText,
                            textAlign: TextAlign.center,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ) ??
                                const TextStyle(
                                  fontSize: 20,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '— $authorText',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ) ??
                                const TextStyle(
                                  fontSize: 14,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showToolbar) buildToolBar(),
            ],
          ),
        ),
      ),
    );
  }
}

