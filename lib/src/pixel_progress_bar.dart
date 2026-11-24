import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Пиксельный индикатор прогресса: полоса с заполнением.
///
/// Рисуется только примитивами, атлас не нужен. Ширина [width] задаётся в
/// пикселях сцены, высота 8, всё умножается на [scale]. Заполнение растёт
/// по целым пикселям, а при смене [value] плавно доезжает до нового
/// значения (150 мс).
///
/// Если задан [segments], полоса состоит из отдельных блоков (например, 10
/// блоков = шкала на 10 делений), иначе заполнение сплошное.
class PixelProgressBar extends StatelessWidget {
  const PixelProgressBar({
    super.key,
    required this.value,
    this.width = 60,
    this.segments = 0,
    this.scale,
    this.color,
    this.trackColor,
  });

  /// Заполнение от 0 (пусто) до 1 (полно).
  final double value;

  /// Ширина в пикселях сцены.
  final int width;

  /// Число блоков; 0 это сплошное заполнение.
  final int segments;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 3.
  final int? scale;

  /// Цвет заполнения.
  /// null: берётся из [PixelTheme] (success).
  final Color? color;

  /// Цвет пустой части.
  /// null: берётся из [PixelTheme] (track).
  final Color? trackColor;

  /// См. [_PixelProgressBarImpl.segmentSpans].
  static List<({int start, int width})> segmentSpans(int innerW, int segments) =>
      _PixelProgressBarImpl.segmentSpans(innerW, segments);

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelProgressBarImpl(
      value: value,
      width: width,
      segments: segments,
      scale: scale ?? theme.scale ?? 3,
      color: color ?? theme.success,
      trackColor: trackColor ?? theme.track,
    );
  }
}

/// Реализация PixelProgressBar: все значения уже подобраны (параметр, тема или умолчание).
class _PixelProgressBarImpl extends StatelessWidget {
  const _PixelProgressBarImpl({
    required this.value,
    this.width = 60,
    this.segments = 0,
    this.scale = 3,
    this.color = const Color(0xFF43A047),
    this.trackColor = const Color(0xFF424242),
  })  : assert(value >= 0 && value <= 1, 'value от 0 до 1'),
        assert(width >= 4, 'width не меньше 4'),
        assert(segments >= 0, 'segments не отрицательный'),
        assert(scale >= 1, 'scale должен быть не меньше 1');

  /// Заполнение от 0 (пусто) до 1 (полно).
  final double value;

  /// Ширина в пикселях сцены.
  final int width;

  /// Число блоков; 0 это сплошное заполнение.
  final int segments;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет заполнения.
  final Color color;

  /// Цвет пустой части.
  final Color trackColor;

  // Высота в пикселях сцены.
  static const int _height = 8;

  /// Положение блоков внутри полосы шириной [innerW] пикселей: [segments]
  /// блоков, между ними зазор в 1 пиксель, первый начинается с 0, последний
  /// заканчивается ровно на [innerW]. Остаток ширины раздаётся блокам по
  /// одному пикселю, поэтому полная шкала заполняет полосу целиком.
  static List<({int start, int width})> segmentSpans(int innerW, int segments) {
    final spans = <({int start, int width})>[];
    for (var i = 0; i < segments; i++) {
      final start = i * (innerW + 1) ~/ segments;
      final end = (i + 1) * (innerW + 1) ~/ segments - 1; // без зазора
      spans.add((start: start, width: math.max(1, end - start)));
    }
    return spans;
  }

  List<PixelLayer> _buildLayers(double v) {
    final border = pixelDarken(trackColor, 0.5);
    final innerW = width - 2; // ширина внутри рамки
    const innerH = _height - 2;

    final items = <PixelObject>[
      PixelRect(x: 1, y: 0, width: width - 2, height: _height, color: border),
      PixelRect(x: 0, y: 1, width: width, height: _height - 2, color: border),
      PixelRect(x: 1, y: 1, width: innerW, height: innerH, color: trackColor),
    ];

    if (segments == 0) {
      // Сплошное заполнение: целое число пикселей.
      final filled = (v * innerW).round();
      if (filled > 0) {
        items.add(PixelRect(x: 1, y: 1, width: filled, height: innerH, color: color));
      }
    } else {
      // Блоки с зазором в 1 пиксель, вместе занимающие всю ширину внутри
      // рамки (ширина блоков может отличаться на 1 пиксель).
      final spans = segmentSpans(innerW, segments);
      final lit = (v * segments).round();
      for (var i = 0; i < lit && i < spans.length; i++) {
        items.add(PixelRect(
          x: 1 + spans[i].start,
          y: 1,
          width: spans[i].width,
          height: innerH,
          color: color,
        ));
      }
    }
    return [PixelLayer(id: 'progress', items: items)];
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: '${(value * 100).round()}%',
      child: SizedBox(
        width: (width * scale).toDouble(),
        height: (_height * scale).toDouble(),
        // Плавный ход заполнения. Первое значение показывается сразу.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: const Duration(milliseconds: 150),
          builder: (context, v, _) => PixelCanvas(
            scale: scale,
            background: const Color(0x00000000),
            touchMode: PixelTouchMode.transparent,
            layers: _buildLayers(v),
          ),
        ),
      ),
    );
  }
}
