import 'package:flutter/services.dart';

/// Результат применения маски: итоговый текст и откуда взят каждый его
/// символ.
class PixelMaskResult {
  const PixelMaskResult(this.text, this.source);

  /// Текст по маске.
  final String text;

  /// Для каждого символа [text]: номер символа во входной строке, из
  /// которого он взят, или -1, если символ (постоянный знак маски) добавлен
  /// автоматически.
  final List<int> source;
}

// Подходит ли символ [ch] под знак маски [p] ('#', 'A' или '*').
bool _fits(String p, String ch) {
  switch (p) {
    case '#':
      final c = ch.codeUnitAt(0);
      return c >= 0x30 && c <= 0x39;
    case 'A':
      return RegExp(r'^\p{L}$', unicode: true).hasMatch(ch);
    default: // '*'
      return true;
  }
}

bool _isPlaceholder(String p) => p == '#' || p == 'A' || p == '*';

/// Применяет [mask] к строке [input].
///
/// Знаки маски:
///
///  * `#` цифра;
///  * `A` буква (любого алфавита);
///  * `*` любой символ;
///  * всё остальное это постоянные знаки: они вставляются сами.
///
/// Например, маска `+7 (###) ###-##-##` превращает `9161234567` в
/// `+7 (916) 123-45-67`. Постоянный знак добавляется только тогда, когда за
/// ним будет вводимый символ: пока пользователь не ввёл следующую цифру,
/// закрывающая скобка не появляется, поэтому удалять текст клавишей
/// Backspace можно без «залипания».
///
/// Символы входа, не подходящие под очередной знак, пропускаются. Если
/// ввод длиннее маски, лишнее отбрасывается.
PixelMaskResult applyPixelMask(String mask, String input) {
  final out = StringBuffer();
  final src = <int>[];
  var i = 0;

  for (var m = 0; m < mask.length; m++) {
    final p = mask[m];
    if (_isPlaceholder(p)) {
      // Следующий подходящий символ входа.
      while (i < input.length && !_fits(p, input[i])) {
        i++;
      }
      if (i >= input.length) break;
      out.write(input[i]);
      src.add(i);
      i++;
    } else {
      if (i >= input.length) break; // конечные постоянные знаки не добавляем
      if (input[i] == p) {
        // Пользователь сам напечатал этот знак.
        out.write(p);
        src.add(i);
        i++;
      } else {
        // Знак нужно вставить сам, но только если дальше есть символ,
        // который займёт следующий знак маски.
        var next = m + 1;
        while (next < mask.length && !_isPlaceholder(mask[next])) {
          next++;
        }
        if (next >= mask.length) break;
        var any = false;
        for (var j = i; j < input.length; j++) {
          if (_fits(mask[next], input[j])) {
            any = true;
            break;
          }
        }
        if (!any) break;
        out.write(p);
        src.add(-1);
      }
    }
  }
  return PixelMaskResult(out.toString(), src);
}

/// Форматтер ввода по шаблону: оставляет в поле текст по маске (см.
/// [applyPixelMask]). Годится для любого поля Flutter, не только
/// PixelTextField.
///
/// Форматтеры вызываются только при вводе пользователя. Начальный текст
/// контроллера должен уже соответствовать маске (или пропустите его через
/// [applyPixelMask]).
class PixelMaskFormatter extends TextInputFormatter {
  const PixelMaskFormatter(this.mask);

  final String mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final result = applyPixelMask(mask, newValue.text);
    final original = newValue.selection.extentOffset < 0
        ? newValue.text.length
        : newValue.selection.extentOffset;

    // Курсор встаёт после последнего символа, который был перед ним во
    // входе. Если курсор был в конце, он остаётся в конце результата (после
    // автоматически добавленных знаков).
    var caret = 0;
    for (var k = 0; k < result.source.length; k++) {
      if (result.source[k] >= 0 && result.source[k] < original) caret = k + 1;
    }
    if (original >= newValue.text.length) caret = result.text.length;

    return TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}
