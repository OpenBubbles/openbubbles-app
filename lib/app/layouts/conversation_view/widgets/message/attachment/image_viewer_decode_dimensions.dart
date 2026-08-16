import 'dart:math';

class ImageViewerDecodeDimensions {
  const ImageViewerDecodeDimensions(
      {required this.width, required this.height});

  final int width;
  final int height;
}

ImageViewerDecodeDimensions calculateImageViewerDecodeDimensions({
  required double maximumDisplayWidth,
  required double pixelRatio,
  required int? sourceWidth,
  required int? sourceHeight,
  required double aspectRatio,
}) {
  final safeMaximumDisplayWidth =
      maximumDisplayWidth.isFinite && maximumDisplayWidth > 0
          ? maximumDisplayWidth
          : 1.0;
  final safePixelRatio =
      pixelRatio.isFinite && pixelRatio > 0 ? pixelRatio : 1.0;
  final safeAspectRatio =
      aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1.0;
  final displayWidth = min(
    sourceWidth != null && sourceWidth > 0
        ? sourceWidth.toDouble()
        : safeMaximumDisplayWidth,
    safeMaximumDisplayWidth,
  );
  final fallbackHeight = safeMaximumDisplayWidth / safeAspectRatio;
  final displayHeight = min(
    sourceHeight != null && sourceHeight > 0
        ? sourceHeight.toDouble()
        : fallbackHeight,
    fallbackHeight,
  );

  int cacheDimension(double displayDimension) =>
      (displayDimension * safePixelRatio / 2).round().clamp(1, 1024).toInt();

  return ImageViewerDecodeDimensions(
    width: cacheDimension(displayWidth),
    height: cacheDimension(displayHeight),
  );
}
