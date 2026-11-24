import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_mask.dart';
import 'pixel_theme.dart';

/// Однострочное поле ввода с текстом шрифтом из атласа.
///
/// Ввод, фокус, клавиатуру (системную и аппаратную), выделение клавишами,
/// копирование и вставку выполняет обычный Flutter `EditableText`: он лежит
/// под полем невидимым. Всё, что видно (рамка, текст, курсор, выделение),
/// рисуют холсты шрифтом из атласа. Поэтому работают все привычные
/// сочетания клавиш и системная клавиатура, а вид остаётся пиксельным.
///
/// Поле принимает только те символы, которые есть в шрифте [font]: остальные
/// при вводе и вставке отбрасываются (иначе их нечем нарисовать). Текст
/// длиннее поля прокручивается так, чтобы курсор был виден.
///
///     PixelTextField(
///       atlas: atlas,
///       width: 100,
///       hint: 'Имя',
///       onChanged: (text) => print(text),
///     )
///
/// Нажатие ставит курсор, перетаскивание выделяет текст, двойное нажатие
/// выделяет слово (в поле пароля весь текст). Содержимым можно управлять
/// через [controller] (как у TextField).
///
/// Пароль: с [obscureText] вместо символов рисуются [obscuringCharacter]
/// (по умолчанию `*`; этот символ должен быть в шрифте, иначе он
/// рисуется как `?`), а копирование отключено.
///
/// Шаблон: с [mask] поле держит текст по маске, например
/// `+7 (###) ###-##-##` (`#` цифра, `A` буква, `*` любой символ, остальное
/// вставляется само), см. [PixelMaskFormatter]. Начальный текст
/// контроллера приводится к маске при создании поля.
///
/// Ширина [width] задаётся в пикселях сцены; без неё поле занимает всю
/// ширину родителя (тогда она должна быть ограничена). Высота одна: высота
/// подписи плюс рамка и отступы.
class PixelTextField extends StatelessWidget {
  const PixelTextField({
    super.key,
    required this.atlas,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.hint = '',
    this.maxLength,
    this.obscureText = false,
    this.obscuringCharacter = '*',
    this.mask,
    this.keyboardType,
    this.enabled = true,
    this.width,
    this.font,
    this.scale,
    this.color,
  });

  final PixelAtlas atlas;

  /// Содержимое поля. Если не задан, поле создаёт свой.
  final TextEditingController? controller;

  /// Управление фокусом. Если не задан, поле создаёт свой.
  final FocusNode? focusNode;

  /// Вызывается при каждом изменении текста.
  final ValueChanged<String>? onChanged;

  /// Вызывается по клавише Enter или кнопке «готово» на клавиатуре.
  final ValueChanged<String>? onSubmitted;

  /// Серая подсказка, пока поле пустое.
  final String hint;

  /// Наибольшее число символов или null без ограничения.
  final int? maxLength;

  /// Режим пароля: вместо символов рисуется [obscuringCharacter].
  final bool obscureText;

  /// Символ, которым закрашиваются символы пароля.
  final String obscuringCharacter;

  /// Шаблон ввода или null. Если задан, [maxLength] не используется (длину
  /// задаёт сама маска).
  final String? mask;

  /// Тип клавиатуры. По умолчанию цифровая для маски только из `#` и
  /// обычная в остальных случаях.
  final TextInputType? keyboardType;

  /// Отключённое поле серое, не принимает фокус и нажатия.
  final bool enabled;

  /// Ширина в пикселях сцены или null, чтобы занять всю ширину родителя.
  final int? width;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет рамки в фокусе и выделения.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelTextFieldImpl(
      atlas: atlas,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      hint: hint,
      maxLength: maxLength,
      obscureText: obscureText,
      obscuringCharacter: obscuringCharacter,
      mask: mask,
      keyboardType: keyboardType,
      enabled: enabled,
      width: width,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.primary,
    );
  }
}

/// Реализация PixelTextField: все значения уже подобраны (параметр, тема или умолчание).
class _PixelTextFieldImpl extends StatefulWidget {
  const _PixelTextFieldImpl({
    required this.atlas,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.hint = '',
    this.maxLength,
    this.obscureText = false,
    this.obscuringCharacter = '*',
    this.mask,
    this.keyboardType,
    this.enabled = true,
    this.width,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF3F51B5),
  })  : assert(scale >= 1, 'scale должен быть не меньше 1'),
        assert(width == null || width >= 12, 'width не меньше 12'),
        assert(maxLength == null || maxLength > 0, 'maxLength больше 0'),
        assert(obscuringCharacter.length == 1, 'нужен один символ'),
        assert(mask == null || mask.length > 0, 'mask не может быть пустой');

  final PixelAtlas atlas;

  /// Содержимое поля. Если не задан, поле создаёт свой.
  final TextEditingController? controller;

  /// Управление фокусом. Если не задан, поле создаёт свой.
  final FocusNode? focusNode;

  /// Вызывается при каждом изменении текста.
  final ValueChanged<String>? onChanged;

  /// Вызывается по клавише Enter или кнопке «готово» на клавиатуре.
  final ValueChanged<String>? onSubmitted;

  /// Серая подсказка, пока поле пустое.
  final String hint;

  /// Наибольшее число символов или null без ограничения.
  final int? maxLength;

  /// Режим пароля: вместо символов рисуется [obscuringCharacter].
  final bool obscureText;

  /// Символ, которым закрашиваются символы пароля.
  final String obscuringCharacter;

  /// Шаблон ввода или null. Если задан, [maxLength] не используется (длину
  /// задаёт сама маска).
  final String? mask;

  /// Тип клавиатуры. По умолчанию цифровая для маски только из `#` и
  /// обычная в остальных случаях.
  final TextInputType? keyboardType;

  /// Отключённое поле серое, не принимает фокус и нажатия.
  final bool enabled;

  /// Ширина в пикселях сцены или null, чтобы занять всю ширину родителя.
  final int? width;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет рамки в фокусе и выделения.
  final Color color;

  @override
  State<_PixelTextFieldImpl> createState() => _PixelTextFieldState();
}

// Отбрасывает символы, которых нет в шрифте.
class _GlyphFilter extends TextInputFormatter {
  _GlyphFilter(this.allowed);

  final Set<int> allowed;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.runes.every(allowed.contains)) return newValue;

    // Оставляем разрешённые символы и пересчитываем положение курсора:
    // сколько разрешённых символов было до него.
    String keep(String s) => String.fromCharCodes(s.runes.where(allowed.contains));
    final base = newValue.selection.baseOffset.clamp(0, text.length);
    final extent = newValue.selection.extentOffset.clamp(0, text.length);
    final filtered = keep(text);
    return TextEditingValue(
      text: filtered,
      selection: TextSelection(
        baseOffset: keep(text.substring(0, base)).length,
        extentOffset: keep(text.substring(0, extent)).length,
      ),
    );
  }
}

class _PixelTextFieldState extends State<_PixelTextFieldImpl> {
  // Отступ текста от края поля в пикселях сцены: рамка 1 + зазор 2.
  static const int _inset = 3;

  static const Duration _blink = Duration(milliseconds: 530);

  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  Timer? _blinkTimer;
  bool _caretOn = true;
  double _scroll = 0; // сдвиг текста влево в пикселях сцены
  int _dragAnchor = 0;
  // Двойное нажатие определяем сами: если бы использовался
  // DoubleTapGestureRecognizer, одиночное нажатие (курсор, клавиатура)
  // откладывалось бы на время ожидания второго.
  Timer? _doubleTapTimer; // идёт, пока второе нажатие ещё считается двойным
  Offset _lastTapPos = Offset.zero;

  // Ключ нужен, чтобы заново показать клавиатуру у поля, которое уже
  // в фокусе (см. _requestKeyboard).
  final GlobalKey<EditableTextState> _editableKey = GlobalKey<EditableTextState>();

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    // Форматтеры работают только при вводе, поэтому начальный текст
    // приводим к маске сами.
    final mask = widget.mask;
    if (mask != null) {
      final formatted = applyPixelMask(mask, _controller.text).text;
      if (formatted != _controller.text) {
        _controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
    _controller.addListener(_onChange);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_PixelTextFieldImpl old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_onChange);
      _controller.addListener(_onChange);
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _doubleTapTimer?.cancel();
    _controller.removeListener(_onChange);
    _focus.removeListener(_onFocus);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  // Текст или выделение изменились: курсор снова виден, отсчёт мигания
  // начинается заново.
  void _onChange() {
    _caretOn = true;
    _restartBlink();
    setState(() {});
  }

  void _onFocus() {
    _caretOn = true;
    _restartBlink();
    setState(() {});
  }

  void _restartBlink() {
    _blinkTimer?.cancel();
    if (!_focus.hasFocus) return;
    _blinkTimer = Timer.periodic(_blink, (_) {
      if (mounted) setState(() => _caretOn = !_caretOn);
    });
  }

  PixelFont? get _font => widget.atlas.font(widget.font);

  // Что рисуется вместо текста: сам текст или закрашенные символы.
  String _display(String text) =>
      widget.obscureText ? widget.obscuringCharacter * text.length : text;

  // Расстояние от начала до позиции [i] символа строки [text].
  double _advanceTo(String text, int i) =>
      _advance(_display(text.substring(0, i)));

  // Расстояние от начала текста до позиции после строки [s], в пикселях
  // сцены: ширина строки плюс зазор до следующего символа.
  double _advance(String s) {
    if (s.isEmpty) return 0;
    final layout = layoutText(PixelText(text: s, font: widget.font), widget.atlas);
    return layout == null ? 0 : layout.size.width + (_font?.spacing ?? 0);
  }

  int get _textH =>
      layoutText(PixelText(text: 'A', font: widget.font), widget.atlas)
          ?.size
          .height
          .toInt() ??
      0;

  int get _height => _textH + 8;

  // Номер символа, ближайшего к горизонтальной координате [dx] (обычные
  // пиксели внутри поля).
  int _indexAt(double dx) {
    final x = dx / widget.scale - _inset + _scroll;
    final text = _controller.text;
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i <= text.length; i++) {
      final d = (x - _advanceTo(text, i)).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  // Фокус и клавиатура. Если поле уже в фокусе, а клавиатуру пользователь
  // убрал, requestFocus ничего не сделает: фокус уже есть. Поэтому просим
  // клавиатуру у самого EditableText: он сам откроет соединение с
  // клавиатурой, если его нет, или покажет её снова.
  void _requestKeyboard() {
    final editable = _editableKey.currentState;
    if (editable != null) {
      editable.requestKeyboard();
    } else {
      _focus.requestFocus();
    }
  }

  // Окно времени и расстояние, в которых второе нажатие считается двойным.
  static const Duration _doubleTapWindow = Duration(milliseconds: 300);
  static const double _doubleTapSlop = 24;

  void _tapDown(TapDownDetails d) {
    final isDouble = (_doubleTapTimer?.isActive ?? false) &&
        (d.localPosition - _lastTapPos).distance <= _doubleTapSlop;
    _doubleTapTimer?.cancel();

    if (isDouble) {
      // Второе нажатие: выделяем слово и больше нажатий не ждём.
      _doubleTapTimer = null;
      _doubleTap(d.localPosition.dx);
      return;
    }
    // Первое нажатие: ставим курсор и ждём возможного второго.
    _lastTapPos = d.localPosition;
    _doubleTapTimer = Timer(_doubleTapWindow, () {});
    final i = _indexAt(d.localPosition.dx);
    _controller.selection = TextSelection.collapsed(offset: i);
    _requestKeyboard();
  }

  // Номер символа, внутри которого лежит горизонтальная координата [dx].
  int _charIndexAt(double dx) {
    final x = dx / widget.scale - _inset + _scroll;
    final text = _controller.text;
    for (var k = 0; k < text.length; k++) {
      if (x < _advanceTo(text, k + 1)) return k;
    }
    return text.length - 1;
  }

  static bool _isWordChar(String ch) =>
      RegExp(r'[\p{L}\p{N}_]', unicode: true).hasMatch(ch);

  // Двойное нажатие: выделить слово под пальцем. Если нажали на пробелы
  // или знаки, выделяется такая же группа знаков. В поле пароля слов нет,
  // выделяется весь текст.
  void _doubleTap(double dx) {
    final text = _controller.text;
    if (text.isEmpty) return;
    if (widget.obscureText) {
      _controller.selection =
          TextSelection(baseOffset: 0, extentOffset: text.length);
    } else {
      final c = _charIndexAt(dx);
      final word = _isWordChar(text[c]);
      var start = c;
      var end = c + 1;
      while (start > 0 && _isWordChar(text[start - 1]) == word) {
        start--;
      }
      while (end < text.length && _isWordChar(text[end]) == word) {
        end++;
      }
      _controller.selection = TextSelection(baseOffset: start, extentOffset: end);
    }
    _requestKeyboard();
  }

  Widget _hidden() {
    final font = _font;
    final allowed = font?.glyphs.keys.toSet() ?? <int>{};
    final mask = widget.mask;
    return EditableText(
      key: _editableKey,
      controller: _controller,
      focusNode: _focus,
      obscureText: widget.obscureText,
      obscuringCharacter: widget.obscuringCharacter,
      keyboardType: widget.keyboardType ??
          (mask != null && !mask.contains('A') && !mask.contains('*')
              ? TextInputType.number
              : TextInputType.text),
      style: const TextStyle(color: Color(0x00000000), fontSize: 1),
      cursorColor: const Color(0x00000000),
      backgroundCursorColor: const Color(0x00000000),
      showCursor: false,
      maxLines: 1,
      readOnly: !widget.enabled,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        _GlyphFilter(allowed),
        if (mask != null)
          PixelMaskFormatter(mask)
        else if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final h = _height;
    final textH = _textH;
    final focused = _focus.hasFocus && widget.enabled;
    final text = _controller.text;
    final sel = _controller.selection;

    final base = widget.enabled ? widget.color : const Color(0xFF9E9E9E);
    final border = focused ? base : pixelDarken(base, 0.55);

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      focused: focused,
      value: text,
      child: LayoutBuilder(
        builder: (context, box) {
          assert(widget.width != null || box.hasBoundedWidth,
              'PixelTextField без width нужна ограниченная ширина');
          final w = widget.width ?? (box.maxWidth / scale).floor();
          final innerW = w - 2 * _inset;

          // Прокрутка: курсор (конец выделения) всегда виден.
          final caretX = sel.isValid
              ? _advanceTo(text, sel.extentOffset.clamp(0, text.length))
              : 0.0;
          if (caretX - _scroll > innerW - 1) _scroll = caretX - innerW + 1;
          if (caretX < _scroll) _scroll = caretX;
          // Если текст стал короче, лишнюю прокрутку убираем.
          final total = _advance(_display(text));
          _scroll = math.max(0, math.min(_scroll, math.max(0, total - innerW + 1)));

          final hasSelection = sel.isValid && !sel.isCollapsed;
          final selStart = hasSelection ? _advanceTo(text, sel.start) : 0.0;
          final selEnd = hasSelection ? _advanceTo(text, sel.end) : 0.0;
          final textY = (h - 2 - textH) ~/ 2;

          return SizedBox(
            width: (w * scale).toDouble(),
            height: (h * scale).toDouble(),
            child: Stack(
              children: [
                // Невидимый EditableText: ввод, фокус, клавиатура.
                Positioned.fill(child: Opacity(opacity: 0, child: _hidden())),
                // Рамка и фон.
                Positioned.fill(
                  child: PixelCanvas(
                    scale: scale,
                    atlas: widget.atlas,
                    background: const Color(0x00000000),
                    touchMode: PixelTouchMode.transparent,
                    layers: [
                      PixelLayer(id: 'field-frame', items: [
                        PixelRect(x: 1, y: 0, width: w - 2, height: h, color: pixelDarken(border, 0.5)),
                        PixelRect(x: 0, y: 1, width: w, height: h - 2, color: pixelDarken(border, 0.5)),
                        PixelRect(x: 1, y: 1, width: w - 2, height: h - 2, color: border),
                        PixelRect(
                          x: 2,
                          y: 2,
                          width: w - 4,
                          height: h - 4,
                          color: widget.enabled
                              ? const Color(0xFF1E1E2A)
                              : const Color(0xFF3A3A3A),
                        ),
                      ]),
                    ],
                  ),
                ),
                // Текст, выделение и курсор; ClipRect отрезает то, что
                // ушло за край при прокрутке.
                Positioned(
                  left: (_inset * scale).toDouble(),
                  top: scale.toDouble(),
                  width: (innerW * scale).toDouble(),
                  height: ((h - 2) * scale).toDouble(),
                  child: ClipRect(
                    child: PixelCanvas(
                      scale: scale,
                      atlas: widget.atlas,
                      background: const Color(0x00000000),
                      touchMode: PixelTouchMode.transparent,
                      layers: [
                        PixelLayer(id: 'field-text', items: [
                          if (hasSelection)
                            PixelRect(
                              x: (selStart - _scroll).round(),
                              y: textY - 1,
                              width: math.max(1, (selEnd - selStart).round()),
                              height: textH + 2,
                              color: widget.color,
                            ),
                          if (text.isNotEmpty)
                            PixelText(
                              text: _display(text),
                              font: widget.font,
                              x: (-_scroll).round(),
                              y: textY,
                              color: widget.enabled
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFFBDBDBD),
                            )
                          else if (widget.hint.isNotEmpty)
                            PixelText(
                              text: widget.hint,
                              font: widget.font,
                              x: 0,
                              y: textY,
                              color: const Color(0xFF8A8A9A),
                            ),
                          if (focused && _caretOn && !hasSelection)
                            PixelRect(
                              x: (caretX - _scroll).round(),
                              y: textY - 1,
                              width: 1,
                              height: textH + 2,
                              color: const Color(0xFFFFFFFF),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Нажатия: курсор по нажатию, выделение перетаскиванием.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // Выделение начинается там, где коснулись пальцем, а не
                    // там, где палец вышел за порог перетаскивания.
                    dragStartBehavior: DragStartBehavior.down,
                    onTapDown: widget.enabled ? _tapDown : null,
                    onHorizontalDragStart: widget.enabled
                        ? (d) {
                            _dragAnchor = _indexAt(d.localPosition.dx);
                            _requestKeyboard();
                          }
                        : null,
                    onHorizontalDragUpdate: widget.enabled
                        ? (d) => _controller.selection = TextSelection(
                              baseOffset: _dragAnchor,
                              extentOffset: _indexAt(d.localPosition.dx),
                            )
                        : null,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
