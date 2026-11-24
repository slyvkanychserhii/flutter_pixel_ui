import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Шаговый счётчик: кнопка «минус», текущее число и кнопка «плюс».
///
/// Весь элемент это один холст: общая рамка со срезанными углами, слева
/// «−», по центру число шрифтом из атласа, справа «+». Значки рисуются
/// примитивами, поэтому шрифту нужны только цифры.
///
/// Значение хранит приложение: [onChanged] получает новое число, уже
/// ограниченное диапазоном [min]..[max]. Если держать палец на «−» или «+»,
/// значение меняется непрерывно (после короткой паузы, затем с частотой
/// около 12 раз в секунду). Ещё значение можно менять перетаскиванием по
/// числу: вправо увеличивает, влево уменьшает (одно деление [step] на
/// каждые несколько пикселей), это удобно при большом диапазоне.
/// На границе диапазона соответствующая сторона становится серой и не
/// реагирует. Без [onChanged] элемент отключён.
///
/// Значение меняется в момент касания (а не отпускания), как у кнопок
/// управления в играх; внутри прокручиваемого списка касание по счётчику
/// тоже меняет значение.
class PixelStepper extends StatelessWidget {
  const PixelStepper({
    super.key,
    required this.atlas,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.font,
    this.scale,
    this.color,
    this.padding = 3,
  });

  final PixelAtlas atlas;

  final int value;

  /// Вызывается с новым значением. null отключает элемент.
  final ValueChanged<int>? onChanged;

  final int min;

  final int max;

  /// На сколько меняется значение за одно нажатие.
  final int step;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет кнопок «−» и «+».
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  /// Горизонтальный отступ вокруг числа в пикселях сцены.
  final int padding;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelStepperImpl(
      atlas: atlas,
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      step: step,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.primary,
      padding: padding,
    );
  }
}

/// Реализация PixelStepper: все значения уже подобраны (параметр, тема или умолчание).
class _PixelStepperImpl extends StatefulWidget {
  const _PixelStepperImpl({
    required this.atlas,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF3F51B5),
    this.padding = 3,
  })  : assert(min < max, 'min должен быть меньше max'),
        assert(value >= min && value <= max, 'value между min и max'),
        assert(step > 0, 'step должен быть больше 0'),
        assert(scale >= 1, 'scale должен быть не меньше 1'),
        assert(padding >= 0, 'padding не может быть отрицательным');

  final PixelAtlas atlas;

  final int value;

  /// Вызывается с новым значением. null отключает элемент.
  final ValueChanged<int>? onChanged;

  final int min;
  final int max;

  /// На сколько меняется значение за одно нажатие.
  final int step;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет кнопок «−» и «+».
  final Color color;

  /// Горизонтальный отступ вокруг числа в пикселях сцены.
  final int padding;

  @override
  State<_PixelStepperImpl> createState() => _PixelStepperState();
}

class _PixelStepperState extends State<_PixelStepperImpl> {
  // Пауза перед началом повтора и интервал повтора при удержании.
  static const Duration _repeatDelay = Duration(milliseconds: 400);
  static const Duration _repeatEvery = Duration(milliseconds: 80);

  // Ширина кнопки «−» или «+» в пикселях сцены.
  static const int _buttonW = 11;

  // Сколько пикселей сцены перетаскивания по числу дают одно деление.
  static const int _dragStep = 6;

  int _pressedSide = 0; // -1 «минус», 1 «плюс», 0 ничего не нажато
  Timer? _timer;

  bool _dragging = false; // перетаскивание началось на числе
  double _dragAcc = 0; // накопленный сдвиг в обычных пикселях

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Размер подписи в пикселях сцены (0, если шрифта нет в атласе).
  Size _textSize(String text) =>
      layoutText(PixelText(text: text, font: widget.font), widget.atlas)
          ?.size ??
      Size.zero;

  // Геометрия в пикселях сцены. Ширина поля числа рассчитана на самое
  // широкое из значений (min или max), чтобы элемент не менял размер.
  ({int valueW, int total, int height, int textH}) _geometry() {
    final a = _textSize('${widget.min}');
    final b = _textSize('${widget.max}');
    final textW = math.max(a.width, b.width).toInt();
    final textH = math.max(a.height, b.height).toInt();
    final valueW = textW + 2 * widget.padding;
    return (
      valueW: valueW,
      // рамка + кнопка + линия + число + линия + кнопка + рамка
      total: 1 + _buttonW + 1 + valueW + 1 + _buttonW + 1,
      height: math.max(textH + 8, _buttonW),
      textH: textH,
    );
  }

  // Какая сторона под горизонтальной координатой [dx] (обычные пиксели).
  int _sideAt(double dx) {
    final g = _geometry();
    final x = dx / widget.scale;
    if (x < 1 + _buttonW + 1) return -1;
    if (x >= g.total - (1 + _buttonW + 1)) return 1;
    return 0;
  }

  bool _canStep(int side) => side < 0
      ? widget.value > widget.min
      : widget.value < widget.max;

  // Один шаг в сторону [side]. На границе повтор прекращается.
  void _apply(int side) {
    if (!_canStep(side)) {
      _timer?.cancel();
      return;
    }
    final v = (widget.value + side * widget.step).clamp(widget.min, widget.max);
    if (v != widget.value) widget.onChanged!(v);
  }

  void _down(PointerDownEvent e) {
    final side = _sideAt(e.localPosition.dx);
    if (side == 0 || !_canStep(side)) return;
    setState(() => _pressedSide = side);
    _apply(side);
    _timer?.cancel();
    // Сначала пауза, затем регулярный повтор.
    _timer = Timer(_repeatDelay, () {
      _apply(side);
      _timer = Timer.periodic(_repeatEvery, (_) => _apply(side));
    });
  }

  void _up() {
    _timer?.cancel();
    if (_pressedSide != 0) setState(() => _pressedSide = 0);
  }

  // Перетаскивание по числу: накопленный сдвиг переводится в целые деления.
  void _dragUpdate(double dx) {
    if (!_dragging) return;
    _dragAcc += dx;
    final steps = (_dragAcc / (_dragStep * widget.scale)).truncate();
    if (steps == 0) return;
    _dragAcc -= steps * _dragStep * widget.scale;
    final v = (widget.value + steps * widget.step).clamp(widget.min, widget.max);
    if (v != widget.value) widget.onChanged!(v);
  }

  List<PixelLayer> _buildLayers(bool enabled) {
    final g = _geometry();
    final base = enabled ? widget.color : const Color(0xFF9E9E9E);
    final border = pixelDarken(base, 0.6);
    final idle = pixelDarken(base, 0.55);
    final h = g.height;
    final w = g.total;
    final plusX = w - 1 - _buttonW;
    final cy = h ~/ 2;

    // Заливка и значок одной стороны. [x] левый край кнопки.
    List<PixelObject> side(int sideId, int x) {
      final active = enabled && _canStep(sideId);
      final pressed = _pressedSide == sideId && active;
      final fill = !active
          ? idle
          : pressed
              ? pixelDarken(base, 0.3)
              : base;
      final icon =
          active ? const Color(0xFFFFFFFF) : const Color(0xFF9E9E9E);
      return [
        PixelRect(x: x, y: 1, width: _buttonW, height: h - 2, color: fill),
        // Горизонтальная черта (общая для «−» и «+»), 5 x 1 по центру.
        PixelRect(x: x + 3, y: cy, width: 5, height: 1, color: icon),
        if (sideId > 0)
          PixelRect(x: x + 5, y: cy - 2, width: 1, height: 5, color: icon),
      ];
    }

    final text = '${widget.value}';
    final textSize = _textSize(text);

    return [
      PixelLayer(id: 'stepper', items: [
        PixelRect(x: 1, y: 0, width: w - 2, height: h, color: border),
        PixelRect(x: 0, y: 1, width: w, height: h - 2, color: border),
        ...side(-1, 1),
        // Поле числа: тёмная заливка между линиями.
        PixelRect(
            x: 1 + _buttonW + 1, y: 1, width: g.valueW, height: h - 2, color: idle),
        ...side(1, plusX),
        PixelText(
          text: text,
          font: widget.font,
          x: 1 + _buttonW + 1 + ((g.valueW - textSize.width) / 2).round(),
          y: ((h - g.textH) / 2).round(),
          color: const Color(0xFFFFFFFF),
        ),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final g = _geometry();

    return Semantics(
      enabled: enabled,
      value: '${widget.value}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Горизонтальное перетаскивание работает, только если началось на
        // числе: у кнопок есть своё удержание.
        onHorizontalDragStart: enabled
            ? (d) {
                _dragging = _sideAt(d.localPosition.dx) == 0;
                _dragAcc = 0;
              }
            : null,
        onHorizontalDragUpdate: enabled ? (d) => _dragUpdate(d.delta.dx) : null,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: enabled ? _down : null,
          onPointerUp: enabled ? (_) => _up() : null,
          onPointerCancel: enabled ? (_) => _up() : null,
          child: SizedBox(
            width: (g.total * widget.scale).toDouble(),
            height: (g.height * widget.scale).toDouble(),
            child: PixelCanvas(
              scale: widget.scale,
              atlas: widget.atlas,
              background: const Color(0x00000000),
              touchMode: PixelTouchMode.transparent,
              layers: _buildLayers(enabled),
            ),
          ),
        ),
      ),
    );
  }
}
