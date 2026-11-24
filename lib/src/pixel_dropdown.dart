import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Выпадающий список: поле с выбранным пунктом и меню под ним.
///
/// По нажатию на поле меню открывается поверх экрана (через Overlay), под
/// полем или над ним, если снизу не хватает места. Выбор пункта закрывает
/// меню; нажатие в любое другое место тоже закрывает его без выбора.
/// Поле и меню это холсты, пункты рисуются шрифтом из атласа.
///
///     PixelDropdown<String>(
///       atlas: atlas,
///       items: const {'ru': 'Русский', 'de': 'Deutsch', 'en': 'English'},
///       value: lang,
///       onChanged: (v) => setState(() => lang = v),
///     )
///
/// Ширина одинакова у поля и меню и подбирается по самой длинной подписи.
/// Без [onChanged] поле отключено.
class PixelDropdown<T> extends StatelessWidget {
  const PixelDropdown({
    super.key,
    required this.atlas,
    required this.items,
    required this.value,
    required this.onChanged,
    this.font,
    this.scale,
    this.color,
    this.padding = 4,
  });

  final PixelAtlas atlas;

  /// Значения и подписи в порядке показа.
  final Map<T, String> items;

  /// Выбранное значение; должно быть среди ключей [items].
  final T value;

  /// Вызывается при выборе другого пункта. null отключает поле.
  final ValueChanged<T>? onChanged;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет поля и выбранного пункта меню.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  /// Отступ от подписи до края в пикселях сцены.
  final int padding;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelDropdownImpl<T>(
      atlas: atlas,
      items: items,
      value: value,
      onChanged: onChanged,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.primary,
      padding: padding,
    );
  }
}

/// Реализация PixelDropdown: все значения уже подобраны (параметр, тема или умолчание).
class _PixelDropdownImpl<T> extends StatefulWidget {
  const _PixelDropdownImpl({
    required this.atlas,
    required this.items,
    required this.value,
    required this.onChanged,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF3F51B5),
    this.padding = 4,
  })  : assert(scale >= 1, 'scale должен быть не меньше 1'),
        assert(padding >= 0, 'padding не может быть отрицательным'),
        assert(items.length > 0, 'нужен хотя бы один пункт');

  final PixelAtlas atlas;

  /// Значения и подписи в порядке показа.
  final Map<T, String> items;

  /// Выбранное значение; должно быть среди ключей [items].
  final T value;

  /// Вызывается при выборе другого пункта. null отключает поле.
  final ValueChanged<T>? onChanged;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет поля и выбранного пункта меню.
  final Color color;

  /// Отступ от подписи до края в пикселях сцены.
  final int padding;

  @override
  State<_PixelDropdownImpl<T>> createState() => _PixelDropdownState<T>();
}

class _PixelDropdownState<T> extends State<_PixelDropdownImpl<T>> {
  OverlayEntry? _entry;

  // Размеры в пикселях сцены.
  static const int _arrowArea = 8; // место под стрелку справа

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  Size _textSize(String text) =>
      layoutText(PixelText(text: text, font: widget.font), widget.atlas)
          ?.size ??
      Size.zero;

  // Геометрия: ширина [w] (общая у поля и меню), высота поля [h], высота
  // пункта меню [itemH], высота подписи [textH].
  ({int w, int h, int itemH, int textH}) _geometry() {
    var textW = 0;
    var textH = 0;
    for (final label in widget.items.values) {
      final s = _textSize(label);
      textW = math.max(textW, s.width.toInt());
      textH = math.max(textH, s.height.toInt());
    }
    return (
      w: textW + 2 * widget.padding + 2 + _arrowArea,
      h: textH + 8,
      itemH: textH + 4,
      textH: textH,
    );
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _open() {
    if (_entry != null) return;
    final box = context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    final g = _geometry();
    final menuH = ((widget.items.length * g.itemH + 2) * widget.scale).toDouble();
    final screenH = MediaQuery.sizeOf(context).height;
    final below = topLeft.dy + box.size.height;
    // Под полем, а если не помещается, то над ним.
    final top = below + menuH <= screenH ? below : topLeft.dy - menuH;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Нажатие мимо меню закрывает его.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: topLeft.dx,
            top: top,
            child: _menu(g),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  Widget _menu(({int w, int h, int itemH, int textH}) g) {
    final keys = widget.items.keys.toList();
    final labels = widget.items.values.toList();
    final base = widget.color;
    final border = pixelDarken(base, 0.6);
    final back = pixelDarken(base, 0.45);
    final w = g.w;
    final h = keys.length * g.itemH + 2;

    final layers = [
      PixelLayer(id: 'menu', items: [
        PixelRect(x: 1, y: 0, width: w - 2, height: h, color: border),
        PixelRect(x: 0, y: 1, width: w, height: h - 2, color: border),
        PixelRect(x: 1, y: 1, width: w - 2, height: h - 2, color: back),
        for (var i = 0; i < keys.length; i++) ...[
          if (keys[i] == widget.value)
            PixelRect(
                x: 1, y: 1 + i * g.itemH, width: w - 2, height: g.itemH, color: base),
          PixelText(
            text: labels[i],
            font: widget.font,
            x: 1 + widget.padding,
            y: 1 + i * g.itemH + 2,
            color: const Color(0xFFFFFFFF),
          ),
        ],
      ]),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        final i = ((d.localPosition.dy / widget.scale - 1) / g.itemH).floor();
        if (i < 0 || i >= keys.length) return;
        _close();
        if (keys[i] != widget.value) widget.onChanged!(keys[i]);
      },
      child: SizedBox(
        width: (w * widget.scale).toDouble(),
        height: (h * widget.scale).toDouble(),
        child: PixelCanvas(
          scale: widget.scale,
          atlas: widget.atlas,
          background: const Color(0x00000000),
          touchMode: PixelTouchMode.transparent,
          layers: layers,
        ),
      ),
    );
  }

  List<PixelLayer> _fieldLayers(
    ({int w, int h, int itemH, int textH}) g,
    bool enabled,
  ) {
    final base = enabled ? widget.color : const Color(0xFF9E9E9E);
    final border = pixelDarken(base, 0.6);
    final w = g.w;
    final h = g.h;
    const white = Color(0xFFFFFFFF);
    final ay = (h - 3) ~/ 2; // верхняя строка стрелки

    return [
      PixelLayer(id: 'field', items: [
        PixelRect(x: 1, y: 0, width: w - 2, height: h, color: border),
        PixelRect(x: 0, y: 1, width: w, height: h - 2, color: border),
        PixelRect(x: 1, y: 1, width: w - 2, height: h - 2, color: base),
        PixelText(
          text: widget.items[widget.value] ?? '',
          font: widget.font,
          x: 1 + widget.padding,
          y: ((h - g.textH) / 2).round(),
          color: white,
        ),
        // Стрелка вниз: три строки 5, 3 и 1 пиксель.
        PixelRect(x: w - 8, y: ay, width: 5, height: 1, color: white),
        PixelRect(x: w - 7, y: ay + 1, width: 3, height: 1, color: white),
        PixelRect(x: w - 6, y: ay + 2, width: 1, height: 1, color: white),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.items.containsKey(widget.value),
        'value должно быть среди items');
    final enabled = widget.onChanged != null;
    final g = _geometry();

    return Semantics(
      button: true,
      enabled: enabled,
      value: widget.items[widget.value],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _open : null,
        child: SizedBox(
          width: (g.w * widget.scale).toDouble(),
          height: (g.h * widget.scale).toDouble(),
          child: PixelCanvas(
            scale: widget.scale,
            atlas: widget.atlas,
            background: const Color(0x00000000),
            touchMode: PixelTouchMode.transparent,
            layers: _fieldLayers(g, enabled),
          ),
        ),
      ),
    );
  }
}
