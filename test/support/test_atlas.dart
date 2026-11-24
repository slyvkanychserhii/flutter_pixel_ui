import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

/// Описание тестового атласа. Картинка 32x16, рисует [testAtlasPng]:
///
///     half  (0, 0, 8, 8)   непрозрачна только левая половина (x 0..3)
///     wide  (0, 8, 6, 2)   непрозрачна целиком, не квадрат (для поворота)
///     full  (16, 0, 8, 8)  непрозрачна целиком
///     ga    (8, 0, 3, 5)   глиф "A", непрозрачный
///     gs    (12, 0, 2, 5)  глиф пробела, прозрачный
///
/// Шрифт "f": высота строки 5, зазор 1. Анимации: "anim" (зациклена) и
/// "once" (один раз): кадры half, full, 2 кадра в секунду.
const Map<String, Object?> testAtlasJson = {
  'image': 't.png',
  'frames': {
    'half': {'x': 0, 'y': 0, 'w': 8, 'h': 8},
    'wide': {'x': 0, 'y': 8, 'w': 6, 'h': 2},
    'full': {'x': 16, 'y': 0, 'w': 8, 'h': 8},
    'ga': {'x': 8, 'y': 0, 'w': 3, 'h': 5},
    'gs': {'x': 12, 'y': 0, 'w': 2, 'h': 5},
  },
  'animations': {
    'anim': {
      'frames': ['half', 'full'],
      'fps': 2,
      'loop': true,
    },
    'once': {
      'frames': ['half', 'full'],
      'fps': 2,
      'loop': false,
    },
  },
  'fonts': {
    'f': {
      'lineHeight': 5,
      'spacing': 1,
      'glyphs': {'A': 'ga', ' ': 'gs'},
    },
  },
};

/// PNG тестового атласа: белые прямоугольники на прозрачном фоне.
Future<Uint8List> testAtlasPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..isAntiAlias = false;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 4, 8), paint); // half
  canvas.drawRect(const Rect.fromLTWH(0, 8, 6, 2), paint); // wide
  canvas.drawRect(const Rect.fromLTWH(16, 0, 8, 8), paint); // full
  canvas.drawRect(const Rect.fromLTWH(8, 0, 3, 5), paint); // ga
  final image = await recorder.endRecording().toImage(32, 16);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Набор файлов в памяти вместо ассетов приложения.
class MemoryBundle extends AssetBundle {
  MemoryBundle(this.files);

  final Map<String, Uint8List> files;

  @override
  Future<ByteData> load(String key) async {
    final bytes = files[key];
    if (bytes == null) throw FlutterError('Нет файла $key');
    return ByteData.sublistView(bytes);
  }
}

/// Загружает тестовый атлас. [json] можно подменить, чтобы проверить
/// реакцию на неверное описание.
Future<PixelAtlas> loadTestAtlas({Map<String, Object?>? json}) async {
  final bundle = MemoryBundle({
    't.json': Uint8List.fromList(utf8.encode(jsonEncode(json ?? testAtlasJson))),
    't.png': await testAtlasPng(),
  });
  return PixelAtlas.load(bundle, 't.json');
}
