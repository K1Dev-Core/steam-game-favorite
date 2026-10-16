import 'dart:convert';

import 'package:flutter/material.dart';

class GameArtwork extends StatelessWidget {
  const GameArtwork({
    super.key,
    required this.source,
    required this.placeholder,
    this.fit = BoxFit.cover,
  });

  final String source;
  final Widget placeholder;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? image;
    try {
      if (source.startsWith('data:image/')) {
        final separator = source.indexOf(',');
        if (separator < 0) return placeholder;
        image = MemoryImage(base64Decode(source.substring(separator + 1)));
      } else {
        final uri = Uri.tryParse(source);
        if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
          image = NetworkImage(source);
        }
      }
    } catch (_) {
      return placeholder;
    }
    if (image == null) return placeholder;
    return Image(
      image: image,
      fit: fit,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
