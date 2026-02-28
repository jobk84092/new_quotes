// quoteInfo.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:new_quotes/services/platform_media_service.dart';
import 'package:new_quotes/widgets/quote_card.dart';
import 'utils.dart';
import 'package:new_quotes/widgets/ad_banner.dart';

class QuoteInfoPage extends StatefulWidget {
  final Map<String, dynamic> quote;

  const QuoteInfoPage({super.key, required this.quote});

  @override
  State<QuoteInfoPage> createState() => _QuoteInfoPageState();
}

class _QuoteInfoPageState extends State<QuoteInfoPage> {
  Uint8List? _userBgBytes;

  @override
  Widget build(BuildContext context) {
    final quoteText = (widget.quote['quote'] ?? '').toString().trim();
    final author = (widget.quote['author'] ?? 'Unknown').toString().trim();
    final shareText = author.isEmpty || author == 'Unknown'
        ? quoteText
        : '$quoteText\n\n— $author';
    final bg = (widget.quote['image'] ?? '').toString();
    final repaintKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Details'),
        actions: [
          IconButton(
            tooltip: 'Pick background',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () async {
              final bytes = await PlatformMediaService.pickImageBytes();
              if (!mounted) return;
              if (bytes == null || bytes.isEmpty) return;
              setState(() {
                _userBgBytes = bytes;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Background selected')),
              );
            },
          ),
          if (_userBgBytes != null)
            IconButton(
              tooltip: 'Clear background',
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _userBgBytes = null;
                });
              },
            ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              if (quoteText.isEmpty) return;
              await Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied')),
              );
            },
          ),
          IconButton(
            tooltip: 'Share text',
            icon: const Icon(Icons.share),
            onPressed: () {
              if (quoteText.isEmpty) return;
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied — paste to share')),
              );
            },
          ),
          IconButton(
            tooltip: 'Share image',
            icon: const Icon(Icons.image_outlined),
            onPressed: () async {
              if (quoteText.isEmpty) return;
              final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
              if (boundary == null) return;
              final image = await boundary.toImage(pixelRatio: 3);
              final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
              final pngBytes = byteData?.buffer.asUint8List();
              if (pngBytes == null || pngBytes.isEmpty) return;
              final ok = await PlatformMediaService.sharePngBytes(
                pngBytes,
                filename: 'quote.png',
              );
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share failed')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: repaintKey,
                child: SizedBox(
                  width: double.infinity,
                  child: QuoteCard(
                    quote: quoteText,
                    author: author,
                    backgroundImage: bg,
                    backgroundBytes: _userBgBytes,
                    onTap: null,
                    showToolbar: false,
                  ),
                ),
              ),
            ),
          ),
          buildToolBar(),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }
}