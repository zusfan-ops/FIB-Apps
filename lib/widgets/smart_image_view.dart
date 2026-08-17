import 'dart:convert';
import 'package:flutter/material.dart';

class SmartImageView extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const SmartImageView({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    Widget imageWidget;

    if (cleanUrl.isEmpty) {
      imageWidget = _placeholder();
    } else if (cleanUrl.startsWith('data:') || cleanUrl.contains(';base64,')) {
      // Base64 Data URI (data:image/..., data:application/octet-stream, raw base64)
      try {
        final commaIndex = cleanUrl.indexOf(',');
        final base64Str = commaIndex != -1 
            ? cleanUrl.substring(commaIndex + 1).replaceAll('\n', '').replaceAll('\r', '').trim() 
            : cleanUrl.replaceAll('\n', '').replaceAll('\r', '').trim();
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _placeholder(),
        );
      } catch (_) {
        imageWidget = _placeholder();
      }
    } else {
      // Regular HTTP / HTTPS URL
      imageWidget = Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height ?? 180,
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _placeholder() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 180,
      color: Colors.grey.shade100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
          SizedBox(height: 6),
          Text('Gambar tidak dapat dimuat', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
