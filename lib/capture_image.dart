import 'dart:typed_data';
import 'package:flutter/material.dart';

/// CameraX rotation describes the raw JPEG pixels. Flutter also honors EXIF,
/// so remove EXIF only from the in-memory display copy before rotating once.
/// The original bytes, compressed pixels, OCR input and stored record are intact.
Uint8List jpegPixelsForDisplay(Uint8List original) {
  if (original.length < 4 || original[0] != 0xff || original[1] != 0xd8) {
    return original;
  }
  final skipped = <(int, int)>[];
  var cursor = 2;
  while (cursor < original.length) {
    final start = cursor;
    if (original[cursor] != 0xff) return original;
    while (cursor < original.length && original[cursor] == 0xff) {
      cursor++;
    }
    if (cursor >= original.length) return original;
    final marker = original[cursor++];
    // The remaining scan data is copied verbatim, never parsed as metadata.
    if (marker == 0xda || marker == 0xd9) break;
    if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (cursor + 2 > original.length) return original;
    final length = (original[cursor] << 8) | original[cursor + 1];
    final end = cursor + length;
    if (length < 2 || end > original.length) return original;
    final payload = cursor + 2;
    if (marker == 0xe1 &&
        length >= 8 &&
        original[payload] == 0x45 &&
        original[payload + 1] == 0x78 &&
        original[payload + 2] == 0x69 &&
        original[payload + 3] == 0x66 &&
        original[payload + 4] == 0 &&
        original[payload + 5] == 0) {
      skipped.add((start, end));
    }
    cursor = end;
  }
  if (skipped.isEmpty) return original;
  final display = BytesBuilder(copy: false);
  var copiedThrough = 0;
  for (final (start, end) in skipped) {
    display.add(Uint8List.sublistView(original, copiedThrough, start));
    copiedThrough = end;
  }
  display.add(Uint8List.sublistView(original, copiedThrough));
  return display.takeBytes();
}

class OriginalCaptureImage extends StatelessWidget {
  const OriginalCaptureImage({
    super.key,
    required this.bytes,
    required this.rotation,
  });
  final Uint8List bytes;
  final int rotation;

  @override
  Widget build(BuildContext context) => RotatedBox(
    quarterTurns: rotation ~/ 90,
    child: Image.memory(jpegPixelsForDisplay(bytes), fit: BoxFit.contain),
  );
}
