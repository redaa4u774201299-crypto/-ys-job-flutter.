import 'dart:typed_data';
import 'dart:math' as math;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ImageCropDialog extends StatefulWidget {
  const ImageCropDialog({
    required this.imageBytes,
    required this.imageLabel,
    super.key,
  });

  final Uint8List imageBytes;
  final String imageLabel;

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final CropController _cropController = CropController();
  var _isCropping = false;
  String? _errorMessage;

  void _startCropping() {
    setState(() {
      _isCropping = true;
      _errorMessage = null;
    });
    _cropController.crop();
  }

  void _handleCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure(:final cause):
        setState(() {
          _isCropping = false;
          _errorMessage =
              'تعذر قص الصورة. حاول مرة أخرى. (${cause.toString()})';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final cropSize = math.min(
      math.min(screenSize.width - 80, 460.0),
      math.max(220.0, screenSize.height - 280),
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          const Icon(Icons.crop_rounded, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(child: Text('قص ${widget.imageLabel}')),
        ],
      ),
      content: SizedBox(
        width: cropSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'حرّك الصورة أو كبّرها ثم اختر الجزء المربع المناسب.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: cropSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _cropController,
                  aspectRatio: 1,
                  interactive: true,
                  initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                    size: 0.82,
                    aspectRatio: 1,
                  ),
                  maskColor: AppColors.navy.withValues(alpha: 0.68),
                  baseColor: AppColors.beige,
                  radius: 12,
                  progressIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  onCropped: _handleCropped,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.red.shade700),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCropping
              ? null
              : () => Navigator.of(context).pop<Uint8List>(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _isCropping ? null : _startCropping,
          icon: _isCropping
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_isCropping ? 'جارٍ القص…' : 'قص وحفظ'),
        ),
      ],
    );
  }
}
