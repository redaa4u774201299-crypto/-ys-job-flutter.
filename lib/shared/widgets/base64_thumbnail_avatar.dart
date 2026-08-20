import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class Base64ThumbnailAvatar extends StatefulWidget {
  const Base64ThumbnailAvatar({
    super.key,
    required this.encoded,
    required this.fallbackLabel,
    this.radius = 25,
    this.fallbackIcon = Icons.person_outline,
  });

  final String encoded;
  final String fallbackLabel;
  final double radius;
  final IconData fallbackIcon;

  static Uint8List? decode(String encoded) {
    if (encoded.trim().isEmpty) return null;
    try {
      final bytes = base64Decode(encoded);
      return bytes.isEmpty ? null : bytes;
    } on FormatException {
      return null;
    }
  }

  static int cacheDimension({
    required double radius,
    required double devicePixelRatio,
  }) => (radius * 2 * devicePixelRatio).ceil();

  static int decodedRgbaByteBudget({
    required double radius,
    required double devicePixelRatio,
  }) {
    final dimension = cacheDimension(
      radius: radius,
      devicePixelRatio: devicePixelRatio,
    );
    return dimension * dimension * 4;
  }

  @override
  State<Base64ThumbnailAvatar> createState() => _Base64ThumbnailAvatarState();
}

class _Base64ThumbnailAvatarState extends State<Base64ThumbnailAvatar> {
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    _decodedBytes = Base64ThumbnailAvatar.decode(widget.encoded);
  }

  @override
  void didUpdateWidget(covariant Base64ThumbnailAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.encoded != widget.encoded) {
      _decodedBytes = Base64ThumbnailAvatar.decode(widget.encoded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacheDimension = Base64ThumbnailAvatar.cacheDimension(
      radius: widget.radius,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    final fallbackInitial = widget.fallbackLabel.trim().isEmpty
        ? null
        : widget.fallbackLabel.trim().characters.first.toUpperCase();
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.beige,
      foregroundColor: AppColors.navy,
      child: _decodedBytes == null
          ? (fallbackInitial == null
                ? Icon(widget.fallbackIcon)
                : Text(
                    fallbackInitial,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ))
          : ClipOval(
              child: Image.memory(
                _decodedBytes!,
                width: widget.radius * 2,
                height: widget.radius * 2,
                cacheWidth: cacheDimension,
                cacheHeight: cacheDimension,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
    );
  }
}
