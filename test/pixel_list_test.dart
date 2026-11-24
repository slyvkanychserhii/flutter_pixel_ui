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

  // Высота строки: подпись шрифта 'f' высотой 5 плюс 6, то есть 11 пикселей
  // сцены. Масштаб 2: строка 22 пикселя, рамка 2 пикселя.
  Widget list(
    List<String> labels, {
    int? selected,
    ValueChanged<int>? onSelected,
    double height = 100,
  }) {
    return host(SizedBox(
      width: 200,
      height: height,
      child: PixelList(
        atlas: atlas,
        font: 'f',
        labels: labels,
        selectedIndex: selected,
        onSelected: onSelected,
      ),
    ));
  }

  testWidgets('занимает всё место родителя', (tester) async {
    await tester.pumpWidget(list(['AA', 'AA'], onSelected: (_) {}));
    expect(tester.getSize(find.byType(PixelList)), const Size(200, 100));
  });

  testWidgets('нажатие на строку сообщает её номер', (tester) async {
    final log = <int>[];
    await tester.pumpWidget(list(['AA', 'AA', 'AA'], onSelected: log.add));
    // Вторая строка: рамка 2 + первая строка 22 + середина 11.
    await tester.tapAt(const Offset(50, 35));
    expect(log, [1]);
  });

  testWidgets('без onSelected нажатие ничего не делает', (tester) async {
    await tester.pumpWidget(list(['AA', 'AA', 'AA']));
    await tester.tapAt(const Offset(50, 35));
    expect(tester.takeException(), isNull);
  });

  testWidgets('длинный список прокручивается', (tester) async {
    final labels = List.filled(30, 'AA');
    await tester.pumpWidget(list(labels, onSelected: (_) {}));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, 0);

    await tester.drag(find.byType(PixelList), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('после остановки смещение кратно масштабу', (tester) async {
    final labels = List.filled(30, 'AA');
    await tester.pumpWidget(list(labels, onSelected: (_) {}));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

    // Тянем на нечётное число пикселей, чтобы получить дробное смещение.
    await tester.drag(find.byType(PixelList), const Offset(0, -33));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels % 2, 0);
  });

  testWidgets('нажатие на дорожку полосы прокрутки двигает список',
      (tester) async {
    final labels = List.filled(30, 'AA');
    await tester.pumpWidget(list(labels, onSelected: (_) {}));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

    // Дорожка справа: последние 5 пикселей сцены (10) перед рамкой (2).
    await tester.tapAt(const Offset(200 - 2 - 5, 90));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
  });
}
