import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Пиксельный ползунок: выбор числа от [min] до [max] перетаскиванием.
///
/// Рисуется только примитивами, атлас не нужен. Ширина [width] в пикселях
/// сцены, высота 12, всё умножается на [scale]. Бегунок стоит на целых
/// пикселях. Нажатие в любое место полосы переносит туда бегунок, а
/// перетаскивание двигает его.
///
/// С [divisions] значение прыгает по делениям: например, min 0, max 10,
/// divisions 10 даёт целые числа от 0 до 10.
///
/// Значение хранит приложение: при движении вызывается [onChanged] с новым
/// значением (только когда оно изменилось). Без [onChanged] ползунок
/// отключён.
class PixelSlider extends StatelessWidget {
  const PixelSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.width = 60,
    this.scale,
    this.color,
    this.trackColor,
  });

  /// Текущее значение от [min] до [max].
  final double value;

  /// Вызывается при изменении значения. null отключает ползунок.
  final ValueChanged<double>? onChanged;

  final double min;

  final double max;

  /// Число делений или null для плавного изменения.
  final int? divisions;

  /// Ширина в пикселях сцены.
  final int width;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 3.
  final int? scale;

  /// Цвет пройденной части полосы.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  /// Цвет оставшейся части полосы.
  /// null: берётся из [PixelTheme] (track).
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelSliderImpl(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      width: width,
      scale: scale ?? theme.scale ?? 3,
      color: color ?? theme.primary,
      trackColor: trackColor ?? theme.track,
    );
  }
}

/// Реализация PixelSlider: все значения уже подобраны (параметр, тема или умолчание).
class _PixelSliderImpl extends StatelessWidget {
  const _PixelSliderImpl({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.width = 60,
    this.scale = 3,
    this.color = const Color(0xFF3F51B5),
    this.trackColor = const Color(0xFF424242),
  })  : assert(max > min, 'max должен быть больше min'),
        assert(value >= min && value <= max, 'value между min и max'),
        assert(divisions == null || divisions > 0, 'divisions больше 0'),
        assert(width >= 12, 'width не меньше 12'),
        assert(scale >= 1, 'scale должен быть не меньше 1');

  /// Текущее значение от [min] до [max].
  final double value;

  /// Вызывается при изменении значения. null отключает ползунок.
  final ValueChanged<double>? onChanged;

  final double min;
  final double max;

  /// Число делений или null для плавного изменения.
  final int? divisions;

  /// Ширина в пикселях сцены.
  final int width;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет пройденной части полосы.
  final Color color;

  /// Цвет оставшейся части полосы.
  final Color trackColor;

  // Размеры в пикселях сцены.
  static const int _height = 12;
  static const int _thumbW = 8;

  // Значение, соответствующее горизонтальной координате [dx] (в обычных
  // пикселях внутри виджета). Центр бегунка встаёт под палец.
  double _valueAt(double dx) {
    final sceneX = dx / scale;
    var t = ((sceneX - _thumbW / 2) / (width - _thumbW)).clamp(0.0, 1.0).toDouble();
    final steps = divisions;
    if (steps != null) t = (t * steps).round() / steps;
    return min + t * (max - min);
  }

  void _update(double dx) {
    final v = _valueAt(dx);
    if (v != value) onChanged!(v);
  }

  List<PixelLayer> _buildLayers(bool enabled) {
    final base = enabled ? color : const Color(0xFF9E9E9E);
    final trackBorder = pixelDarken(trackColor, 0.5);
    final thumbBorder = pixelDarken(base, 0.6);
    final t = (value - min) / (max - min);
    final thumbX = (t * (width - _thumbW)).round();
    // Пройденная часть идёт от левого края до середины бегунка.
    final filled = math.min(thumbX + _thumbW ~/ 2, width - 2);

    final items = <PixelObject>[
      // Полоса высотой 6: рамка со срезанными углами, фон, пройденная часть.
      PixelRect(x: 1, y: 3, width: width - 2, height: 6, color: trackBorder),
      PixelRect(x: 0, y: 4, width: width, height: 4, color: trackBorder),
      PixelRect(x: 1, y: 4, width: width - 2, height: 4, color: trackColor),
      PixelRect(x: 1, y: 4, width: filled, height: 4, color: base),
      // Блик сверху на пройденной части: полоса выглядит объёмной.
      PixelRect(x: 1, y: 4, width: filled, height: 1, color: pixelLighten(base, 0.35)),
    ];

    // Риски делений: тёмные штрихи в полосе (на пройденной части темнее её цвета).
    final steps = divisions;
    if (steps != null && steps <= (width - _thumbW) ~/ 3) {
      for (var i = 0; i <= steps; i++) {
        final x = (i * (width - _thumbW) / steps).round() + _thumbW ~/ 2;
        final passed = x < filled;
        items.add(PixelRect(
          x: x,
          y: 5,
          width: 1,
          height: 2,
          color: passed ? pixelDarken(base, 0.45) : pixelDarken(trackColor, 0.4),
        ));
      }
    }

    // Бегунок 8x12 в стиле кнопки: цветная заливка, светлый верх, тёмный низ,
    // тёмная рамка со срезанными углами и «ручка» из двух штрихов.
    final fill = enabled ? base : const Color(0xFFBDBDBD);
    items.addAll([
      PixelRect(x: thumbX + 1, y: 0, width: _thumbW - 2, height: _height, color: thumbBorder),
      PixelRect(x: thumbX, y: 1, width: _thumbW, height: _height - 2, color: thumbBorder),
      PixelRect(x: thumbX + 1, y: 1, width: _thumbW - 2, height: _height - 2, color: fill),
      PixelRect(x: thumbX + 1, y: 1, width: _thumbW - 2, height: 1, color: pixelLighten(fill, 0.45)),
      PixelRect(x: thumbX + 1, y: _height - 3, width: _thumbW - 2, height: 2, color: pixelDarken(fill, 0.25)),
      PixelRect(x: thumbX + 3, y: 4, width: 1, height: 4, color: pixelDarken(fill, 0.4)),
      PixelRect(x: thumbX + 4, y: 4, width: 1, height: 4, color: pixelLighten(fill, 0.3)),
    ]);

    return [PixelLayer(id: 'slider', items: items)];
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      slider: true,
      enabled: enabled,
      value: value.toStringAsFixed(2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (d) => _update(d.localPosition.dx) : null,
        onHorizontalDragStart:
            enabled ? (d) => _update(d.localPosition.dx) : null,
        onHorizontalDragUpdate:
            enabled ? (d) => _update(d.localPosition.dx) : null,
        child: SizedBox(
          width: (width * scale).toDouble(),
          height: (_height * scale).toDouble(),
          child: PixelCanvas(
            scale: scale,
            background: const Color(0x00000000),
            touchMode: PixelTouchMode.transparent,
            layers: _buildLayers(enabled),
          ),
        ),
      ),
    );
  }
}
