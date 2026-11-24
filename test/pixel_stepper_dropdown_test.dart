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

  group('PixelStepper', () {
    Widget stepper(List<int> log, {int value = 5, bool enabled = true}) {
      return host(PixelStepper(
        atlas: atlas,
        font: 'f',
        value: value,
        min: 0,
        max: 10,
        onChanged: enabled ? log.add : null,
      ));
    }

    // Точки нажатия: левая и правая кнопки (масштаб 2, середина кнопки на
    // 5 пикселей сцены от края).
    Offset minusPoint(WidgetTester t) => t.getTopLeft(find.byType(PixelStepper)) + const Offset(10, 10);
    Offset plusPoint(WidgetTester t) => t.getTopRight(find.byType(PixelStepper)) - const Offset(10, -10);

    testWidgets('«плюс» и «минус» меняют значение на шаг', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(stepper(log));
      await tester.tapAt(plusPoint(tester));
      await tester.tapAt(minusPoint(tester));
      expect(log, [6, 4]);
    });

    // Середина поля с числом (масштаб 2, поле шире кнопок).
    Offset valuePoint(WidgetTester t) => t.getCenter(find.byType(PixelStepper));

    testWidgets('перетаскивание по числу вправо увеличивает значение', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(stepper(log));
      await tester.dragFrom(valuePoint(tester), const Offset(60, 0));
      expect(log, isNotEmpty);
      expect(log.last, greaterThan(5));
    });

    testWidgets('перетаскивание по числу влево уменьшает значение', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(stepper(log));
      await tester.dragFrom(valuePoint(tester), const Offset(-60, 0));
      expect(log, isNotEmpty);
      expect(log.last, lessThan(5));
    });

    testWidgets('перетаскивание, начатое на кнопке, значение не меняет', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(stepper(log));
      // Начало на «плюсе»: сработает только нажатие, не перетаскивание.
      await tester.dragFrom(plusPoint(tester), const Offset(-60, 0));
      expect(log.where((v) => v < 5), isEmpty);
    });

    testWidgets('отключённый счётчик не реагирует на перетаскивание', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(stepper(log, enabled: false));
      await tester.dragFrom(valuePoint(tester), const Offset(60, 0));
      expect(log, isEmpty);
    });

    testWidgets('на границе диапазона сторона не реагирует', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(stepper(log, value: 10));
      await tester.tapAt(plusPoint(tester));
      expect(log, isEmpty);
      await tester.tapAt(minusPoint(tester));
      expect(log, [9]);
    });

    testWidgets('удержание повторяет изменение', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(stepper(log));
      final gesture = await tester.startGesture(plusPoint(tester));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 240));
      await gesture.up();
      await tester.pump();
      // касание + пауза + несколько повторов
      expect(log.length, greaterThanOrEqualTo(3));

      // После отпускания повтор прекращается.
      final count = log.length;
      await tester.pump(const Duration(seconds: 1));
      expect(log.length, count);
    });

    testWidgets('отключённый счётчик не реагирует', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(stepper(log, enabled: false));
      await tester.tapAt(plusPoint(tester));
      expect(log, isEmpty);
    });
  });

  group('PixelDropdown', () {
    Widget app(List<String> log) {
      return WidgetsApp(
        color: const Color(0xFF000000),
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          pageBuilder: (context, _, __) => Align(
            alignment: Alignment.topLeft,
            child: PixelDropdown<String>(
              atlas: atlas,
              font: 'f',
              items: const {'a': 'AA', 'b': 'AA', 'c': 'AA'},
              value: 'a',
              onChanged: log.add,
            ),
          ),
        ),
      );
    }

    testWidgets('нажатие открывает меню, выбор пункта закрывает его',
        (tester) async {
      final log = <String>[];
      await tester.pumpWidget(app(log));
      expect(find.byType(PixelCanvas), findsOneWidget);

      final field = find.byType(PixelDropdown<String>);
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(find.byType(PixelCanvas), findsNWidgets(2)); // поле и меню

      // Меню начинается под полем; пункт высотой 9 пикселей сцены, масштаб 2.
      // Второй пункт: 1 + 9 + 4 = 14 пикселей сцены от верха меню.
      final below = tester.getBottomLeft(field);
      await tester.tapAt(below + const Offset(10, 28));
      await tester.pumpAndSettle();
      expect(log, ['b']);
      expect(find.byType(PixelCanvas), findsOneWidget);
    });

    testWidgets('выбор текущего пункта ничего не сообщает', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(app(log));
      final field = find.byType(PixelDropdown<String>);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Первый пункт (выбранный): 1 + 4 = 5 пикселей сцены от верха меню.
      await tester.tapAt(tester.getBottomLeft(field) + const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(find.byType(PixelCanvas), findsOneWidget);
    });

    testWidgets('нажатие мимо меню закрывает его без выбора', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(app(log));
      await tester.tap(find.byType(PixelDropdown<String>));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(find.byType(PixelCanvas), findsOneWidget);
    });
  });
}
