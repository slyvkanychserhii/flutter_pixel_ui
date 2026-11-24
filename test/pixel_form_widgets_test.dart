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

  group('PixelCheckbox', () {
    testWidgets('размер 10 x 10 пикселей сцены, умноженные на масштаб',
        (tester) async {
      await tester.pumpWidget(host(
        PixelCheckbox(value: false, scale: 2, onChanged: (_) {}),
      ));
      expect(tester.getSize(find.byType(PixelCheckbox)), const Size(20, 20));
    });

    testWidgets('нажатие сообщает противоположное значение', (tester) async {
      final values = <bool>[];
      await tester.pumpWidget(host(
        PixelCheckbox(value: false, onChanged: values.add),
      ));
      await tester.tap(find.byType(PixelCheckbox));
      expect(values, [true]);

      await tester.pumpWidget(host(
        PixelCheckbox(value: true, onChanged: values.add),
      ));
      await tester.tap(find.byType(PixelCheckbox));
      expect(values, [true, false]);
    });

    testWidgets('без onChanged отключён', (tester) async {
      await tester.pumpWidget(host(
        const PixelCheckbox(value: true, onChanged: null),
      ));
      await tester.tap(find.byType(PixelCheckbox));
      expect(tester.takeException(), isNull);
    });
  });

  group('PixelRadio', () {
    testWidgets('размер 11 x 11 пикселей сцены', (tester) async {
      await tester.pumpWidget(host(
        PixelRadio<int>(
            value: 0, groupValue: 0, scale: 2, onChanged: (_) {}),
      ));
      expect(tester.getSize(find.byType(PixelRadio<int>)), const Size(22, 22));
    });

    testWidgets('нажатие на невыбранную сообщает её значение', (tester) async {
      final values = <int>[];
      await tester.pumpWidget(host(
        PixelRadio<int>(value: 2, groupValue: 0, onChanged: values.add),
      ));
      await tester.tap(find.byType(PixelRadio<int>));
      expect(values, [2]);
    });

    testWidgets('нажатие на уже выбранную ничего не сообщает', (tester) async {
      final values = <int>[];
      await tester.pumpWidget(host(
        PixelRadio<int>(value: 2, groupValue: 2, onChanged: values.add),
      ));
      await tester.tap(find.byType(PixelRadio<int>));
      expect(values, isEmpty);
    });
  });

  group('PixelProgressBar', () {
    testWidgets('размер: ширина и высота 8, умноженные на масштаб',
        (tester) async {
      await tester.pumpWidget(host(
        const PixelProgressBar(value: 0.5, width: 40, scale: 2),
      ));
      expect(
          tester.getSize(find.byType(PixelProgressBar)), const Size(80, 16));
    });

    testWidgets('смена значения доезжает без ошибок', (tester) async {
      await tester.pumpWidget(host(const PixelProgressBar(value: 0.2)));
      await tester.pumpWidget(host(const PixelProgressBar(value: 0.9)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('блоки шкалы занимают всю ширину без остатка', () {
      for (final (w, n) in [(58, 10), (40, 7), (30, 30 ~/ 3), (100, 4)]) {
        final spans = PixelProgressBar.segmentSpans(w, n);
        expect(spans, hasLength(n));
        expect(spans.first.start, 0);
        expect(spans.last.start + spans.last.width, w);
        for (var i = 1; i < n; i++) {
          // Между соседними блоками ровно 1 пиксель зазора.
          expect(spans[i].start, spans[i - 1].start + spans[i - 1].width + 1);
        }
      }
    });

    testWidgets('блоки (segments) тоже рисуются', (tester) async {
      await tester.pumpWidget(host(
        const PixelProgressBar(value: 0.5, segments: 10),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('PixelPanel', () {
    testWidgets('размер: содержимое плюс отступы', (tester) async {
      await tester.pumpWidget(host(
        const PixelPanel(
          child: SizedBox(width: 40, height: 20),
        ),
      ));
      // Отступ по умолчанию 8 со всех сторон.
      expect(tester.getSize(find.byType(PixelPanel)), const Size(56, 36));
    });

    testWidgets('заголовок сдвигает содержимое вниз', (tester) async {
      // Подпись "AA" в тестовом шрифте высотой 5: полоса 5 + 3 = 8, плюс
      // рамка и разделитель 2, итого 10 пикселей сцены, при масштабе 2 это
      // 20 на экране. Высота 20 + 8 + 8 + 20 = 56.
      await tester.pumpWidget(host(
        PixelPanel(
          atlas: atlas,
          font: 'f',
          title: 'AA',
          child: const SizedBox(width: 40, height: 20),
        ),
      ));
      expect(tester.getSize(find.byType(PixelPanel)), const Size(56, 56));
    });

    testWidgets('содержимое получает нажатия', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(
        PixelPanel(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox(width: 40, height: 20),
          ),
        ),
      ));
      await tester.tapAt(const Offset(30, 20)); // внутри содержимого
      expect(taps, 1);
    });
  });
}
