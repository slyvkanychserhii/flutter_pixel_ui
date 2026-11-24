import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Пиксельный флажок (галочка в квадрате).
///
/// Рисуется только примитивами, атлас не нужен. Размер 10 x 10 пикселей
/// сцены, умноженный на [scale]. Стиль как у [PixelSwitch] и [PixelButton]:
/// тёмная рамка со срезанными углами. Подпись рядом кладётся обычным
/// виджетом (например, Row с Text).
///
/// Значение хранит приложение: при нажатии вызывается [onChanged] с
/// противоположным значением. Без [onChanged] флажок отключён.
class PixelCheckbox extends StatelessWidget {
  const PixelCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.scale,
    this.color,
  });

  /// Отмечен ли флажок.
  final bool value;

  /// Вызывается при нажатии с новым значением. null отключает флажок.
  final ValueChanged<bool>? onChanged;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 3.
  final int? scale;

  /// Цвет заливки отмеченного флажка.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelCheckboxImpl(
      value: value,
      onChanged: onChanged,
      scale: scale ?? theme.scale ?? 3,
      color: color ?? theme.primary,
    );
  }
}

/// Реализация PixelCheckbox: все значения уже подобраны (параметр, тема или умолчание).
class _PixelCheckboxImpl extends StatelessWidget {
  const _PixelCheckboxImpl({
    required this.value,
    required this.onChanged,
    this.scale = 3,
    this.color = const Color(0xFF3F51B5),
  }) : assert(scale >= 1, 'scale должен быть не меньше 1');

  /// Отмечен ли флажок.
  final bool value;

  /// Вызывается при нажатии с новым значением. null отключает флажок.
  final ValueChanged<bool>? onChanged;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет заливки отмеченного флажка.
  final Color color;

  // Размер в пикселях сцены.
  static const int _size = 10;

  List<PixelLayer> _buildLayers(bool enabled) {
    final base = enabled ? color : const Color(0xFF9E9E9E);
    final border = pixelDarken(base, 0.6);
    final fill = value ? base : const Color(0xFFEEEEEE);
    const mark = Color(0xFFFFFFFF);

    return [
      PixelLayer(id: 'checkbox', items: [
        // Рамка со срезанными углами и заливка.
        PixelRect(x: 1, y: 0, width: _size - 2, height: _size, color: border),
        PixelRect(x: 0, y: 1, width: _size, height: _size - 2, color: border),
        PixelRect(
            x: 1, y: 1, width: _size - 2, height: _size - 2, color: fill),
        // Галочка в два пикселя толщиной: две одинаковые ломаные, вторая
        // на пиксель выше.
        if (value) ...[
          const PixelLine(x0: 2, y0: 5, x1: 4, y1: 7, color: mark),
          const PixelLine(x0: 4, y0: 7, x1: 7, y1: 4, color: mark),
          const PixelLine(x0: 2, y0: 4, x1: 4, y1: 6, color: mark),
          const PixelLine(x0: 4, y0: 6, x1: 7, y1: 3, color: mark),
        ],
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
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
