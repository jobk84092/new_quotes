import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformMediaService {
  static const MethodChannel _channel = MethodChannel('new_quotes/media');

  static Future<Uint8List?> pickImageBytes() async {
    if (kIsWeb) return null;
    final bytes = await _channel.invokeMethod<Uint8List>('pickImageBytes');
    return bytes;
  }

  static Future<bool> shareText(String text) async {
    if (kIsWeb) return false;
    final ok = await _channel.invokeMethod<bool>('shareText', {'text': text});
    return ok ?? false;
  }

  static Future<bool> sharePngBytes(Uint8List bytes, {String filename = 'quote.png'}) async {
    if (kIsWeb) return false;
    final ok = await _channel.invokeMethod<bool>('sharePngBytes', {
      'bytes': bytes,
      'filename': filename,
    });
    return ok ?? false;
  }
}

