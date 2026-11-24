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

  // Кадр 'full' (8x8, непрозрачный) годится как рамка с полосой 1.
  const style = PixelFrameStyle(frame: 'full', slice: EdgeInsets.all(1));

  group('PixelButton со спрайтами', () {
    PixelButton button({PixelFrameStyle? frame, VoidCallback? onPressed}) => PixelButton(
          atlas: atlas,
          font: 'f',
          label: 'AA',
          scale: 2,
          frame: frame,
          onPressed: onPressed,
        );

    testWidgets('размер такой же, как у кнопки из примитивов', (tester) async {
      await tester.pumpWidget(host(button(onPressed: () {})));
      final plain = tester.getSize(find.byType(PixelButton));
      await tester.pumpWidget(host(button(frame: style, onPressed: () {})));
      expect(tester.getSize(find.byType(PixelButton)), plain);
    });

    testWidgets('рамка рисуется через PixelNineSlice', (tester) async {
      await tester.pumpWidget(host(button(onPressed: () {})));
      expect(find.byType(PixelNineSlice), findsNothing);
      await tester.pumpWidget(host(button(frame: style, onPressed: () {})));
      expect(find.byType(PixelNineSlice), findsOneWidget);
    });

    testWidgets('нажатие работает, нажатое и отключённое состояние не падают',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(button(frame: style, onPressed: () => taps++)));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(PixelButton)));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(taps, 1);

      await tester.pumpWidget(host(button(frame: style)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('рамка из темы подхватывается, параметр сильнее темы', (tester) async {
      await tester.pumpWidget(host(PixelThemeScope(
        theme: const PixelTheme(buttonFrame: style),
        child: button(onPressed: () {}),
      )));
      expect(find.byType(PixelNineSlice), findsOneWidget);
    });
  });

  group('PixelPanel', () {
    testWidgets('рамка из спрайта: заголовок и содержимое на месте', (tester) async {
      await tester.pumpWidget(host(PixelPanel(
        atlas: atlas,
        font: 'f',
        title: 'AA',
        frame: style,
        child: const SizedBox(width: 20, height: 10),
      )));
      expect(find.byType(PixelNineSlice), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Размер больше содержимого на отступы, рамку и заголовок.
      final size = tester.getSize(find.byType(PixelPanel));
      expect(size.width, greaterThan(20));
      expect(size.height, greaterThan(10));
    });

    testWidgets('expand занимает всё место родителя', (tester) async {
      await tester.pumpWidget(host(const SizedBox(
        width: 200,
        height: 100,
        child: PixelPanel(expand: true, child: SizedBox(width: 10, height: 10)),
      )));
      expect(tester.getSize(find.byType(PixelPanel)), const Size(200, 100));
    });

    testWidgets('без expand панель по размеру содержимого', (tester) async {
      await tester.pumpWidget(host(const SizedBox(
        width: 200,
        height: 100,
        child: Align(
          alignment: Alignment.topLeft,
          child: PixelPanel(child: SizedBox(width: 10, height: 10)),
        ),
      )));
      final size = tester.getSize(find.byType(PixelPanel));
      expect(size.width, lessThan(200));
      expect(size.height, lessThan(100));
    });

    testWidgets('expand с рамкой из спрайта', (tester) async {
      await tester.pumpWidget(host(SizedBox(
        width: 200,
        height: 100,
        child: PixelPanel(
          atlas: atlas,
          frame: style,
          expand: true,
          child: const SizedBox(width: 10, height: 10),
        ),
      )));
      expect(tester.getSize(find.byType(PixelPanel)), const Size(200, 100));
    });

    testWidgets('expand в списке без высоты берёт размер содержимого', (tester) async {
      await tester.pumpWidget(host(const SizedBox(
        width: 200,
        child: SingleChildScrollView(
          child: PixelPanel(expand: true, child: SizedBox(width: 10, height: 30)),
        ),
      )));
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(PixelPanel));
      expect(size.width, 200);
      expect(size.height, lessThan(100));
    });
  });

  group('PixelTheme с рамками', () {
    test('рамки входят в равенство темы', () {
      const a = PixelTheme(buttonFrame: style);
      expect(a, const PixelTheme(buttonFrame: style));
      expect(a == PixelTheme.standard, isFalse);
      expect(a.copyWith(scale: 3).buttonFrame, style);
    });
  });
}
