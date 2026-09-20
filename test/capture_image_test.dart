import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fictional_screen/capture_image.dart';

void main() {
  test('unrelated JPEG metadata survives the display-only EXIF removal', () {
    final tagged = File(
      'test/fixtures/orientation/exif-180.jpg',
    ).readAsBytesSync();
    final raw = File('test/fixtures/orientation/raw-180.jpg').readAsBytesSync();
    // A separate APP1 segment, deliberately not an EXIF payload.
    const otherMetadata = [0xff, 0xe1, 0, 8, 88, 77, 80, 0, 0, 0];
    final combined = Uint8List.fromList([
      ...tagged.take(2),
      ...otherMetadata,
      ...tagged.skip(2),
    ]);
    expect(jpegPixelsForDisplay(combined), [
      ...raw.take(2),
      ...otherMetadata,
      ...raw.skip(2),
    ]);
  });
  for (final rotation in [0, 90, 180, 270]) {
    final tagged = File(
      'test/fixtures/orientation/exif-$rotation.jpg',
    ).readAsBytesSync();
    final raw = File(
      'test/fixtures/orientation/raw-$rotation.jpg',
    ).readAsBytesSync();
    test(
      'preview retains exact JPEG pixels and original bytes at $rotation degrees',
      () {
        final before = Uint8List.fromList(tagged);
        expect(jpegPixelsForDisplay(tagged), raw);
        expect(tagged, before);
        expect(identical(jpegPixelsForDisplay(raw), raw), isTrue);
      },
    );

    for (final withExif in [true, false]) {
      testWidgets('render upright at $rotation degrees, EXIF=$withExif', (
        tester,
      ) async {
        final bytes = withExif ? tagged : raw;
        final key = GlobalKey();
        await tester.runAsync(() async {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 120,
                    height: 80,
                    child: OriginalCaptureImage(
                      bytes: bytes,
                      rotation: rotation,
                    ),
                  ),
                ),
              ),
            ),
          );
          await precacheImage(
            MemoryImage(jpegPixelsForDisplay(bytes)),
            key.currentContext!,
          );
        });
        await tester.pumpAndSettle();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final rendered = await tester.runAsync(
          () => boundary.toImage(pixelRatio: 1),
        );
        final pixels = await tester.runAsync(
          () => rendered!.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        final expected = [
          (20, 20, [255, 0, 0]),
          (100, 20, [0, 255, 0]),
          (20, 60, [0, 0, 255]),
          (100, 60, [255, 255, 0]),
        ];
        for (final (x, y, color) in expected) {
          final offset = (y * 120 + x) * 4;
          for (var channel = 0; channel < 3; channel++) {
            expect(
              pixels!.getUint8(offset + channel),
              closeTo(color[channel], 5),
              reason: 'Corner ($x,$y) must remain upright',
            );
          }
        }
        rendered!.dispose();
      });
    }
  }
  test('non-JPEG and truncated JPEG bytes are not rewritten', () {
    for (final value in [
      <int>[],
      [0x89, 0x50, 0x4e, 0x47],
      [0xff, 0xd8, 0xff, 0xe1, 0xff, 0xff],
      [0xff, 0xd8, 0xff, 0xe1],
    ]) {
      final bytes = Uint8List.fromList(value);
      expect(identical(jpegPixelsForDisplay(bytes), bytes), isTrue);
    }
  });
}
