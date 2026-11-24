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

  group('PixelSlider', () {
    testWidgets('размер: ширина и 12 пикселей сцены, умноженные на масштаб',
        (tester) async {
      await tester.pumpWidget(host(
        PixelSlider(value: 0, width: 60, scale: 2, onChanged: (_) {}),
      ));
      expect(tester.getSize(find.byType(PixelSlider)), const Size(120, 24));
    });

    testWidgets('нажатие в центр даёт около 0.5', (tester) async {
      final values = <double>[];
      await tester.pumpWidget(host(
        PixelSlider(value: 0, width: 60, scale: 2, onChanged: values.add),
      ));
      await tester.tapAt(const Offset(60, 10));
      expect(values, hasLength(1));
      expect(values.single, closeTo(0.5, 0.01));
    });

    testWidgets('нажатие у левого края даёт 0', (tester) async {
      final values = <double>[];
      await tester.pumpWidget(host(
        PixelSlider(value: 0.5, width: 60, scale: 2, onChanged: values.add),
      ));
      await tester.tapAt(const Offset(2, 10));
      expect(values, [0.0]);
    });

    testWidgets('перетаскивание вправо за край даёт 1', (tester) async {
      final values = <double>[];
      await tester.pumpWidget(host(
        PixelSlider(value: 0, width: 60, scale: 2, onChanged: values.add),
      ));
      await tester.dragFrom(const Offset(10, 10), const Offset(300, 0));
      expect(values, isNotEmpty);
      expect(values.last, 1.0);
    });

    testWidgets('с делениями значение попадает на деление', (tester) async {
      final values = <double>[];
      await tester.pumpWidget(host(
        PixelSlider(
          value: 1,
          min: 1,
          max: 5,
          divisions: 4,
          width: 60,
          scale: 2,
          onChanged: values.add,
        ),
      ));
      await tester.tapAt(const Offset(60, 10)); // середина: 3
      expect(values.single, 3.0);
    });

    testWidgets('повторное нажатие на то же значение не вызывает onChanged',
        (tester) async {
      final values = <double>[];
      await tester.pumpWidget(host(
        PixelSlider(value: 0, width: 60, scale: 2, onChanged: values.add),
      ));
      await tester.tapAt(const Offset(2, 10));
      expect(values, isEmpty);
    });

    testWidgets('отключённый ползунок не падает и не сообщает', (tester) async {
      await tester.pumpWidget(host(
        const PixelSlider(value: 0.3, width: 60, scale: 2, onChanged: null),
      ));
      await tester.tapAt(const Offset(60, 10));
      expect(tester.takeException(), isNull);
    });
  });

  group('PixelDialog', () {
    // Приложение с кнопкой-запуском; результат диалога копится в [results].
    Widget app(PixelAtlas atlas, List<bool?> results) {
      return WidgetsApp(
        color: const Color(0xFF000000),
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          pageBuilder: (context, _, __) => Builder(
            builder: (context) => GestureDetector(
              // Без opaque пустой SizedBox не принимает нажатия.
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final r = await showPixelDialog<bool>(
                  context: context,
                  builder: (ctx) => PixelDialog(
                    atlas: atlas,
                    font: 'f',
                    title: 'AA',
                    content: const Text('Вопрос'),
                    actions: [
                      PixelButton(
                        atlas: atlas,
                        font: 'f',
                        label: 'AA',
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ],
                  ),
                );
                results.add(r);
              },
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    }

    testWidgets('показывается, кнопка закрывает и возвращает результат',
        (tester) async {
      final results = <bool?>[];
      await tester.pumpWidget(app(atlas, results));
      await tester.tapAt(const Offset(400, 500));
      await tester.pumpAndSettle();
      expect(find.byType(PixelDialog), findsOneWidget);
      expect(find.text('Вопрос'), findsOneWidget);

      await tester.tap(find.byType(PixelButton));
      await tester.pumpAndSettle();
      expect(find.byType(PixelDialog), findsNothing);
      expect(results, [true]);
    });

    testWidgets('нажатие мимо диалога закрывает его с результатом null',
        (tester) async {
      final results = <bool?>[];
      await tester.pumpWidget(app(atlas, results));
      await tester.tapAt(const Offset(400, 500));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(PixelDialog), findsNothing);
      expect(results, [null]);
    });
  });
}
