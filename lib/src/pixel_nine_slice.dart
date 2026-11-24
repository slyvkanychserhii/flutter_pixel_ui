import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_theme.dart';

/// Одна часть девятичастной нарезки: откуда брать кусок картинки атласа
/// ([src], в пикселях картинки) и куда его рисовать ([dst], в обычных
/// пикселях виджета).
typedef PixelSlicePart = ({Rect src, Rect dst, bool isCorner});

/// Делит кадр [frame] на девять частей и раскладывает их по области
/// [width] x [height] пикселей сцены (до умножения на [scale]).
///
/// Углы сохраняют размер, края растягиваются в одну сторону, центр в обе:
///
///     +---+---------+---+
///     | ↖ |    ↑    | ↗ |   углы: размер как в кадре
///     +---+---------+---+
///     | ← |    ·    | → |   края: тянутся вдоль стороны
///     +---+---------+---+   центр: тянется во все стороны
///     | ↙ |    ↓    | ↘ |
///     +---+---------+---+
///
/// [slice] это ширина левой, верхней, правой и нижней неизменяемых полос в
/// пикселях кадра. Части нулевой площади пропускаются. Возвращает пустой
/// список, если область меньше суммы фиксированных полос.
///
/// Вынесено отдельной функцией, чтобы раскладку можно было проверять
/// тестом без рисования.
List<PixelSlicePart> nineSliceParts({
  required Rect frame,
  required EdgeInsets slice,
  required int width,
  required int height,
  required int scale,
}) {
  if (width < slice.horizontal || height < slice.vertical) return const [];

  // Границы столбцов и строк в кадре (src) и в области (dst).
  final sx = [frame.left, frame.left + slice.left, frame.right - slice.right, frame.right];
  final sy = [frame.top, frame.top + slice.top, frame.bottom - slice.bottom, frame.bottom];
  final dx = [0.0, slice.left * scale, (width - slice.right) * scale, width * scale]
      .map((v) => v.toDouble())
      .toList();
  final dy = [0.0, slice.top * scale, (height - slice.bottom) * scale, height * scale]
      .map((v) => v.toDouble())
      .toList();

  final parts = <PixelSlicePart>[];
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 3; col++) {
      final src = Rect.fromLTRB(sx[col], sy[row], sx[col + 1], sy[row + 1]);
      final dst = Rect.fromLTRB(dx[col], dy[row], dx[col + 1], dy[row + 1]);
      if (src.isEmpty || dst.isEmpty) continue;
      parts.add((
        src: src,
        dst: dst,
        isCorner: (col == 0 || col == 2) && (row == 0 || row == 2),
      ));
    }
  }
  return parts;
}

/// Растягиваемая рамка из кадра атласа (девятичастная нарезка, 9-slice).
///
/// Один небольшой кадр ([frame], например 16 x 16 пикселей) превращается в
/// рамку любого размера: углы остаются как нарисованы, края и центр
/// растягиваются. Так панели, окна и кнопки рисуются спрайтами, а не
/// примитивами, и могут иметь любой дизайн.
///
/// В кадре нужно указать, какие полосы неизменяемы: [slice] (в пикселях
/// кадра: left, top, right, bottom). Края нарезки лучше делать однородными
/// вдоль стороны, тогда растягивание незаметно. Если на краях или в центре
/// есть узор, включите [tile]: части тогда не растягиваются, а повторяются
/// целыми плитками (последняя плитка обрезается).
///
/// Размер как у PixelTabs: виджет занимает всё место, которое дал родитель,
/// а по оси без ограничения берёт размер содержимого. Содержимое [child]
/// лежит внутри рамки: отступ от края это [slice] * [scale] плюс [padding].
///
/// Рисование идёт через `Canvas.drawImageRect` без сглаживания, поэтому
/// пиксели остаются квадратами; размер областей в пикселях сцены
/// округляется вниз до целого, лишняя полоска справа и снизу пустая.
class PixelNineSlice extends StatelessWidget {
  const PixelNineSlice({
    super.key,
    required this.atlas,
    required this.frame,
    required this.slice,
    this.child,
    this.scale,
    this.tile = false,
    this.tint = const Color(0xFFFFFFFF),
    this.padding = EdgeInsets.zero,
  });

  final PixelAtlas atlas;

  /// Имя кадра в атласе.
  final String frame;

  /// Неизменяемые полосы в пикселях кадра. Значения целые, а в сумме
  /// меньше размера кадра (в центре остаётся хотя бы пиксель).
  final EdgeInsets slice;

  /// Содержимое внутри рамки или null для пустой рамки.
  final Widget? child;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Повторять края и центр плитками вместо растягивания.
  final bool tile;

  /// Цвет подкраски: умножается на цвета кадра (белый не меняет их).
  final Color tint;

  /// Дополнительный отступ содержимого от внутренней границы рамки (в
  /// обычных пикселях).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelNineSliceImpl(
      atlas: atlas,
      frame: frame,
      slice: slice,
      scale: scale ?? theme.scale ?? 2,
      tile: tile,
      tint: tint,
      padding: padding,
      child: child,
    );
  }
}

/// Реализация PixelNineSlice: все значения уже подобраны (параметр, тема или умолчание).
class _PixelNineSliceImpl extends StatelessWidget {
  const _PixelNineSliceImpl({
    required this.atlas,
    required this.frame,
    required this.slice,
    this.child,
    this.scale = 2,
    this.tile = false,
    this.tint = const Color(0xFFFFFFFF),
    this.padding = EdgeInsets.zero,
  })  : assert(scale >= 1, 'scale должен быть не меньше 1');

  final PixelAtlas atlas;

  /// Имя кадра в атласе.
  final String frame;

  /// Неизменяемые полосы в пикселях кадра. Значения целые, а в сумме
  /// меньше размера кадра (в центре остаётся хотя бы пиксель).
  final EdgeInsets slice;

  /// Содержимое внутри рамки или null для пустой рамки.
  final Widget? child;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Повторять края и центр плитками вместо растягивания.
  final bool tile;

  /// Цвет подкраски: умножается на цвета кадра (белый не меняет их).
  final Color tint;

  /// Дополнительный отступ содержимого от внутренней границы рамки (в
  /// обычных пикселях).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final rect = atlas.frame(frame);
    assert(rect != null, 'в атласе нет кадра "$frame"');
    assert(
      slice.left == slice.left.roundToDouble() &&
          slice.top == slice.top.roundToDouble() &&
          slice.right == slice.right.roundToDouble() &&
          slice.bottom == slice.bottom.roundToDouble(),
      'slice должен состоять из целых чисел',
    );
    assert(
      rect == null ||
          (slice.horizontal < rect.width && slice.vertical < rect.height),
      'slice не оставляет места для центра кадра',
    );

    final inner = EdgeInsets.fromLTRB(
      slice.left * scale,
      slice.top * scale,
      slice.right * scale,
      slice.bottom * scale,
    );

    // Занимаем всё доступное место; по неограниченной оси берём размер
    // содержимого.
    return LayoutBuilder(
      builder: (context, box) => ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: box.hasBoundedWidth ? box.maxWidth : 0,
          minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
        ),
        child: Stack(
          children: [
            if (rect != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _NineSlicePainter(
                    image: atlas.image,
                    frame: rect,
                    slice: slice,
                    scale: scale,
                    tile: tile,
                    tint: tint,
                  ),
                ),
              ),
            Padding(
              padding: inner + padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _NineSlicePainter extends CustomPainter {
  _NineSlicePainter({
    required this.image,
    required this.frame,
    required this.slice,
    required this.scale,
    required this.tile,
    required this.tint,
  });

  final ui.Image image;
  final Rect frame;
  final EdgeInsets slice;
  final int scale;
  final bool tile;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final parts = nineSliceParts(
      frame: frame,
      slice: slice,
      width: (size.width / scale).floor(),
      height: (size.height / scale).floor(),
      scale: scale,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false
      ..colorFilter = ColorFilter.mode(tint, BlendMode.modulate);

    for (final p in parts) {
      if (!tile || p.isCorner) {
        canvas.drawImageRect(image, p.src, p.dst, paint);
        continue;
      }
      // Плитки: исходный кусок повторяется целиком, последний обрезается
      // по границе части.
      final tw = p.src.width * scale;
      final th = p.src.height * scale;
      canvas.save();
      canvas.clipRect(p.dst);
      for (var y = p.dst.top; y < p.dst.bottom; y += th) {
        for (var x = p.dst.left; x < p.dst.right; x += tw) {
          canvas.drawImageRect(image, p.src, Rect.fromLTWH(x, y, tw, th), paint);
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_NineSlicePainter old) =>
      old.image != image ||
      old.frame != frame ||
      old.slice != slice ||
      old.scale != scale ||
      old.tile != tile ||
      old.tint != tint;
}
