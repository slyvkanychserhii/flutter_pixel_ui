import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_nine_slice.dart';
import 'pixel_theme.dart';

/// Пиксельная кнопка с подписью шрифтом из атласа.
///
/// Это обычный виджет: кладётся в любую раскладку (Row, Column, Stack...),
/// а внутри себя использует [PixelCanvas]. Кнопка это тёмная рамка со
/// срезанными углами и заливка, а под ней тень в один пиксель
/// (x рамка, a заливка, u тень, 0 прозрачно):
///
///     0xxxxx0        0000000
///     xaaaaax        0xxxxx0
///     xaaaaax   ->   xaaaaax
///     uxxxxxu        xaaaaax
///     0uuuuu0        0xxxxx0
///
/// При нажатии кнопка опускается на пиксель и закрывает тень, подпись
/// опускается вместе с ней. Размер виджета не меняется: под кнопкой всегда
/// оставлен ряд пикселей для тени.
///
/// Размер считается сам: размер подписи плюс отступы, в пикселях сцены,
/// умноженный на [scale]. Холст внутри занимает ровно эту площадь, поэтому
/// пиксели кнопки ровные при любом масштабе.
///
/// Без [onPressed] кнопка отключена: серая и не нажимается.
class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.atlas,
    required this.label,
    required this.onPressed,
    this.font,
    this.scale,
    this.color,
    this.textColor,
    this.frame,
    this.padding = 4,
    this.minWidth = 0,
  });

  /// Атлас с шрифтом [font].
  final PixelAtlas atlas;

  /// Подпись.
  final String label;

  /// Вызывается при нажатии. null отключает кнопку.
  final VoidCallback? onPressed;

  /// Имя шрифта в атласе.
  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Основной цвет кнопки (заливка); цвет рамки получается из него.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  /// null: берётся из [PixelTheme] (text).
  final Color? textColor;

  /// Рамка из кадров атласа вместо примитивов (9-slice) или null.
  /// null: берётся из [PixelTheme.buttonFrame], а если и там null, кнопка
  /// рисуется примитивами. С рамкой [color] не используется: цвета берутся
  /// из кадров. Размер кнопки считается так же, как без рамки, поэтому
  /// подпись должна помещаться внутри неизменяемых полос ([padding]).
  final PixelFrameStyle? frame;

  /// Горизонтальный отступ от подписи до края в пикселях сцены.
  final int padding;

  /// Минимальная ширина кнопки в пикселях сцены.
  final int minWidth;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelButtonImpl(
      atlas: atlas,
      label: label,
      onPressed: onPressed,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.primary,
      textColor: textColor ?? theme.text,
      frame: frame ?? theme.buttonFrame,
      padding: padding,
      minWidth: minWidth,
    );
  }
}

/// Реализация PixelButton: все значения уже подобраны (параметр, тема или умолчание).
class _PixelButtonImpl extends StatefulWidget {
  const _PixelButtonImpl({
    required this.atlas,
    required this.label,
    required this.onPressed,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF3F51B5),
    this.textColor = const Color(0xFFFFFFFF),
    this.frame,
    this.padding = 4,
    this.minWidth = 0,
  }) : assert(scale >= 1, 'scale должен быть не меньше 1');

  /// Атлас с шрифтом [font].
  final PixelAtlas atlas;

  /// Подпись.
  final String label;

  /// Вызывается при нажатии. null отключает кнопку.
  final VoidCallback? onPressed;

  /// Имя шрифта в атласе.
  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Основной цвет кнопки (заливка); цвет рамки получается из него.
  final Color color;

  final Color textColor;

  final PixelFrameStyle? frame;

  /// Горизонтальный отступ от подписи до края в пикселях сцены.
  final int padding;

  /// Минимальная ширина кнопки в пикселях сцены.
  final int minWidth;

  @override
  State<_PixelButtonImpl> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<_PixelButtonImpl> {
  // Как долго кнопка остаётся нажатой минимум, даже если палец отпущен
  // раньше: иначе короткий тап не успевает показать анимацию.
  static const Duration _minPress = Duration(milliseconds: 100);

  // Вертикальный отступ от подписи до рамки в пикселях сцены.
  static const int _vPadding = 3;

  bool _pressed = false;
  final Stopwatch _sinceDown = Stopwatch(); // сколько прошло с касания
  Timer? _releaseTimer; // отложенное отпускание

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  // Палец коснулся кнопки.
  //
  // Состояние берётся из "сырых" событий указателя (Listener), а не из
  // onTapDown жестов: при быстром тапе GestureDetector присылает onTapDown и
  // onTapUp одновременно, в одном кадре, и нажатие никогда не рисуется.
  void _down() {
    _releaseTimer?.cancel();
    _sinceDown
      ..reset()
      ..start();
    _setPressed(true);
  }

  // Палец отпущен (или касание отменено). Если кнопка была нажата меньше
  // [_minPress], отпускание откладывается на оставшееся время.
  void _release() {
    final left = _minPress - _sinceDown.elapsed;
    if (left <= Duration.zero) {
      _setPressed(false);
      return;
    }
    _releaseTimer?.cancel();
    _releaseTimer = Timer(left, () {
      if (mounted) _setPressed(false);
    });
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  // Слои кнопки. [w] ширина и [bodyH] высота самой кнопки (без тени) в
  // пикселях сцены; весь холст выше на один ряд под тень. [textH] высота
  // подписи, [pressed] нажата ли кнопка.
  List<PixelLayer> _buildLayers(
    int w,
    int bodyH,
    int textH,
    bool enabled,
    bool pressed,
  ) {
    final base = enabled ? widget.color : const Color(0xFF9E9E9E);
    final border = pixelDarken(base, 0.6);
    // Полупрозрачная тень: на любом фоне она просто его затемняет.
    const shadow = Color(0x66000000);
    // Нажатая кнопка опущена на пиксель.
    final o = pressed ? 1 : 0;

    return [
      PixelLayer(id: 'button', items: [
        // Тень: видна только то, что торчит из-под кнопки, то есть нижний
        // ряд и два угла над ним. У нажатой кнопки её нет. Части тени не
        // перекрываются, чтобы полупрозрачный цвет не накладывался дважды.
        if (!pressed) ...[
          PixelRect(x: 1, y: bodyH, width: w - 2, height: 1, color: shadow),
          PixelRect(x: 0, y: bodyH - 1, width: 1, height: 1, color: shadow),
          PixelRect(x: w - 1, y: bodyH - 1, width: 1, height: 1, color: shadow),
        ],
        // Рамка: два перекрывающихся прямоугольника дают срезанные углы.
        PixelRect(x: 1, y: o, width: w - 2, height: bodyH, color: border),
        PixelRect(x: 0, y: o + 1, width: w, height: bodyH - 2, color: border),
        // Заливка внутри рамки.
        PixelRect(x: 1, y: o + 1, width: w - 2, height: bodyH - 2, color: base),
        // Подпись по центру кнопки (а не всего холста с тенью).
        PixelText(
          text: widget.label,
          font: widget.font,
          align: Alignment.topCenter,
          y: o + ((bodyH - textH) / 2).round(),
          color: enabled ? widget.textColor : const Color(0xFFE0E0E0),
        ),
      ]),
    ];
  }

  // Кнопка из спрайтов: рамка 9-slice под подписью. Кадр зависит от
  // состояния; если отдельного кадра нет, берётся основной с подкраской.
  Widget _spriteFace(
    PixelFrameStyle style,
    int w,
    int bodyH,
    int textH,
    bool enabled,
    bool pressed,
  ) {
    var name = style.frame;
    var tint = const Color(0xFFFFFFFF);
    if (!enabled) {
      if (style.disabledFrame != null) {
        name = style.disabledFrame!;
      } else {
        tint = const Color(0xFF9E9E9E);
      }
    } else if (pressed) {
      if (style.pressedFrame != null) {
        name = style.pressedFrame!;
      } else {
        tint = const Color(0xFFBDBDBD);
      }
    }
    final o = pressed ? 1 : 0; // нажатая подпись опущена на пиксель

    return Stack(
      children: [
        // Рамка занимает тело кнопки; нижний ряд (под тень) остаётся пустым.
        Positioned(
          left: 0,
          top: 0,
          width: (w * widget.scale).toDouble(),
          height: (bodyH * widget.scale).toDouble(),
          child: PixelNineSlice(
            atlas: widget.atlas,
            frame: name,
            slice: style.slice,
            scale: widget.scale,
            tile: style.tile,
            tint: tint,
          ),
        ),
        Positioned.fill(
          child: PixelCanvas(
            scale: widget.scale,
            atlas: widget.atlas,
            background: const Color(0x00000000),
            touchMode: PixelTouchMode.transparent,
            layers: [
              PixelLayer(id: 'label', items: [
                PixelText(
                  text: widget.label,
                  font: widget.font,
                  align: Alignment.topCenter,
                  y: o + ((bodyH - textH) / 2).round(),
                  color: enabled ? widget.textColor : const Color(0xFFE0E0E0),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final pressed = _pressed && enabled;

    // Размер подписи; без шрифта в атласе текст не рисуется, размер 0.
    final textSize =
        layoutText(PixelText(text: widget.label, font: widget.font), widget.atlas)
                ?.size ??
            Size.zero;
    final textH = textSize.height.toInt();
    // 1 пиксель на рамку с каждой стороны, плюс отступ.
    final w = math.max(
      widget.minWidth,
      textSize.width.toInt() + 2 * (1 + widget.padding),
    );
    final bodyH = textH + 2 * (1 + _vPadding);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: enabled ? (_) => _down() : null,
        onPointerUp: enabled ? (_) => _release() : null,
        onPointerCancel: enabled ? (_) => _release() : null,
        // GestureDetector отвечает только за само нажатие (onPressed) и за
        // отмену, если палец уехал (например, началась прокрутка списка).
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapCancel: enabled ? _release : null,
          child: SizedBox(
            width: (w * widget.scale).toDouble(),
            // + 1 ряд под тень.
            height: ((bodyH + 1) * widget.scale).toDouble(),
            child: widget.frame != null
                ? _spriteFace(widget.frame!, w, bodyH, textH, enabled, pressed)
                : PixelCanvas(
                    scale: widget.scale,
                    atlas: widget.atlas,
                    background: const Color(0x00000000),
                    // Нажатия обрабатывают Listener и GestureDetector выше,
                    // холст им не мешает.
                    touchMode: PixelTouchMode.transparent,
                    layers: _buildLayers(w, bodyH, textH, enabled, pressed),
                  ),
          ),
        ),
      ),
    );
  }
}
