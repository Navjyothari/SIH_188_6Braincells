import 'package:flutter/services.dart';

class DeviceBridge {
  static const channel = MethodChannel('fictional_screen/device');
  Future<Map<String, dynamic>?> capture() =>
      channel.invokeMapMethod<String, dynamic>('capture');
  Future<Map<String, dynamic>> recognize(Uint8List bytes, int rotation) async =>
      (await channel.invokeMapMethod<String, dynamic>('recognize', {
        'bytes': bytes,
        'rotation': rotation,
      }))!;
  Future<String> save(String envelope) async =>
      (await channel.invokeMethod<String>('save', {'envelope': envelope}))!;
  Future<List<String>> list() async =>
      (await channel.invokeListMethod<String>('list'))!;
  Future<String> load(String id) async =>
      (await channel.invokeMethod<String>('load', {'id': id}))!;
}
