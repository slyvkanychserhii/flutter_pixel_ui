import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Выбор длительности: часы, минуты и секунды (для таймеров и трекеров).
///
/// Три колонки с двоеточиями между ними. В каждой колонке стрелка вверх,
/// число и стрелка вниз:
///
///     ▲ ▲ ▲
///     01:30:00
///     ▼ ▼ ▼
///
/// Значение меняется тремя способами:
///
///  * нажатием на стрелку (на шаг колонки: час, минута или секунда);
///  * удержанием стрелки: после короткой паузы значение меняется
///    непрерывно;
///  * вертикальным перетаскиванием по числу: вверх увеличивает, вниз
///    уменьшает (одно деление на каждые несколько пикселей).
///
/// Значение это [Duration]. Разряды переносятся как на часах: прибавление
/// секунды к 00:00:59 даёт 00:01:00. Значение ограничено диапазоном от нуля
/// до [maxHours] часов 59 минут 59 секунд. Стрелка, которая вывела бы за
/// диапазон, становится серой.
///
/// Для времени суток (будильник) включите [wrapAround]: колонки прокручиваются
/// по кругу независимо друг от друга, и после 00 вниз идёт 23.
///
/// Значение хранит приложение: [onChanged] получает новую длительность.
/// Без [onChanged] элемент отключён. С `showSeconds: false` секунд нет
/// (колонка не показывается, секунды значения не меняются).
///
///     PixelTimePicker(
///       atlas: atlas,
///       value: duration,
///       onChanged: (d) => setState(() => duration = d),
///     )
class PixelTimePicker extends StatelessWidget {
  const PixelTimePicker({
    super.key,
    required this.atlas,
    required this.value,
    required this.onChanged,
    this.maxHours = 99,
    this.showSeconds = true,
    this.wrapAround = false,
    this.font,
    this.scale,
    this.color,
    this.padding = 3,
  });

  final PixelAtlas atlas;

  /// Текущая длительность.
  final Duration value;

  /// Вызывается с новой длительностью. null отключает элемент.
  final ValueChanged<Duration>? onChanged;

  /// Наибольшее число часов (длительность не выше maxHours:59:59).
  final int maxHours;

  /// Показывать ли колонку секунд.
  final bool showSeconds;

  /// Циклический режим, как у циферблата будильника: каждая колонка
  /// прокручивается по кругу сама по себе. Часы идут 00, 23, 22, ... при
  /// уменьшении и 23, 00, 01, ... при увеличении (при `maxHours: 23`),
  /// минуты и секунды 59, 58, ..., 00, 59. Перенос в соседнюю колонку не
  /// происходит, а стрелки никогда не становятся серыми. Без [wrapAround]
  /// колонки связаны переносом разрядов и значение ограничено диапазоном.
  final bool wrapAround;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет стрелок.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  /// Горизонтальный отступ вокруг числа в пикселях сцены.
  final int padding;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelTimePickerImpl(
      atlas: atlas,
      value: value,
      onChanged: onChanged,
      maxHours: maxHours,
      showSeconds: showSeconds,
      wrapAround: wrapAround,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.primary,
      padding: padding,
    );
  }
}

/// Реализация PixelTimePicker: все значения уже подобраны (параметр, тема или умолчание).
class _PixelTimePickerImpl extends StatefulWidget {
  const _PixelTimePickerImpl({
    required this.atlas,
    required this.value,
    required this.onChanged,
    this.maxHours = 99,
    this.showSeconds = true,
    this.wrapAround = false,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF3F51B5),
    this.padding = 3,
  })  : assert(maxHours >= 0, 'maxHours не может быть отрицательным'),
        assert(scale >= 1, 'scale должен быть не меньше 1'),
        assert(padding >= 0, 'padding не может быть отрицательным');

  final PixelAtlas atlas;

  /// Текущая длительность.
  final Duration value;

  /// Вызывается с новой длительностью. null отключает элемент.
  final ValueChanged<Duration>? onChanged;

  /// Наибольшее число часов (длительность не выше maxHours:59:59).
  final int maxHours;

  /// Показывать ли колонку секунд.
  final bool showSeconds;

  /// Циклический режим, как у циферблата будильника: каждая колонка
  /// прокручивается по кругу сама по себе. Часы идут 00, 23, 22, ... при
  /// уменьшении и 23, 00, 01, ... при увеличении (при `maxHours: 23`),
  /// минуты и секунды 59, 58, ..., 00, 59. Перенос в соседнюю колонку не
  /// происходит, а стрелки никогда не становятся серыми. Без [wrapAround]
  /// колонки связаны переносом разрядов и значение ограничено диапазоном.
  final bool wrapAround;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет стрелок.
  final Color color;

  /// Горизонтальный отступ вокруг числа в пикселях сцены.
  final int padding;

  @override
  State<_PixelTimePickerImpl> createState() => _PixelTimePickerState();
}

// Колонки по порядку; шаг в секундах.
enum _Unit {
  hours(3600),
  minutes(60),
  seconds(1);

  const _Unit(this.step);

  /// Шаг колонки в секундах. Поле называется не seconds, чтобы не совпадать
  /// с одноимённым значением перечисления.
  final int step;
}

// Куда попало нажатие внутри колонки.
enum _Zone { up, value, down }

class _PixelTimePickerState extends State<_PixelTimePickerImpl> {
  // Пауза перед повтором и интервал повтора при удержании стрелки.
  static const Duration _repeatDelay = Duration(milliseconds: 400);
  static const Duration _repeatEvery = Duration(milliseconds: 80);

  // Размеры в пикселях сцены.
  static const int _arrowH = 8; // высота кнопки со стрелкой
  static const int _dragStep = 6; // пикселей сцены перетаскивания на деление
  static const int _colonW = 6; // место под двоеточие между колонками

  _Unit? _pressedUnit;
  int _pressedDir = 0; // 1 вверх, -1 вниз
  Timer? _timer;

  _Unit? _dragUnit;
  double _dragAcc = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_Unit> get _units => [
        _Unit.hours,
        _Unit.minutes,
        if (widget.showSeconds) _Unit.seconds,
      ];

  Duration get _max =>
      Duration(hours: widget.maxHours, minutes: 59, seconds: 59);

  // Размер строки в пикселях сцены (0, если шрифта нет в атласе).
  Size _textSize(String text) =>
      layoutText(PixelText(text: text, font: widget.font), widget.atlas)
          ?.size ??
      Size.zero;

  // Число часов с нужным числом цифр (не меньше двух).
  int get _hourDigits => math.max(2, '${widget.maxHours}'.length);

  String _label(_Unit unit) {
    final v = widget.value;
    return switch (unit) {
      _Unit.hours => '${v.inHours}'.padLeft(_hourDigits, '0'),
      _Unit.minutes => '${v.inMinutes % 60}'.padLeft(2, '0'),
      _Unit.seconds => '${v.inSeconds % 60}'.padLeft(2, '0'),
    };
  }

  // Геометрия в пикселях сцены. Ширина колонки рассчитана по самому
  // широкому числу, поэтому элемент не меняет размер при смене значения.
  ({
    int colonW, // место под двоеточие между колонками
    int valueH, // высота поля с числом
    int height,
    int total,
    int textH,
    List<int> xs, // левый край колонки (вместе с рамкой)
  }) _geometry() {
    final hours = _textSize('0' * _hourDigits);
    final two = _textSize('00');
    final textH = math.max(hours.height, two.height).toInt();
    final widths = [
      for (final u in _units)
        (u == _Unit.hours ? hours.width : two.width).toInt() +
            2 * widget.padding,
    ];
    const colonW = _colonW;
    final valueH = textH + 4;

    final xs = <int>[];
    var x = 0;
    for (var i = 0; i < widths.length; i++) {
      xs.add(x);
      x += widths[i] + 2 + (i < widths.length - 1 ? colonW : 0);
    }
    return (
      colonW: colonW,
      valueH: valueH,
      // рамка + стрелка + линия + число + линия + стрелка + рамка
      height: 1 + _arrowH + 1 + valueH + 1 + _arrowH + 1,
      total: x,
      textH: textH,
      xs: xs,
    );
  }

  // Внутренняя ширина колонки номер [i] (часы могут быть шире).
  int _unitInnerW(int i) {
    final g = _geometry();
    final next = i + 1 < g.xs.length ? g.xs[i + 1] - g.colonW : g.total;
    return next - g.xs[i] - 2;
  }

  // Какая колонка и зона под точкой ([dx], [dy] в обычных пикселях) или null.
  (int, _Zone)? _hit(double dx, double dy) {
    final g = _geometry();
    final x = dx / widget.scale;
    final y = dy / widget.scale;
    for (var i = 0; i < g.xs.length; i++) {
      if (x >= g.xs[i] && x < g.xs[i] + _unitInnerW(i) + 2) {
        if (y < 1 + _arrowH) return (i, _Zone.up);
        if (y >= 1 + _arrowH + 1 + g.valueH) return (i, _Zone.down);
        return (i, _Zone.value);
      }
    }
    return null;
  }

  // Допустимо ли изменение колонки [unit] в сторону [dir].
  bool _canStep(_Unit unit, int dir) {
    if (widget.wrapAround) return true; // по кругу можно всегда
    final next = widget.value + Duration(seconds: dir * unit.step);
    return next >= Duration.zero && next <= _max;
  }

  // Изменяет значение на [count] шагов колонки [unit] (count может быть
  // отрицательным). Выходящее за диапазон значение ограничивается. Возвращает
  // false, если значение не изменилось.
  bool _step(_Unit unit, int count) {
    final next = widget.wrapAround ? _wrapped(unit, count) : _clamped(unit, count);
    if (next == widget.value) return false;
    widget.onChanged!(next);
    return true;
  }

  // Обычный режим: разряды переносятся, значение ограничено диапазоном.
  Duration _clamped(_Unit unit, int count) {
    final seconds = widget.value.inSeconds + count * unit.step;
    return Duration(seconds: seconds.clamp(0, _max.inSeconds));
  }

  // Циклический режим: меняется только одна колонка, по кругу в своём
  // диапазоне (часы 0..maxHours, минуты и секунды 0..59), остальные не
  // затрагиваются. Операция % в Dart для положительного делителя всегда даёт
  // неотрицательный результат, поэтому 0 - 1 даёт последнее значение.
  Duration _wrapped(_Unit unit, int count) {
    final v = widget.value;
    var hours = v.inHours;
    var minutes = v.inMinutes % 60;
    var seconds = v.inSeconds % 60;
    switch (unit) {
      case _Unit.hours:
        hours = (hours + count) % (widget.maxHours + 1);
      case _Unit.minutes:
        minutes = (minutes + count) % 60;
      case _Unit.seconds:
        seconds = (seconds + count) % 60;
    }
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  void _stopRepeat() {
    _timer?.cancel();
    if (_pressedUnit != null) {
      setState(() {
        _pressedUnit = null;
        _pressedDir = 0;
      });
    }
  }

  void _pointerDown(PointerDownEvent e) {
    final hit = _hit(e.localPosition.dx, e.localPosition.dy);
    if (hit == null || hit.$2 == _Zone.value) return;
    final unit = _units[hit.$1];
    final dir = hit.$2 == _Zone.up ? 1 : -1;
    if (!_canStep(unit, dir)) return;

    setState(() {
      _pressedUnit = unit;
      _pressedDir = dir;
    });
    _step(unit, dir);
    _timer?.cancel();
    // Сначала пауза, затем регулярный повтор; на границе повтор прекращается.
    _timer = Timer(_repeatDelay, () {
      void tick() {
        if (!_canStep(unit, dir)) {
          _timer?.cancel();
          return;
        }
        _step(unit, dir);
      }

      tick();
      _timer = Timer.periodic(_repeatEvery, (_) => tick());
    });
  }

  List<PixelLayer> _buildLayers(bool enabled) {
    final g = _geometry();
    final base = enabled ? widget.color : const Color(0xFF9E9E9E);
    final border = pixelDarken(base, 0.6);
    final idle = pixelDarken(base, 0.55);
    final h = g.height;
    const valueY = 1 + _arrowH + 1;
    final downY = valueY + g.valueH + 1;
    final textY = valueY + ((g.valueH - g.textH) / 2).round();
    const white = Color(0xFFFFFFFF);

    final items = <PixelObject>[];
    for (var i = 0; i < _units.length; i++) {
      final unit = _units[i];
      final x = g.xs[i];
      final inner = _unitInnerW(i);
      final w = inner + 2;

      Color arrowFill(int dir) {
        if (!enabled || !_canStep(unit, dir)) return idle;
        return _pressedUnit == unit && _pressedDir == dir
            ? pixelDarken(base, 0.3)
            : base;
      }

      Color arrowColor(int dir) =>
          enabled && _canStep(unit, dir) ? white : const Color(0xFF9E9E9E);

      // Рамка со срезанными углами; линии между зонами это её цвет.
      items
        ..add(PixelRect(x: x + 1, y: 0, width: w - 2, height: h, color: border))
        ..add(PixelRect(x: x, y: 1, width: w, height: h - 2, color: border))
        // Стрелка вверх, число, стрелка вниз.
        ..add(PixelRect(x: x + 1, y: 1, width: inner, height: _arrowH, color: arrowFill(1)))
        ..add(PixelRect(x: x + 1, y: valueY, width: inner, height: g.valueH, color: idle))
        ..add(PixelRect(x: x + 1, y: downY, width: inner, height: _arrowH, color: arrowFill(-1)));

      // Треугольники: три строки 1, 3 и 5 пикселей.
      final ax = x + 1 + ((inner - 5) / 2).floor();
      final up = arrowColor(1);
      final down = arrowColor(-1);
      items
        ..add(PixelRect(x: ax + 2, y: 3, width: 1, height: 1, color: up))
        ..add(PixelRect(x: ax + 1, y: 4, width: 3, height: 1, color: up))
        ..add(PixelRect(x: ax, y: 5, width: 5, height: 1, color: up))
        ..add(PixelRect(x: ax, y: downY + 2, width: 5, height: 1, color: down))
        ..add(PixelRect(x: ax + 1, y: downY + 3, width: 3, height: 1, color: down))
        ..add(PixelRect(x: ax + 2, y: downY + 4, width: 1, height: 1, color: down));

      final label = _label(unit);
      items.add(PixelText(
        text: label,
        font: widget.font,
        x: x + 1 + ((inner - _textSize(label).width) / 2).round(),
        y: textY,
        color: enabled ? white : const Color(0xFFBDBDBD),
      ));

      // Двоеточие после колонки, кроме последней. Это два квадрата 2 x 2,
      // нарисованные цветом элемента, а не глиф шрифта: так оно заметно и
      // на светлом, и на тёмном фоне (глиф был бы белым и в один пиксель).
      if (i < _units.length - 1) {
        final dotX = x + w + (_colonW - 2) ~/ 2;
        final mid = valueY + g.valueH ~/ 2;
        items
          ..add(PixelRect(x: dotX, y: mid - 3, width: 2, height: 2, color: base))
          ..add(PixelRect(x: dotX, y: mid + 1, width: 2, height: 2, color: base));
      }
    }
    return [PixelLayer(id: 'time-picker', items: items)];
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final g = _geometry();
    final scale = widget.scale;

    return Semantics(
      enabled: enabled,
      value: _units.map(_label).join(':'),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: enabled ? _pointerDown : null,
        onPointerUp: enabled ? (_) => _stopRepeat() : null,
        onPointerCancel: enabled ? (_) => _stopRepeat() : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Перетаскивание по числу: вверх увеличивает, вниз уменьшает.
          onVerticalDragStart: enabled
              ? (d) {
                  final hit = _hit(d.localPosition.dx, d.localPosition.dy);
                  _dragUnit = hit != null && hit.$2 == _Zone.value
                      ? _units[hit.$1]
                      : null;
                  _dragAcc = 0;
                }
              : null,
          onVerticalDragUpdate: enabled
              ? (d) {
                  final unit = _dragUnit;
                  if (unit == null) return;
                  _dragAcc -= d.delta.dy; // вверх даёт плюс
                  final steps = (_dragAcc / (_dragStep * scale)).truncate();
                  if (steps != 0) {
                    _dragAcc -= steps * _dragStep * scale;
                    _step(unit, steps);
                  }
                }
              : null,
          child: SizedBox(
            width: (g.total * scale).toDouble(),
            height: (g.height * scale).toDouble(),
            child: PixelCanvas(
              scale: scale,
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
