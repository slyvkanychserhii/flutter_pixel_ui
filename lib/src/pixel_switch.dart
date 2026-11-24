import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Пиксельный переключатель (включён / выключен).
///
/// Рисуется только примитивами, атлас не нужен. Бегунок едет по целым
/// пикселям сцены, поэтому и в движении картинка остаётся пиксельной.
/// Размер в пикселях сцены 22 x 12, умножается на [scale].
///
/// Без [onChanged] переключатель отключён: серый и не нажимается.
class PixelSwitch extends StatelessWidget {
  const PixelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.scale,
    this.onColor,
    this.offColor,
  });

  /// Включён ли переключатель.
  final bool value;

  /// Вызывается при нажатии с новым значением. null отключает переключатель.
  final ValueChanged<bool>? onChanged;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 3.
  final int? scale;

  /// null: берётся из [PixelTheme] (success).
  final Color? onColor;

  /// null: берётся из [PixelTheme] (off).
  final Color? offColor;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelSwitchImpl(
      value: value,
      onChanged: onChanged,
      scale: scale ?? theme.scale ?? 3,
      onColor: onColor ?? theme.success,
      offColor: offColor ?? theme.off,
    );
  }
}

/// Реализация PixelSwitch: все значения уже подобраны (параметр, тема или умолчание).
class _PixelSwitchImpl extends StatelessWidget {
  const _PixelSwitchImpl({
    required this.value,
    required this.onChanged,
    this.scale = 3,
    this.onColor = const Color(0xFF43A047),
    this.offColor = const Color(0xFF757575),
  }) : assert(scale >= 1, 'scale должен быть не меньше 1');

  /// Включён ли переключатель.
  final bool value;

  /// Вызывается при нажатии с новым значением. null отключает переключатель.
  final ValueChanged<bool>? onChanged;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  final Color onColor;
  final Color offColor;

  // Размеры в пикселях сцены.
  static const int _w = 22;
  static const int _h = 12;
  static const int _knob = 8;
  // Путь бегунка: от левого края (внутри рамки и отступа) до правого.
  static const int _travel = _w - 4 - _knob;

  List<PixelLayer> _buildLayers(double t, bool enabled) {
    final on = t >= 0.5; // цвет дорожки меняется на середине пути
    final base = !enabled
        ? const Color(0xFFBDBDBD)
        : (on ? onColor : offColor);
    final border = pixelDarken(base, 0.6);
    final knobX = 2 + (t * _travel).round(); // целый пиксель сцены

    return [
      PixelLayer(id: 'switch', items: [
        // Дорожка со срезанными углами.
        PixelRect(x: 1, y: 0, width: _w - 2, height: _h, color: border),
        PixelRect(x: 0, y: 1, width: _w, height: _h - 2, color: border),
        PixelRect(x: 1, y: 1, width: _w - 2, height: _h - 2, color: base),
        // Бегунок: тёмная рамка и светлая заливка.
        PixelRect(x: knobX, y: 2, width: _knob, height: _knob, color: border),
        PixelRect(
          x: knobX + 1,
          y: 3,
          width: _knob - 2,
          height: _knob - 2,
          color: enabled ? const Color(0xFFFFFFFF) : const Color(0xFFEEEEEE),
        ),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: (_w * scale).toDouble(),
          height: (_h * scale).toDouble(),
          // Плавный ход бегунка: t идёт от 0 к 1 за 120 мс, а при выключении
          // обратно. Первое значение показывается сразу, без анимации.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 120),
            builder: (context, t, _) => PixelCanvas(
              scale: scale,
              background: const Color(0x00000000),
              touchMode: PixelTouchMode.transparent,
              layers: _buildLayers(t, enabled),
            ),
          ),
        ),
      ),
    );
  }
}
