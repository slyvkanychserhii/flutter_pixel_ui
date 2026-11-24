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

  group('PixelButton', () {
    testWidgets('размер: подпись, рамка, отступы и тень, умноженные на масштаб',
        (tester) async {
      // Подпись "AA" в тестовом шрифте: 7 x 5. Ширина 7 + 2 * (1 + 4) = 17,
      // высота кнопки 5 + 2 * (1 + 3) = 13 плюс ряд тени = 14; масштаб 2.
      await tester.pumpWidget(host(PixelButton(
        atlas: atlas,
        font: 'f',
        label: 'AA',
        scale: 2,
        onPressed: () {},
      )));
      expect(tester.getSize(find.byType(PixelButton)), const Size(34, 28));
    });

    testWidgets('minWidth растягивает кнопку', (tester) async {
      await tester.pumpWidget(host(PixelButton(
        atlas: atlas,
        font: 'f',
        label: 'AA',
        scale: 1,
        minWidth: 40,
        onPressed: () {},
      )));
      expect(tester.getSize(find.byType(PixelButton)).width, 40);
    });

    testWidgets('нажатие вызывает onPressed', (tester) async {
      var count = 0;
      await tester.pumpWidget(host(PixelButton(
        atlas: atlas,
        font: 'f',
        label: 'AA',
        onPressed: () => count++,
      )));
      await tester.tap(find.byType(PixelButton));
      // Дожидаемся отложенного отпускания и конца анимации.
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('без onPressed кнопка отключена', (tester) async {
      await tester.pumpWidget(host(PixelButton(
        atlas: atlas,
        font: 'f',
        label: 'AA',
        onPressed: null,
      )));
      // Ничего не падает, нажимать нечему.
      await tester.tap(find.byType(PixelButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('PixelSwitch', () {
    testWidgets('размер 22 x 12 пикселей сцены, умноженные на масштаб',
        (tester) async {
      await tester.pumpWidget(host(
        PixelSwitch(value: false, scale: 3, onChanged: (_) {}),
      ));
      expect(tester.getSize(find.byType(PixelSwitch)), const Size(66, 36));
    });

    testWidgets('нажатие сообщает противоположное значение', (tester) async {
      final values = <bool>[];
      await tester.pumpWidget(host(
        PixelSwitch(value: false, onChanged: values.add),
      ));
      await tester.tap(find.byType(PixelSwitch));
      await tester.pumpAndSettle();
      expect(values, [true]);

      // Значение хранит приложение: передали true, следующее нажатие false.
      await tester.pumpWidget(host(
        PixelSwitch(value: true, onChanged: values.add),
      ));
      await tester.tap(find.byType(PixelSwitch));
      await tester.pumpAndSettle();
      expect(values, [true, false]);
    });

    testWidgets('без onChanged переключатель отключён', (tester) async {
      await tester.pumpWidget(host(
        const PixelSwitch(value: false, onChanged: null),
      ));
      await tester.tap(find.byType(PixelSwitch));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
