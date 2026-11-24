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

  // В тестовом атласе подпись 'AA' шрифтом 'f' имеет размер 7 x 5 пикселей
  // сцены.
  group('PixelSegmented', () {
    Widget segmented(List<int> log, {int value = 0, bool enabled = true}) {
      return host(PixelSegmented<int>(
        atlas: atlas,
        font: 'f',
        segments: const {0: 'AA', 1: 'AA'},
        value: value,
        onChanged: enabled ? log.add : null,
      ));
    }

    testWidgets('размер: два сегмента по 15, рамка и линия, высота 13',
        (tester) async {
      await tester.pumpWidget(segmented([]));
      // ширина 1 + 15 + 1 + 15 + 1 = 33, масштаб 2
      expect(tester.getSize(find.byType(PixelSegmented<int>)), const Size(66, 26));
    });

    testWidgets('нажатие на второй сегмент сообщает его значение',
        (tester) async {
      final log = <int>[];
      await tester.pumpWidget(segmented(log));
      await tester.tapAt(const Offset(50, 10));
      expect(log, [1]);
    });

    testWidgets('нажатие на уже выбранный сегмент ничего не сообщает',
        (tester) async {
      final log = <int>[];
      await tester.pumpWidget(segmented(log));
      await tester.tapAt(const Offset(10, 10));
      expect(log, isEmpty);
    });

    testWidgets('отключённые сегменты не реагируют', (tester) async {
      await tester.pumpWidget(segmented([], enabled: false));
      await tester.tapAt(const Offset(50, 10));
      expect(tester.takeException(), isNull);
    });
  });

  group('PixelTabs', () {
    Widget tabs(List<int> log, {int index = 0}) {
      return host(PixelTabs(
        atlas: atlas,
        font: 'f',
        tabs: const ['AA', 'AA'],
        index: index,
        onChanged: log.add,
        child: const SizedBox(width: 200, height: 50),
      ));
    }

    testWidgets('занимает всё место, которое дал родитель', (tester) async {
      await tester.pumpWidget(host(SizedBox(
        width: 300,
        height: 200,
        child: PixelTabs(
          atlas: atlas,
          font: 'f',
          tabs: const ['AA', 'AA'],
          index: 0,
          onChanged: (_) {},
          child: const SizedBox(width: 20, height: 10),
        ),
      )));
      expect(tester.getSize(find.byType(PixelTabs)), const Size(300, 200));
    });

    testWidgets('без ограничения по высоте берёт высоту содержимого',
        (tester) async {
      await tester.pumpWidget(host(SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: PixelTabs(
            atlas: atlas,
            font: 'f',
            tabs: const ['AA', 'AA'],
            index: 0,
            onChanged: (_) {},
            child: const SizedBox(width: 20, height: 50),
          ),
        ),
      )));
      // ширина по родителю; высота 50 + 2 * 8 + (13 + 1) * 2
      expect(tester.getSize(find.byType(PixelTabs)), const Size(300, 94));
    });

    testWidgets('нажатие на второй ярлык сообщает его номер', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(tabs(log));
      await tester.tapAt(const Offset(56, 10));
      expect(log, [1]);
    });

    testWidgets('нажатие на выбранный ярлык ничего не сообщает', (tester) async {
      final log = <int>[];
      await tester.pumpWidget(tabs(log));
      await tester.tapAt(const Offset(20, 10));
      expect(log, isEmpty);
    });

    testWidgets('нажатие мимо ярлыков (справа от них) игнорируется',
        (tester) async {
      final log = <int>[];
      await tester.pumpWidget(tabs(log));
      await tester.tapAt(const Offset(150, 10));
      expect(log, isEmpty);
    });
  });
}
