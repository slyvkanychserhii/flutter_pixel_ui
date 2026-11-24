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

  // В тестовом шрифте 'f' нет цифр, поэтому ширина числа равна нулю, а
  // высота подписи 5. Двоеточие рисуется примитивами и всегда имеет ширину 6.
  // Тогда геометрия (пиксели сцены):
  //
  //   колонка: ширина 6 + рамки 2 = 8; двоеточие 6
  //   колонки начинаются на x = 0, 14, 28; общая ширина 36
  //   высота: 1 + 8 (стрелка) + 1 + 9 (число) + 1 + 8 + 1 = 29
  //   стрелка вверх: y от 1 до 8, стрелка вниз: y от 19 до 26
  //
  // Масштаб 2: размер 72 x 58; центры стрелок вверх y = 5 (10 пикселей),
  // вниз y = 23 (46 пикселей); центры колонок x = 4, 18, 32.
  const hoursUp = Offset(8, 10);
  const minutesUp = Offset(36, 10);
  const secondsUp = Offset(64, 10);
  const hoursDown = Offset(8, 46);
  const secondsDown = Offset(64, 46);

  Widget picker(
    Duration value,
    List<Duration> log, {
    bool enabled = true,
    bool showSeconds = true,
    int maxHours = 99,
    bool wrapAround = false,
  }) {
    return host(PixelTimePicker(
      atlas: atlas,
      font: 'f',
      value: value,
      maxHours: maxHours,
      showSeconds: showSeconds,
      wrapAround: wrapAround,
      onChanged: enabled ? log.add : null,
    ));
  }

  testWidgets('размер зависит от числа колонок', (tester) async {
    await tester.pumpWidget(picker(Duration.zero, []));
    expect(tester.getSize(find.byType(PixelTimePicker)), const Size(72, 58));

    await tester.pumpWidget(picker(Duration.zero, [], showSeconds: false));
    expect(tester.getSize(find.byType(PixelTimePicker)), const Size(44, 58));
  });

  testWidgets('стрелка вверх у каждой колонки прибавляет свой шаг',
      (tester) async {
    final log = <Duration>[];
    await tester.pumpWidget(picker(Duration.zero, log));
    await tester.tapAt(hoursUp);
    await tester.tapAt(minutesUp);
    await tester.tapAt(secondsUp);
    expect(log, [
      const Duration(hours: 1),
      const Duration(minutes: 1),
      const Duration(seconds: 1),
    ]);
  });

  testWidgets('стрелка вниз вычитает', (tester) async {
    final log = <Duration>[];
    await tester.pumpWidget(picker(const Duration(hours: 1, seconds: 5), log));
    await tester.tapAt(hoursDown);
    await tester.tapAt(secondsDown);
    expect(log, [
      const Duration(seconds: 5),
      const Duration(hours: 1, seconds: 4),
    ]);
  });

  testWidgets('разряды переносятся как на часах', (tester) async {
    final log = <Duration>[];
    await tester.pumpWidget(picker(const Duration(seconds: 59), log));
    await tester.tapAt(secondsUp);
    expect(log, [const Duration(minutes: 1)]);
  });

  testWidgets('ниже нуля не опускается', (tester) async {
    final log = <Duration>[];
    await tester.pumpWidget(picker(Duration.zero, log));
    await tester.tapAt(hoursDown);
    await tester.tapAt(secondsDown);
    expect(log, isEmpty);
  });

  testWidgets('выше максимума не поднимается', (tester) async {
    final log = <Duration>[];
    await tester.pumpWidget(picker(
      const Duration(hours: 23, minutes: 59, seconds: 59),
      log,
      maxHours: 23,
    ));
    await tester.tapAt(secondsUp);
    await tester.tapAt(hoursUp);
    expect(log, isEmpty);
  });

  testWidgets('удержание стрелки повторяет изменение, отпускание прекращает',
      (tester) async {
    final log = <Duration>[];
    await tester.pumpWidget(picker(Duration.zero, log));
    final gesture = await tester.startGesture(secondsUp);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 240));
    await gesture.up();
    await tester.pump();
    expect(log.length, greaterThanOrEqualTo(3));

    final count = log.length;
    await tester.pump(const Duration(seconds: 1));
    expect(log.length, count);
  });

  testWidgets('перетаскивание по числу вверх увеличивает значение',
      (tester) async {
    final log = <Duration>[];
    await tester.pumpWidget(picker(Duration.zero, log));
    // Число минут: x = 18 (36 пикселей), y = 14 (28 пикселей).
    await tester.dragFrom(const Offset(36, 28), const Offset(0, -60));
    expect(log, isNotEmpty);
    expect(log.last, greaterThan(Duration.zero));
    expect(log.last.inSeconds % 60, 0); // менялись именно минуты
  });

  testWidgets('отключённый элемент не реагирует', (tester) async {
    final log = <Duration>[];
    await tester.pumpWidget(picker(const Duration(minutes: 5), log, enabled: false));
    await tester.tapAt(minutesUp);
    await tester.dragFrom(const Offset(36, 28), const Offset(0, -60));
    expect(log, isEmpty);
    expect(tester.takeException(), isNull);
  });

  group('циклический режим (wrapAround)', () {
    testWidgets('часы после 00 вниз идут на 23', (tester) async {
      final log = <Duration>[];
      await tester.pumpWidget(picker(Duration.zero, log, maxHours: 23, wrapAround: true));
      await tester.tapAt(hoursDown);
      expect(log, [const Duration(hours: 23)]);
    });

    testWidgets('часы после 23 вверх идут на 00', (tester) async {
      final log = <Duration>[];
      await tester.pumpWidget(picker(
        const Duration(hours: 23, minutes: 15),
        log,
        maxHours: 23,
        wrapAround: true,
      ));
      await tester.tapAt(hoursUp);
      expect(log, [const Duration(minutes: 15)]);
    });

    testWidgets('минуты идут по кругу без переноса в часы', (tester) async {
      final log = <Duration>[];
      await tester.pumpWidget(picker(
        const Duration(hours: 7),
        log,
        maxHours: 23,
        wrapAround: true,
      ));
      await tester.tapAt(const Offset(36, 46));
      expect(log, [const Duration(hours: 7, minutes: 59)]);
    });

    testWidgets('секунды после 59 вверх идут на 00 без переноса в минуты',
        (tester) async {
      final log = <Duration>[];
      await tester.pumpWidget(picker(
        const Duration(minutes: 5, seconds: 59),
        log,
        wrapAround: true,
      ));
      await tester.tapAt(secondsUp);
      expect(log, [const Duration(minutes: 5)]);
    });

    testWidgets('удержание стрелки вниз у 00 не останавливается', (tester) async {
      final log = <Duration>[];
      await tester.pumpWidget(picker(Duration.zero, log, maxHours: 23, wrapAround: true));
      final gesture = await tester.startGesture(hoursDown);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 240));
      await gesture.up();
      await tester.pump();
      expect(log.length, greaterThanOrEqualTo(3));
    });
  });
}
