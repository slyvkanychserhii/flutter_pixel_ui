import 'package:flutter/services.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String mask(String m, String input) => applyPixelMask(m, input).text;

  group('applyPixelMask', () {
    test('постоянные знаки вставляются, когда за ними идёт символ', () {
      expect(mask('(###) ###', '12'), '(12');
      expect(mask('(###) ###', '123'), '(123');
      expect(mask('(###) ###', '1234'), '(123) 4');
      expect(mask('(###) ###', '123456'), '(123) 456');
    });

    test('лишний ввод за маской отбрасывается', () {
      expect(mask('(###) ###', '12345678901'), '(123) 456');
    });

    test('пустой ввод даёт пустую строку', () {
      expect(mask('(###) ###', ''), '');
    });

    test('символы не того класса пропускаются', () {
      expect(mask('###', 'a1b2c3'), '123');
      expect(mask('AA-##', 'ab12'), 'ab-12');
      // цифры пропускаются, пока не найдётся буква; потом '-' и цифр уже нет
      expect(mask('AA-##', '12ab'), 'ab');
    });

    test('* принимает любой символ', () {
      expect(mask('*-*', 'a1'), 'a-1');
    });

    test('напечатанный постоянный знак не удваивается', () {
      expect(mask('(###) ###', '(123) 456'), '(123) 456');
      expect(mask('(###) ###', '(123)'), '(123)');
    });

    test('постоянный знак не добавляется перед неподходящим символом', () {
      // после '(123' идёт 'x', а он не цифра: закрывающая скобка не нужна
      expect(mask('(###) ###', '(123x'), '(123');
    });

    test('конечные постоянные знаки не добавляются сами', () {
      expect(mask('##-##', '12'), '12');
    });

    test('source показывает происхождение символов', () {
      final r = applyPixelMask('##-##', '123');
      expect(r.text, '12-3');
      // '1' и '2' из входа 0 и 1, '-' добавлен сам, '3' из входа 2
      expect(r.source, [0, 1, -1, 2]);
    });
  });

  group('PixelMaskFormatter', () {
    const formatter = PixelMaskFormatter('###-###');

    TextEditingValue format(String oldText, String newText, int caret) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: oldText),
          TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: caret),
          ),
        );

    test('ввод в конце: курсор остаётся в конце после вставленного знака', () {
      final v = format('123', '1234', 4);
      expect(v.text, '123-4');
      expect(v.selection, const TextSelection.collapsed(offset: 5));
    });

    test('вставка в середину: курсор после вставленного символа', () {
      final v = format('123-456', '1923-456', 2);
      expect(v.text, '192-345');
      expect(v.selection, const TextSelection.collapsed(offset: 2));
    });

    test('удаление постоянного знака в середине не ломает текст', () {
      final v = format('123-456', '123456', 3);
      expect(v.text, '123-456');
    });
  });
}
