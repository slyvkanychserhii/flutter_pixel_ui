import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Пиксельная радиокнопка: один из нескольких взаимоисключающих вариантов.
///
/// Рисуется только примитивами, атлас не нужен. Размер 11 x 11 пикселей
/// сцены, умноженный на [scale]. Группа это несколько радиокнопок с общим
/// [groupValue]: выбрана та, у которой [value] равен ему.
///
///     PixelRadio<int>(value: 0, groupValue: level, onChanged: setLevel)
///     PixelRadio<int>(value: 1, groupValue: level, onChanged: setLevel)
///
/// [onChanged] вызывается только при нажатии на невыбранную кнопку, со
/// значением этой кнопки. Без [onChanged] кнопка отключена.
class PixelRadio<T> extends StatelessWidget {
  const PixelRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.scale,
    this.color,
  });

  /// Значение этой кнопки.
  final T value;

  /// Выбранное значение группы.
  final T? groupValue;

  /// Вызывается при нажатии на невыбранную кнопку. null отключает её.
  final ValueChanged<T>? onChanged;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 3.
  final int? scale;

  /// Цвет точки выбранной кнопки.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelRadioImpl<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      scale: scale ?? theme.scale ?? 3,
      color: color ?? theme.primary,
    );
  }
}

/// Реализация PixelRadio: все значения уже подобраны (параметр, тема или умолчание).
class _PixelRadioImpl<T> extends StatelessWidget {
  const _PixelRadioImpl({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.scale = 3,
    this.color = const Color(0xFF3F51B5),
  }) : assert(scale >= 1, 'scale должен быть не меньше 1');

  /// Значение этой кнопки.
  final T value;

  /// Выбранное значение группы.
  final T? groupValue;

  /// Вызывается при нажатии на невыбранную кнопку. null отключает её.
  final ValueChanged<T>? onChanged;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет точки выбранной кнопки.
  final Color color;

  // Размер в пикселях сцены: окружность радиуса 5 с центром в (5, 5).
  static const int _size = 11;

  bool get _selected => value == groupValue;

  List<PixelLayer> _buildLayers(bool enabled) {
    final base = enabled ? color : const Color(0xFF9E9E9E);
    return [
      PixelLayer(id: 'radio', items: [
        PixelCircle(cx: 5, cy: 5, radius: 5, color: pixelDarken(base, 0.6)),
        PixelCircle(
          cx: 5,
          cy: 5,
          radius: 4,
          color: enabled ? const Color(0xFFEEEEEE) : const Color(0xFFBDBDBD),
        ),
        if (_selected) PixelCircle(cx: 5, cy: 5, radius: 2, color: base),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      checked: _selected,
      inMutuallyExclusiveGroup: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled && !_selected ? () => onChanged!(value) : null,
        child: SizedBox(
          width: (_size * scale).toDouble(),
          height: (_size * scale).toDouble(),
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
