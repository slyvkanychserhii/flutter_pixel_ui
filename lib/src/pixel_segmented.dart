import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Сегментные кнопки: ряд подписей, из которых выбрана ровно одна.
///
/// Подходит для выбора из 2–4 вариантов (сложность, режим, единицы). Весь
/// ряд это один холст: общая рамка со срезанными углами, между сегментами
/// линии. Выбранный сегмент залит цветом [color], остальные тёмные.
///
/// Варианты задаются упорядоченной картой «значение → подпись»:
///
///     PixelSegmented<int>(
///       atlas: atlas,
///       segments: const {0: 'Лёгкий', 1: 'Средний', 2: 'Сложный'},
///       value: level,
///       onChanged: (v) => setState(() => level = v),
///     )
///
/// Ширина каждого сегмента равна ширине его подписи плюс [padding] с обеих
/// сторон. [onChanged] вызывается только при выборе другого сегмента. Без
/// [onChanged] ряд отключён.
class PixelSegmented<T> extends StatelessWidget {
  const PixelSegmented({
    super.key,
    required this.atlas,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.font,
    this.scale,
    this.color,
    this.padding = 4,
  });

  final PixelAtlas atlas;

  /// Значения и подписи в порядке показа (обычная карта сохраняет порядок).
  final Map<T, String> segments;

  /// Выбранное значение; должно быть среди ключей [segments].
  final T value;

  /// Вызывается при выборе другого сегмента. null отключает ряд.
  final ValueChanged<T>? onChanged;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет выбранного сегмента.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  /// Отступ от подписи до границы сегмента в пикселях сцены.
  final int padding;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelSegmentedImpl<T>(
      atlas: atlas,
      segments: segments,
      value: value,
      onChanged: onChanged,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.primary,
      padding: padding,
    );
  }
}

/// Реализация PixelSegmented: все значения уже подобраны (параметр, тема или умолчание).
class _PixelSegmentedImpl<T> extends StatelessWidget {
  const _PixelSegmentedImpl({
    required this.atlas,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF3F51B5),
    this.padding = 4,
  })  : assert(scale >= 1, 'scale должен быть не меньше 1'),
        assert(padding >= 0, 'padding не может быть отрицательным'),
        assert(segments.length > 0, 'нужен хотя бы один сегмент');

  final PixelAtlas atlas;

  /// Значения и подписи в порядке показа (обычная карта сохраняет порядок).
  final Map<T, String> segments;

  /// Выбранное значение; должно быть среди ключей [segments].
  final T value;

  /// Вызывается при выборе другого сегмента. null отключает ряд.
  final ValueChanged<T>? onChanged;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет выбранного сегмента.
  final Color color;

  /// Отступ от подписи до границы сегмента в пикселях сцены.
  final int padding;

  // Размер подписи в пикселях сцены (0, если шрифта нет в атласе).
  Size _textSize(String label) =>
      layoutText(PixelText(text: label, font: font), atlas)?.size ?? Size.zero;

  // Геометрия ряда в пикселях сцены.
  ({List<int> starts, List<int> widths, int total, int height, int textH})
      _geometry() {
    final labels = segments.values.toList();
    var textH = 0;
    final widths = <int>[];
    for (final label in labels) {
      final size = _textSize(label);
      textH = math.max(textH, size.height.toInt());
      widths.add(size.width.toInt() + 2 * padding);
    }
    // Слева рамка в 1 пиксель, между сегментами линия в 1 пиксель.
    final starts = <int>[];
    var x = 1;
    for (final w in widths) {
      starts.add(x);
      x += w + 1;
    }
    // После последнего сегмента x указывает ровно на столбец правой рамки
    // плюс один, то есть равен полной ширине ряда.
    return (
      starts: starts,
      widths: widths,
      total: x,
      height: textH + 2 * 4, // рамка 1 + отступ 3 с каждой стороны
      textH: textH,
    );
  }

  List<PixelLayer> _buildLayers(bool enabled) {
    final g = _geometry();
    final labels = segments.values.toList();
    final keys = segments.keys.toList();
    final base = enabled ? color : const Color(0xFF9E9E9E);
    final border = pixelDarken(base, 0.6);
    final idle = pixelDarken(base, 0.55);
    final w = g.total;
    final h = g.height;

    return [
      PixelLayer(id: 'segmented', items: [
        // Общая рамка со срезанными углами; линии между сегментами это её
        // цвет, оставшийся между заливками.
        PixelRect(x: 1, y: 0, width: w - 2, height: h, color: border),
        PixelRect(x: 0, y: 1, width: w, height: h - 2, color: border),
        for (var i = 0; i < keys.length; i++)
          PixelRect(
            x: g.starts[i],
            y: 1,
            width: g.widths[i],
            height: h - 2,
            color: keys[i] == value ? base : idle,
          ),
        for (var i = 0; i < keys.length; i++)
          PixelText(
            text: labels[i],
            font: font,
            x: g.starts[i] + padding,
            y: ((h - g.textH) / 2).round(),
            color: keys[i] == value
                ? const Color(0xFFFFFFFF)
                : const Color(0xFFBDBDBD),
          ),
      ]),
    ];
  }

  // Какой сегмент лежит под горизонтальной координатой [dx] (обычные
  // пиксели внутри виджета) или null, если это рамка.
  int? _indexAt(double dx) {
    final g = _geometry();
    final x = dx / scale;
    for (var i = 0; i < g.starts.length; i++) {
      // Линию справа от сегмента считаем частью сегмента.
      if (x >= g.starts[i] - (i == 0 ? 1 : 0) && x < g.starts[i] + g.widths[i] + 1) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(segments.containsKey(value), 'value должно быть среди segments');
    final enabled = onChanged != null;
    final g = _geometry();

    return Semantics(
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled
            ? (d) {
                final i = _indexAt(d.localPosition.dx);
                if (i == null) return;
                final key = segments.keys.elementAt(i);
                if (key != value) onChanged!(key);
              }
            : null,
        child: SizedBox(
          width: (g.total * scale).toDouble(),
          height: (g.height * scale).toDouble(),
          child: PixelCanvas(
            scale: scale,
            atlas: atlas,
            background: const Color(0x00000000),
            touchMode: PixelTouchMode.transparent,
            layers: _buildLayers(enabled),
          ),
        ),
      ),
    );
  }
}
