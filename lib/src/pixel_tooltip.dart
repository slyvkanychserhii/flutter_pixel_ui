import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Подсказка: пиксельная плашка с текстом около любого виджета.
///
/// Оборачивает [child] и показывает [message] шрифтом из атласа в двух
/// случаях:
///
///  * долгое нажатие на виджет (для пальца);
///  * наведение мыши, если курсор постоял дольше [waitDuration].
///
/// Плашка рисуется поверх экрана (через Overlay) над виджетом, а если сверху
/// не хватает места, то под ним; по горизонтали она центрируется на виджете и
/// не выходит за края экрана. Нажатия плашка не перехватывает. Она исчезает,
/// когда мышь уходит, и через [showDuration] после показа (для пальца).
///
///     PixelTooltip(
///       atlas: atlas,
///       message: 'Сохранить файл',
///       child: PixelButton(atlas: atlas, label: 'OK', onPressed: save),
///     )
///
/// Многострочный текст не поддерживается: сообщение рисуется одной строкой.
class PixelTooltip extends StatelessWidget {
  const PixelTooltip({
    super.key,
    required this.atlas,
    required this.message,
    required this.child,
    this.font,
    this.scale,
    this.color,
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(seconds: 2),
  });

  final PixelAtlas atlas;

  /// Текст подсказки.
  final String message;

  final Widget child;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет плашки; рамка получается из него.
  /// null: берётся из [PixelTheme] (surface).
  final Color? color;

  /// Сколько мышь должна простоять над виджетом до показа.
  final Duration waitDuration;

  /// Сколько подсказка остаётся на экране после долгого нажатия.
  final Duration showDuration;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelTooltipImpl(
      atlas: atlas,
      message: message,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.surface,
      waitDuration: waitDuration,
      showDuration: showDuration,
      child: child,
    );
  }
}

/// Реализация PixelTooltip: все значения уже подобраны (параметр, тема или умолчание).
class _PixelTooltipImpl extends StatefulWidget {
  const _PixelTooltipImpl({
    required this.atlas,
    required this.message,
    required this.child,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF2B2B3A),
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(seconds: 2),
  }) : assert(scale >= 1, 'scale должен быть не меньше 1');

  final PixelAtlas atlas;

  /// Текст подсказки.
  final String message;

  final Widget child;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет плашки; рамка получается из него.
  final Color color;

  /// Сколько мышь должна простоять над виджетом до показа.
  final Duration waitDuration;

  /// Сколько подсказка остаётся на экране после долгого нажатия.
  final Duration showDuration;

  @override
  State<_PixelTooltipImpl> createState() => _PixelTooltipState();
}

class _PixelTooltipState extends State<_PixelTooltipImpl> {
  // Отступы подписи от рамки в пикселях сцены.
  static const int _padX = 4;
  static const int _padY = 3;

  OverlayEntry? _entry;
  Timer? _showTimer; // ожидание наведения мыши
  Timer? _hideTimer; // автоскрытие после долгого нажатия

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _hide();
    super.dispose();
  }

  // Размер плашки в пикселях сцены.
  ({int w, int h, int textH}) _geometry() {
    final size = layoutText(
          PixelText(text: widget.message, font: widget.font),
          widget.atlas,
        )?.size ??
        Size.zero;
    return (
      w: size.width.toInt() + 2 * (1 + _padX),
      h: size.height.toInt() + 2 * (1 + _padY),
      textH: size.height.toInt(),
    );
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  void _show() {
    if (_entry != null || !mounted) return;
    final box = context.findRenderObject()! as RenderBox;
    final target = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(context);
    final g = _geometry();
    final w = (g.w * widget.scale).toDouble();
    final h = (g.h * widget.scale).toDouble();
    final gap = (2 * widget.scale).toDouble();

    // По горизонтали по центру виджета, но в пределах экрана. Положение
    // округляется до целого пикселя сцены, чтобы плашка лежала на сетке.
    final left = (target.center.dx - w / 2)
        .clamp(gap, math.max(gap, screen.width - w - gap))
        .toDouble();
    // Над виджетом, а если не помещается, то под ним.
    final top = target.top - h - gap >= 0 ? target.top - h - gap : target.bottom + gap;

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: (left / widget.scale).roundToDouble() * widget.scale,
        top: (top / widget.scale).roundToDouble() * widget.scale,
        child: IgnorePointer(child: _bubble(g)),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  Widget _bubble(({int w, int h, int textH}) g) {
    final border = pixelDarken(widget.color, 0.6);
    return SizedBox(
      width: (g.w * widget.scale).toDouble(),
      height: (g.h * widget.scale).toDouble(),
      child: PixelCanvas(
        scale: widget.scale,
        atlas: widget.atlas,
        background: const Color(0x00000000),
        touchMode: PixelTouchMode.transparent,
        layers: [
          PixelLayer(id: 'tooltip', items: [
            PixelRect(x: 1, y: 0, width: g.w - 2, height: g.h, color: border),
            PixelRect(x: 0, y: 1, width: g.w, height: g.h - 2, color: border),
            PixelRect(
                x: 1, y: 1, width: g.w - 2, height: g.h - 2, color: widget.color),
            PixelText(
              text: widget.message,
              font: widget.font,
              x: 1 + _padX,
              y: 1 + _padY,
            ),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // Мышь: показать после паузы, скрыть при уходе.
      onEnter: (_) {
        _showTimer?.cancel();
        _showTimer = Timer(widget.waitDuration, _show);
      },
      onExit: (_) {
        _showTimer?.cancel();
        _hideTimer?.cancel();
        _hide();
      },
      child: GestureDetector(
        // Палец: долгое нажатие. translucent, чтобы обычные нажатия
        // доставались дочернему виджету.
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          _show();
          _hideTimer?.cancel();
          _hideTimer = Timer(widget.showDuration, _hide);
        },
        child: widget.child,
      ),
    );
  }
}
