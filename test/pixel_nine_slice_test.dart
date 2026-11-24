import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_atlas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PixelAtlas atlas;
  setUpAll(() async => atlas = await loadTestAtlas());
  tearDownAll(() => atlas.dispose());

  Widget host(Widget child) => Directionality(
        textDirection: TextDirection.ltr,
        child: Align(alignment: Alignment.topLeft, child: child),
      );

  group('nineSliceParts', () {
    // Кадр 16 x 16 в точке (10, 20), полосы 4 пикселя, область 30 x 20
    // пикселей сцены, масштаб 2.
    const frame = Rect.fromLTWH(10, 20, 16, 16);
    final parts = nineSliceParts(
      frame: frame,
      slice: const EdgeInsets.all(4),
      width: 30,
      height: 20,
      scale: 2,
    );

    test('девять частей', () => expect(parts, hasLength(9)));

    test('верхний левый угол: размер кадра, умноженный на масштаб', () {
      final p = parts.first;
      expect(p.src, const Rect.fromLTRB(10, 20, 14, 24));
      expect(p.dst, const Rect.fromLTWH(0, 0, 8, 8));
      expect(p.isCorner, isTrue);
    });

    test('центр растягивается на всё место между полосами', () {
      final p = parts[4];
      expect(p.src, const Rect.fromLTRB(14, 24, 22, 32));
      // слева и справа по 4 * 2, сверху и снизу тоже
      expect(p.dst, const Rect.fromLTRB(8, 8, 52, 32));
      expect(p.isCorner, isFalse);
    });

    test('нижний правый угол прижат к краю области', () {
      final p = parts.last;
      expect(p.dst, const Rect.fromLTRB(52, 32, 60, 40));
    });

    test('части покрывают область без щелей', () {
      var area = 0.0;
      for (final p in parts) {
        area += p.dst.width * p.dst.height;
      }
      expect(area, 60 * 40);
    });

    test('область меньше полос: ничего не рисуется', () {
      expect(
        nineSliceParts(
          frame: frame,
          slice: const EdgeInsets.all(4),
          width: 7,
          height: 20,
          scale: 2,
        ),
        isEmpty,
      );
    });

    test('нулевая полоса убирает соответствующие части', () {
      final p = nineSliceParts(
        frame: frame,
        slice: const EdgeInsets.symmetric(vertical: 4),
        width: 30,
        height: 20,
        scale: 1,
      );
      // только три части: сверху, центр, снизу, без левых и правых
      expect(p, hasLength(3));
    });
  });

  group('PixelNineSlice', () {
    Widget slice({bool tile = false, Widget? child, int scale = 2}) {
      // Кадр 'full' 8 x 8, полосы по 2.
      return PixelNineSlice(
        atlas: atlas,
        frame: 'full',
        slice: const EdgeInsets.all(2),
        scale: scale,
        tile: tile,
        padding: const EdgeInsets.all(3),
        child: child,
      );
    }

    testWidgets('занимает всё место, которое дал родитель', (tester) async {
      await tester.pumpWidget(host(SizedBox(width: 120, height: 80, child: slice())));
      expect(tester.getSize(find.byType(PixelNineSlice)), const Size(120, 80));
    });

    testWidgets('без ограничения высоты берёт размер содержимого',
        (tester) async {
      await tester.pumpWidget(host(SizedBox(
        width: 120,
        child: SingleChildScrollView(
          child: slice(child: const SizedBox(width: 10, height: 30)),
        ),
      )));
      // высота: 30 + 2 * (2 * 2 полосы) + 2 * 3 отступа = 44
      expect(tester.getSize(find.byType(PixelNineSlice)), const Size(120, 44));
    });

    testWidgets('содержимое отступает на полосу и padding', (tester) async {
      const key = Key('content');
      await tester.pumpWidget(host(SizedBox(
        width: 120,
        height: 80,
        child: slice(child: const SizedBox(key: key, width: 10, height: 10)),
      )));
      // 2 * 2 = 4 на полосу и 3 на padding
      expect(tester.getTopLeft(find.byKey(key)), const Offset(7, 7));
    });

    testWidgets('режим плиток рисуется без ошибок', (tester) async {
      await tester.pumpWidget(host(SizedBox(
        width: 121, // не кратно масштабу и размеру плитки
        height: 83,
        child: slice(tile: true),
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
