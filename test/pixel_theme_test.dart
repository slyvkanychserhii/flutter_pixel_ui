import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) =>
      Directionality(textDirection: TextDirection.ltr, child: Align(alignment: Alignment.topLeft, child: child));

  group('PixelTheme', () {
    test('равенство и copyWith', () {
      const a = PixelTheme(primary: Color(0xFF112233), scale: 3);
      expect(a, const PixelTheme(primary: Color(0xFF112233), scale: 3));
      expect(a.copyWith(scale: 4).scale, 4);
      expect(a.copyWith(scale: 4).primary, a.primary);
      expect(a == PixelTheme.standard, isFalse);
    });

    testWidgets('без PixelThemeScope берётся стандартная тема', (tester) async {
      late PixelTheme found;
      await tester.pumpWidget(host(Builder(builder: (c) {
        found = PixelTheme.of(c);
        return const SizedBox();
      })));
      expect(found, PixelTheme.standard);
    });

    testWidgets('PixelThemeScope отдаёт тему вниз по дереву', (tester) async {
      const theme = PixelTheme(primary: Color(0xFFAA0000));
      late PixelTheme found;
      await tester.pumpWidget(host(PixelThemeScope(
        theme: theme,
        child: Builder(builder: (c) {
          found = PixelTheme.of(c);
          return const SizedBox();
        }),
      )));
      expect(found, theme);
    });
  });

  group('масштаб из темы', () {
    // Размер флажка: 9 пикселей сцены на масштаб (см. PixelCheckbox).
    Size checkboxSize(WidgetTester t) => t.getSize(find.byType(PixelCheckbox));

    testWidgets('без темы у флажка привычный масштаб 3', (tester) async {
      await tester.pumpWidget(host(PixelCheckbox(value: false, onChanged: (_) {})));
      final base = checkboxSize(tester);
      await tester.pumpWidget(host(PixelCheckbox(value: false, scale: 3, onChanged: (_) {})));
      expect(checkboxSize(tester), base);
    });

    testWidgets('тема с scale меняет размер, параметр сильнее темы', (tester) async {
      await tester.pumpWidget(host(PixelCheckbox(value: false, scale: 1, onChanged: (_) {})));
      final one = checkboxSize(tester);

      await tester.pumpWidget(host(PixelThemeScope(
        theme: const PixelTheme(scale: 2),
        child: PixelCheckbox(value: false, onChanged: (_) {}),
      )));
      expect(checkboxSize(tester), one * 2.0);

      // Явный scale у виджета побеждает тему.
      await tester.pumpWidget(host(PixelThemeScope(
        theme: const PixelTheme(scale: 2),
        child: PixelCheckbox(value: false, scale: 1, onChanged: (_) {}),
      )));
      expect(checkboxSize(tester), one);
    });

    testWidgets('смена темы перестраивает виджеты', (tester) async {
      Widget app(int scale) => host(PixelThemeScope(
            theme: PixelTheme(scale: scale),
            child: PixelCheckbox(value: false, onChanged: (_) {}),
          ));
      await tester.pumpWidget(app(1));
      final one = checkboxSize(tester);
      await tester.pumpWidget(app(3));
      expect(checkboxSize(tester), one * 3.0);
    });
  });
}
