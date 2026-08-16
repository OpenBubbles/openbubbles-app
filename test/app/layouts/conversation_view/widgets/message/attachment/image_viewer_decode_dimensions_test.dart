import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/attachment/image_viewer_decode_dimensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bounds decoded dimensions to the displayed image size', () {
    final dimensions = calculateImageViewerDecodeDimensions(
      maximumDisplayWidth: 200,
      pixelRatio: 3,
      sourceWidth: 4000,
      sourceHeight: 3000,
      aspectRatio: 4 / 3,
    );

    expect(dimensions.width, 300);
    expect(dimensions.height, 225);
  });

  test('uses safe positive fallbacks for missing or invalid metadata', () {
    final dimensions = calculateImageViewerDecodeDimensions(
      maximumDisplayWidth: double.nan,
      pixelRatio: double.infinity,
      sourceWidth: 0,
      sourceHeight: null,
      aspectRatio: 0,
    );

    expect(dimensions.width, 1);
    expect(dimensions.height, 1);
  });

  test('caps large device-scaled decode dimensions', () {
    final dimensions = calculateImageViewerDecodeDimensions(
      maximumDisplayWidth: 4000,
      pixelRatio: 4,
      sourceWidth: 4000,
      sourceHeight: 4000,
      aspectRatio: 1,
    );

    expect(dimensions.width, 1024);
    expect(dimensions.height, 1024);
  });
}
