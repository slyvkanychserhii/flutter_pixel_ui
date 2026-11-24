import 'package:flutter/gestures.dart';
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

  // Приложение с Overlay; цель подсказки это SizedBox 60 x 30 в точке
  // (100, 100). Подсказка рисует PixelCanvas, поэтому по числу холстов видно,
  // показана ли она.
  Widget app({List<String>? taps}) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        pageBuilder: (context, _, __) => Stack(
          children: [
            Positioned(
              left: 100,
              top: 100,
              child: PixelTooltip(
                atlas: atlas,
                font: 'f',
                message: 'AA',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps?.add('tap'),
                  child: const SizedBox(width: 60, height: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('долгое нажатие показывает подсказку, потом она скрывается',
      (tester) async {
    await tester.pumpWidget(app());
    expect(find.byType(PixelCanvas), findsNothing);

    await tester.longPressAt(const Offset(130, 115));
    await tester.pump();
    expect(find.byType(PixelCanvas), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(PixelCanvas), findsNothing);
  });

  testWidgets('обычное нажатие доходит до дочернего виджета и не показывает подсказку',
      (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(app(taps: taps));
    await tester.tapAt(const Offset(130, 115));
    await tester.pump(const Duration(seconds: 1));
    expect(taps, ['tap']);
    expect(find.byType(PixelCanvas), findsNothing);
  });

  testWidgets('подсказка стоит над виджетом', (tester) async {
    await tester.pumpWidget(app());
    await tester.longPressAt(const Offset(130, 115));
    await tester.pump();
    // Нижний край плашки выше верха виджета (y = 100).
    expect(tester.getBottomLeft(find.byType(PixelCanvas)).dy, lessThan(100));
  });

  testWidgets('мышь: показывается после паузы и скрывается при уходе',
      (tester) async {
    await tester.pumpWidget(app());
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.moveTo(const Offset(130, 115));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(PixelCanvas), findsNothing); // ещё рано

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PixelCanvas), findsOneWidget);

    await mouse.moveTo(const Offset(600, 500));
    await tester.pump();
    expect(find.byType(PixelCanvas), findsNothing);
  });

  testWidgets('мышь, ушедшая раньше паузы, подсказку не показывает',
      (tester) async {
    await tester.pumpWidget(app());
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.moveTo(const Offset(130, 115));
    await tester.pump(const Duration(milliseconds: 200));
    await mouse.moveTo(const Offset(600, 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PixelCanvas), findsNothing);
  });
}
