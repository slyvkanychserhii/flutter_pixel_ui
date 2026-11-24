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

  // В тестовом атласе у шрифта 'f' есть только 'A' (3 x 5, зазор 1, то есть
  // 4 пикселя сцены на символ) и пробел. Поле шириной 60 при масштабе 2
  // имеет размер 120 x 26.
  Widget field({
    TextEditingController? controller,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    int? maxLength,
    bool enabled = true,
    bool obscureText = false,
    String? mask,
  }) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        pageBuilder: (context, _, __) => Align(
          alignment: Alignment.topLeft,
          child: PixelTextField(
            atlas: atlas,
            font: 'f',
            width: 60,
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            maxLength: maxLength,
            enabled: enabled,
            obscureText: obscureText,
            // В тестовом шрифте есть только 'A'.
            obscuringCharacter: 'A',
            mask: mask,
          ),
        ),
      ),
    );
  }

  testWidgets('размер: ширина и высота подписи плюс 8, умноженные на масштаб',
      (tester) async {
    await tester.pumpWidget(field());
    expect(tester.getSize(find.byType(PixelTextField)), const Size(120, 26));
  });

  testWidgets('нажатие даёт полю фокус', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(field(focusNode: focus));
    expect(focus.hasFocus, isFalse);

    await tester.tapAt(const Offset(30, 13));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('отключённое поле не берёт фокус', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(field(focusNode: focus, enabled: false));
    await tester.tapAt(const Offset(30, 13));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('символы без глифа отбрасываются при вводе', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final log = <String>[];
    await tester.pumpWidget(field(controller: controller, onChanged: log.add));

    await tester.enterText(find.byType(EditableText), 'AxA');
    await tester.pump();
    expect(controller.text, 'AA');
    expect(log.last, 'AA');
  });

  testWidgets('maxLength ограничивает длину', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller, maxLength: 3));

    await tester.enterText(find.byType(EditableText), 'AAAAAA');
    await tester.pump();
    expect(controller.text, 'AAA');
  });

  testWidgets('нажатие ставит курсор ближайший к точке', (tester) async {
    final controller = TextEditingController(text: 'AAAA');
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller));

    // Границы символов: 0, 4, 8, 12, 16 пикселей сцены. Текст начинается
    // на 3 пикселя сцены от края. Точка на 9 пикселей текста (между 2 и 3,
    // ближе к 2) это (9 + 3) * 2 = 24 обычных пикселя.
    await tester.tapAt(const Offset(24, 13));
    await tester.pump();
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
  });

  testWidgets('нажатие правее текста ставит курсор в конец', (tester) async {
    final controller = TextEditingController(text: 'AA');
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller));
    await tester.tapAt(const Offset(110, 13));
    await tester.pump();
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
  });

  testWidgets('перетаскивание выделяет текст', (tester) async {
    final controller = TextEditingController(text: 'AAAA');
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller));

    // От начала текста (x = 6) до третьей границы (12 + 3) * 2 = 30.
    await tester.dragFrom(const Offset(6, 13), const Offset(24, 0));
    await tester.pump();
    expect(controller.selection.isCollapsed, isFalse);
    expect(controller.selection.start, 0);
  });

  testWidgets('двойное нажатие выделяет слово', (tester) async {
    // 'AA AA': символы занимают 0-4, 4-8 (первое слово), пробел 8-11,
    // затем 11-15 и 15-19 (второе слово).
    final controller = TextEditingController(text: 'AA AA');
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller));

    // Точка на 5 пикселях текста (второй символ): (5 + 3) * 2 = 16.
    await tester.tapAt(const Offset(16, 13));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(16, 13));
    await tester.pump();
    expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 2));

    // Второе слово: точка на 13 пикселях текста, (13 + 3) * 2 = 32.
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(const Offset(32, 13));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(32, 13));
    await tester.pump();
    expect(controller.selection, const TextSelection(baseOffset: 3, extentOffset: 5));
  });

  testWidgets('два нажатия с большой паузой это не двойное нажатие',
      (tester) async {
    final controller = TextEditingController(text: 'AA AA');
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller));

    await tester.tapAt(const Offset(16, 13));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tapAt(const Offset(16, 13));
    await tester.pump();
    expect(controller.selection.isCollapsed, isTrue);
  });

  testWidgets('пароль: двойное нажатие выделяет весь текст', (tester) async {
    final controller = TextEditingController(text: 'AAAA');
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller, obscureText: true));

    await tester.tapAt(const Offset(16, 13));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(16, 13));
    await tester.pump();
    expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 4));
  });

  testWidgets('в поле пароля хранится настоящий текст', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller, obscureText: true));
    await tester.enterText(find.byType(EditableText), 'AA A');
    await tester.pump();
    expect(controller.text, 'AA A');
  });

  testWidgets('маска вставляет постоянные знаки при вводе', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    // 'A' в маске это любая буква, пробел постоянный знак.
    await tester.pumpWidget(field(controller: controller, mask: 'AA A'));

    await tester.enterText(find.byType(EditableText), 'AAA');
    await tester.pump();
    expect(controller.text, 'AA A');
  });

  testWidgets('начальный текст приводится к маске', (tester) async {
    final controller = TextEditingController(text: 'AAA');
    addTearDown(controller.dispose);
    await tester.pumpWidget(field(controller: controller, mask: 'AA A'));
    expect(controller.text, 'AA A');
  });

  testWidgets('клавиатура снова показывается при нажатии на поле в фокусе',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(field(focusNode: focus));

    await tester.tapAt(const Offset(30, 13));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    // Пользователь убрал клавиатуру, поле осталось в фокусе.
    tester.testTextInput.hide();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isFalse);

    // Повторное нажатие снова показывает клавиатуру.
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(const Offset(30, 13));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
