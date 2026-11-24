import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_nine_slice.dart';
import 'pixel_theme.dart';

/// Пиксельная панель: рамка и заливка, внутри которых лежат обычные виджеты.
///
/// Основа для окон, карточек и диалогов. Размер панели определяется её
/// содержимым [child] плюс [padding] (как у Container); чтобы панель заняла
/// всё место, положите её в SizedBox или Expanded. Рамка рисуется
/// [PixelCanvas] на заднем плане, поэтому вид панели пиксельный при любом
/// масштабе. Если размер не кратен [scale], справа и снизу остаётся полоска
/// меньше одного пикселя сцены.
///
/// С заголовком [title] сверху появляется полоса с подписью шрифтом из
/// атласа; для неё нужны [atlas] и [font].
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.title,
    this.atlas,
    this.font,
    this.scale,
    this.color,
    this.titleColor,
    this.frame,
    this.expand = false,
    this.padding = const EdgeInsets.all(8),
  });

  /// Содержимое панели.
  final Widget child;

  /// Заголовок или null без заголовка.
  final String? title;

  /// Атлас со шрифтом [font]; нужен только для заголовка.
  final PixelAtlas? atlas;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет заливки; рамка и полоса заголовка получаются из него.
  /// null: берётся из [PixelTheme] (surface).
  final Color? color;

  /// null: берётся из [PixelTheme] (text).
  final Color? titleColor;

  /// Рамка из кадра атласа вместо примитивов (9-slice) или null.
  /// null: берётся из [PixelTheme.panelFrame], а если и там null, панель
  /// рисуется примитивами. Для рамки нужен [atlas]. С рамкой [color] не
  /// используется: цвета берутся из кадра.
  final PixelFrameStyle? frame;

  /// true: панель занимает всё место, которое дал родитель, по оси без
  /// ограничения (например, в ListView по высоте) берёт размер содержимого.
  /// false: размер по содержимому.
  final bool expand;

  /// Отступ от рамки до содержимого (в обычных пикселях, не сцены).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelPanelImpl(
      title: title,
      atlas: atlas,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.surface,
      titleColor: titleColor ?? theme.text,
      frame: frame ?? theme.panelFrame,
      expand: expand,
      padding: padding,
      child: child,
    );
  }
}

/// Реализация PixelPanel: все значения уже подобраны (параметр, тема или умолчание).
class _PixelPanelImpl extends StatelessWidget {
  const _PixelPanelImpl({
    required this.child,
    this.title,
    this.atlas,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF2B2B3A),
    this.titleColor = const Color(0xFFFFFFFF),
    this.frame,
    this.expand = false,
    this.padding = const EdgeInsets.all(8),
  })  : assert(title == null || atlas != null, 'для заголовка нужен atlas'),
        assert(frame == null || atlas != null, 'для рамки из атласа нужен atlas'),
        assert(scale >= 1, 'scale должен быть не меньше 1');

  /// Содержимое панели.
  final Widget child;

  /// Заголовок или null без заголовка.
  final String? title;

  /// Атлас со шрифтом [font]; нужен только для заголовка.
  final PixelAtlas? atlas;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет заливки; рамка и полоса заголовка получаются из него.
  final Color color;

  final Color titleColor;

  final PixelFrameStyle? frame;

  final bool expand;

  /// Отступ от рамки до содержимого (в обычных пикселях, не сцены).
  final EdgeInsets padding;

  // Размер подписи заголовка в пикселях сцены (0, если заголовка нет).
  Size get _titleSize {
    final text = title;
    final atlas = this.atlas;
    if (text == null || atlas == null) return Size.zero;
    return layoutText(PixelText(text: text, font: font), atlas)?.size ??
        Size.zero;
  }

  // Высота полосы заголовка в пикселях сцены (без рамки и разделителя).
  int get _titleBarH => title == null ? 0 : _titleSize.height.toInt() + 3;

  // Слои панели размером [w] x [h] пикселей сцены.
  List<PixelLayer> _buildLayers(int w, int h) {
    final border = pixelDarken(color, 0.6);
    final tb = _titleBarH;

    return [
      PixelLayer(id: 'panel', items: [
        PixelRect(x: 1, y: 0, width: w - 2, height: h, color: border),
        PixelRect(x: 0, y: 1, width: w, height: h - 2, color: border),
        PixelRect(x: 1, y: 1, width: w - 2, height: h - 2, color: color),
        if (title != null) ...[
          // Полоса заголовка чуть светлее заливки, под ней разделитель.
          PixelRect(
              x: 1, y: 1, width: w - 2, height: tb, color: pixelLighten(color, 0.12)),
          PixelRect(x: 1, y: tb + 1, width: w - 2, height: 1, color: border),
          PixelText(
            text: title!,
            font: font,
            x: 4,
            y: 2,
            color: titleColor,
          ),
        ],
      ]),
    ];
  }

  // Панель из спрайтов: рамка 9-slice на заднем плане, заголовок текстом
  // сразу под верхней кромкой, содержимое внутри неизменяемых полос.
  Widget _spriteStack(PixelFrameStyle style) {
    final slice = style.slice;
    final titleH = title == null ? 0 : _titleSize.height.toInt();
    // Место под заголовок: 1 пиксель сверху, подпись, 2 пикселя снизу.
    final titleBlock = title == null ? 0.0 : ((titleH + 3) * scale).toDouble();

    return Stack(
      children: [
        Positioned.fill(
          child: PixelNineSlice(
            atlas: atlas!,
            frame: style.frame,
            slice: slice,
            scale: scale,
            tile: style.tile,
          ),
        ),
        if (title != null)
          Positioned.fill(
            child: PixelCanvas(
              scale: scale,
              atlas: atlas,
              background: const Color(0x00000000),
              touchMode: PixelTouchMode.transparent,
              layers: [
                PixelLayer(id: 'title', items: [
                  PixelText(
                    text: title!,
                    font: font,
                    x: slice.left.toInt() + 1,
                    y: slice.top.toInt() + 1,
                    color: titleColor,
                  ),
                ]),
              ],
            ),
          ),
        Padding(
          padding: padding +
              EdgeInsets.fromLTRB(
                slice.left * scale,
                slice.top * scale + titleBlock,
                slice.right * scale,
                slice.bottom * scale,
              ),
          child: child,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = frame;
    final stack = style == null ? _primitiveStack() : _spriteStack(style);
    if (!expand) return stack;
    // Занимаем всё доступное место; по неограниченной оси берём размер
    // содержимого.
    return LayoutBuilder(
      builder: (context, box) => ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: box.hasBoundedWidth ? box.maxWidth : 0,
          minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
        ),
        child: stack,
      ),
    );
  }

  // Панель из примитивов (рамка и заливка рисуются прямоугольниками).
  Widget _primitiveStack() {
    // Под полосу заголовка содержимое сдвигается вниз: рамка 1 + полоса +
    // разделитель 1.
    final top = title == null ? 0.0 : ((_titleBarH + 2) * scale).toDouble();

    return Stack(
      children: [
        // Задний план: холст на всю площадь панели. Размер сцены считаем
        // из размера, который дал Stack.
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth / scale).floor();
              final h = (box.maxHeight / scale).floor();
              return PixelCanvas(
                scale: scale,
                atlas: atlas,
                background: const Color(0x00000000),
                // Холст не ловит нажатия: они достаются содержимому.
                touchMode: PixelTouchMode.transparent,
                layers: w < 4 || h < 4 ? const [] : _buildLayers(w, h),
              );
            },
          ),
        ),
        Padding(
          padding: padding + EdgeInsets.only(top: top),
          child: child,
        ),
      ],
    );
  }
}
