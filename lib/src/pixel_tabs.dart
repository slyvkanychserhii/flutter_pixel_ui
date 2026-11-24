import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Вкладки: ряд ярлыков сверху и панель с содержимым под ними.
///
/// Выбранный ярлык выше остальных и срастается с панелью (под ним нет
/// линии), невыбранные ниже и темнее. Рамка и ярлыки рисуются одним холстом
/// на заднем плане, содержимое [child] обычные виджеты.
///
/// Виджет не хранит выбор: приложение держит [index], в [onChanged]
/// получает номер нажатого ярлыка и само подставляет нужное содержимое:
///
///     PixelTabs(
///       atlas: atlas,
///       tabs: const ['Игра', 'Звук'],
///       index: tab,
///       onChanged: (i) => setState(() => tab = i),
///       child: tab == 0 ? gameSettings : soundSettings,
///     )
///
/// Панель занимает всё место, которое дал родитель; по оси без ограничения
/// (например, высота в ListView) её размер определяется содержимым плюс
/// [padding]. Содержимое лежит в левом верхнем углу; чтобы растянуть его,
/// оберните в SizedBox.expand или Align. Ряд ярлыков должен помещаться по
/// ширине: перенос не поддерживается.
class PixelTabs extends StatelessWidget {
  const PixelTabs({
    super.key,
    required this.atlas,
    required this.tabs,
    required this.index,
    required this.onChanged,
    required this.child,
    this.font,
    this.scale,
    this.color,
    this.padding = const EdgeInsets.all(8),
    this.tabPadding = 4,
  });

  final PixelAtlas atlas;

  /// Подписи ярлыков.
  final List<String> tabs;

  /// Номер выбранной вкладки.
  final int index;

  /// Вызывается при нажатии на другой ярлык.
  final ValueChanged<int> onChanged;

  /// Содержимое выбранной вкладки.
  final Widget child;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет панели; рамка и невыбранные ярлыки получаются из него.
  /// null: берётся из [PixelTheme] (surface).
  final Color? color;

  /// Отступ от рамки до содержимого (в обычных пикселях).
  final EdgeInsets padding;

  /// Отступ от подписи до края ярлыка в пикселях сцены.
  final int tabPadding;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelTabsImpl(
      atlas: atlas,
      tabs: tabs,
      index: index,
      onChanged: onChanged,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.surface,
      padding: padding,
      tabPadding: tabPadding,
      child: child,
    );
  }
}

/// Реализация PixelTabs: все значения уже подобраны (параметр, тема или умолчание).
class _PixelTabsImpl extends StatelessWidget {
  const _PixelTabsImpl({
    required this.atlas,
    required this.tabs,
    required this.index,
    required this.onChanged,
    required this.child,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF2B2B3A),
    this.padding = const EdgeInsets.all(8),
    this.tabPadding = 4,
  })  : assert(scale >= 1, 'scale должен быть не меньше 1'),
        assert(tabs.length > 0, 'нужна хотя бы одна вкладка'),
        assert(index >= 0 && index < tabs.length, 'index вне диапазона');

  final PixelAtlas atlas;

  /// Подписи ярлыков.
  final List<String> tabs;

  /// Номер выбранной вкладки.
  final int index;

  /// Вызывается при нажатии на другой ярлык.
  final ValueChanged<int> onChanged;

  /// Содержимое выбранной вкладки.
  final Widget child;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет панели; рамка и невыбранные ярлыки получаются из него.
  final Color color;

  /// Отступ от рамки до содержимого (в обычных пикселях).
  final EdgeInsets padding;

  /// Отступ от подписи до края ярлыка в пикселях сцены.
  final int tabPadding;

  // Размер подписи в пикселях сцены (0, если шрифта нет в атласе).
  Size _textSize(String label) =>
      layoutText(PixelText(text: label, font: font), atlas)?.size ??
      Size.zero;

  // Геометрия ярлыков в пикселях сцены: высота подписи, высота ряда [rowH]
  // (вместе с верхней рамкой, до линии панели), начала и ширины ярлыков.
  ({int textH, int rowH, List<int> starts, List<int> widths, int total})
      _geometry() {
    var textH = 0;
    final widths = <int>[];
    for (final label in tabs) {
      final size = _textSize(label);
      if (size.height.toInt() > textH) textH = size.height.toInt();
      widths.add(size.width.toInt() + 2 * (1 + tabPadding));
    }
    // Первый ярлык отступает от левого края на 2, между ярлыками зазор 1.
    final starts = <int>[];
    var x = 2;
    for (final w in widths) {
      starts.add(x);
      x += w + 1;
    }
    return (
      textH: textH,
      rowH: textH + 8, // рамка 1 + отступ 3 + подпись + отступ 3 + строка панели 1
      starts: starts,
      widths: widths,
      total: x,
    );
  }

  // Ярлык со срезанными верхними углами: рамка и заливка. Он занимает
  // строки от [top] до [bottom] включительно; нижняя строка рамки есть
  // только у невыбранного.
  List<PixelObject> _tab(
    int x,
    int w,
    int top,
    int bottom,
    Color border,
    Color fill,
    bool selected,
  ) {
    final hgt = bottom - top + 1;
    return [
      PixelRect(x: x + 1, y: top, width: w - 2, height: hgt, color: border),
      PixelRect(x: x, y: top + 1, width: w, height: hgt - 1, color: border),
      PixelRect(
        x: x + 1,
        y: top + 1,
        width: w - 2,
        // У выбранного заливка доходит до самого низа и перекрывает линию
        // панели; у невыбранного внизу остаётся строка рамки.
        height: selected ? hgt - 1 : hgt - 2,
        color: fill,
      ),
    ];
  }

  List<PixelLayer> _buildLayers(int w, int h) {
    final g = _geometry();
    final border = pixelDarken(color, 0.6);
    final idle = pixelDarken(color, 0.25);
    final line = g.rowH - 1; // строка верхней рамки панели

    return [
      PixelLayer(id: 'tabs', items: [
        // Панель: рамка со срезанными углами и заливка, начинается на
        // строке [line].
        PixelRect(x: 1, y: line, width: w - 2, height: h - line, color: border),
        PixelRect(x: 0, y: line + 1, width: w, height: h - line - 2, color: border),
        PixelRect(x: 1, y: line + 1, width: w - 2, height: h - line - 2, color: color),
        // Невыбранные ярлыки: ниже на 2 строки и тёмные.
        for (var i = 0; i < tabs.length; i++)
          if (i != index)
            ..._tab(g.starts[i], g.widths[i], 2, line - 1, border, idle, false),
        // Выбранный ярлык рисуется последним и срастается с панелью.
        ..._tab(g.starts[index], g.widths[index], 0, line, border, color, true),
        for (var i = 0; i < tabs.length; i++)
          PixelText(
            text: tabs[i],
            font: font,
            x: g.starts[i] + 1 + tabPadding,
            // Подпись на одной высоте у всех ярлыков: не прыгает при выборе.
            y: 4,
            color: i == index
                ? const Color(0xFFFFFFFF)
                : const Color(0xFFBDBDBD),
          ),
      ]),
    ];
  }

  // Номер ярлыка под горизонтальной координатой [dx] или null.
  int? _tabAt(double dx) {
    final g = _geometry();
    final x = dx / scale;
    for (var i = 0; i < g.starts.length; i++) {
      if (x >= g.starts[i] && x < g.starts[i] + g.widths[i]) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final g = _geometry();
    final rowPx = (g.rowH * scale).toDouble();

    // Панель занимает всё доступное место. Если родитель не ограничивает
    // размер (например, высоту в ListView), по этой оси панель берёт
    // размер содержимого.
    return LayoutBuilder(
      builder: (context, box) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: box.hasBoundedWidth ? box.maxWidth : 0,
            minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
          ),
          child: _buildStack(g, rowPx),
        );
      },
    );
  }

  Widget _buildStack(
    ({int textH, int rowH, List<int> starts, List<int> widths, int total}) g,
    double rowPx,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth / scale).floor();
              final h = (box.maxHeight / scale).floor();
              return PixelCanvas(
                scale: scale,
                atlas: atlas,
                background: const Color(0x00000000),
                touchMode: PixelTouchMode.transparent,
                layers: w < g.total || h < g.rowH + 4 ? const [] : _buildLayers(w, h),
              );
            },
          ),
        ),
        // Нажатия на ярлыки: полоса над содержимым.
        Positioned(
          left: 0,
          top: 0,
          width: (g.total * scale).toDouble(),
          height: rowPx,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final i = _tabAt(d.localPosition.dx);
              if (i != null && i != index) onChanged(i);
            },
            child: const SizedBox.expand(),
          ),
        ),
        // Содержимое начинается под рядом ярлыков и верхней рамкой панели.
        Padding(
          padding: padding + EdgeInsets.only(top: ((g.rowH + 1) * scale).toDouble()),
          child: child,
        ),
      ],
    );
  }
}
