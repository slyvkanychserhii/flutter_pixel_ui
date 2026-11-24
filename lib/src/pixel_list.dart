import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_colors.dart';
import 'pixel_theme.dart';

/// Прокручиваемый список строк с выбором одного пункта.
///
/// Рамка, строки и полоса прокрутки это холсты, подписи рисуются шрифтом из
/// атласа. Список занимает всё место, которое дал родитель, поэтому высота
/// должна быть ограничена (SizedBox, Expanded). Прокручивается пальцем или
/// колесом мыши, как обычный ListView, а справа есть пиксельная полоса, за
/// которую тоже можно тянуть и на которую можно нажимать.
///
///     SizedBox(
///       height: 160,
///       child: PixelList(
///         atlas: atlas,
///         labels: const ['Первый', 'Второй', 'Третий'],
///         selectedIndex: index,
///         onSelected: (i) => setState(() => index = i),
///       ),
///     )
///
/// Выбор хранит приложение: [onSelected] получает номер нажатой строки.
/// Без [onSelected] строки не нажимаются (список остаётся прокручиваемым).
///
/// Когда прокрутка останавливается, смещение округляется до целого пикселя
/// сцены, чтобы строки лежали на пиксельной сетке.
class PixelList extends StatelessWidget {
  const PixelList({
    super.key,
    required this.atlas,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.font,
    this.scale,
    this.color,
    this.padding = 3,
  });

  final PixelAtlas atlas;

  /// Подписи строк.
  final List<String> labels;

  /// Номер выбранной строки или null.
  final int? selectedIndex;

  /// Вызывается с номером нажатой строки. null отключает выбор.
  final ValueChanged<int>? onSelected;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// Цвет выбранной строки и ползунка полосы прокрутки.
  /// null: берётся из [PixelTheme] (primary).
  final Color? color;

  /// Отступ от края строки до подписи в пикселях сцены.
  final int padding;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelListImpl(
      atlas: atlas,
      labels: labels,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.primary,
      padding: padding,
    );
  }
}

/// Реализация PixelList: все значения уже подобраны (параметр, тема или умолчание).
class _PixelListImpl extends StatefulWidget {
  const _PixelListImpl({
    required this.atlas,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF3F51B5),
    this.padding = 3,
  })  : assert(scale >= 1, 'scale должен быть не меньше 1'),
        assert(padding >= 0, 'padding не может быть отрицательным');

  final PixelAtlas atlas;

  /// Подписи строк.
  final List<String> labels;

  /// Номер выбранной строки или null.
  final int? selectedIndex;

  /// Вызывается с номером нажатой строки. null отключает выбор.
  final ValueChanged<int>? onSelected;

  final String font;

  /// Целый множитель масштаба, как у [PixelCanvas.scale].
  final int scale;

  /// Цвет выбранной строки и ползунка полосы прокрутки.
  final Color color;

  /// Отступ от края строки до подписи в пикселях сцены.
  final int padding;

  @override
  State<_PixelListImpl> createState() => _PixelListState();
}

class _PixelListState extends State<_PixelListImpl> {
  // Ширина полосы прокрутки в пикселях сцены.
  static const int _barW = 5;

  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Высота подписи самой высокой строки (шрифт один, поэтому берём по
  // первой строке; у шрифта одна высота строки).
  int _textH() {
    final size = layoutText(
      PixelText(text: 'A', font: widget.font),
      widget.atlas,
    )?.size;
    return size?.height.toInt() ?? 0;
  }

  // Высота строки в пикселях сцены.
  int get _rowH => _textH() + 6;

  // Рамка: срезанные углы и тёмная заливка.
  List<PixelLayer> _frameLayers(int w, int h) {
    final border = pixelDarken(widget.color, 0.7);
    return [
      PixelLayer(id: 'list-frame', items: [
        PixelRect(x: 1, y: 0, width: w - 2, height: h, color: border),
        PixelRect(x: 0, y: 1, width: w, height: h - 2, color: border),
        PixelRect(
          x: 1,
          y: 1,
          width: w - 2,
          height: h - 2,
          color: pixelDarken(widget.color, 0.8),
        ),
      ]),
    ];
  }

  Widget _row(int i) {
    final selected = widget.selectedIndex == i;
    final rowH = _rowH;
    final textH = _textH();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onSelected == null ? null : () => widget.onSelected!(i),
      child: SizedBox(
        height: (rowH * widget.scale).toDouble(),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth / widget.scale).floor();
            return PixelCanvas(
              scale: widget.scale,
              atlas: widget.atlas,
              background: const Color(0x00000000),
              touchMode: PixelTouchMode.transparent,
              layers: [
                PixelLayer(id: 'row', items: [
                  if (selected)
                    PixelRect(x: 0, y: 0, width: w, height: rowH, color: widget.color),
                  PixelText(
                    text: widget.labels[i],
                    font: widget.font,
                    x: widget.padding,
                    y: ((rowH - textH) / 2).round(),
                    color: const Color(0xFFFFFFFF),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  // Привязка к сетке уже запланирована (см. _onNotification).
  bool _snapScheduled = false;

  // Округляет смещение до целого пикселя сцены.
  void _snapToGrid() {
    _snapScheduled = false;
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final snapped = (pos.pixels / widget.scale).round() * widget.scale;
    final target =
        snapped.clamp(pos.minScrollExtent, pos.maxScrollExtent).toDouble();
    if ((target - pos.pixels).abs() > 0.01) _controller.jumpTo(target);
  }

  bool _onNotification(Notification n) {
    // Когда прокрутка остановилась, смещение округляется до целого пикселя
    // сцены (сдвиг не больше половины пикселя, на глаз незаметен).
    //
    // Делать это прямо здесь нельзя: jumpTo сам останавливает прокрутку и
    // порождает ещё одно такое же уведомление, пока смещение не обновилось,
    // получилась бы бесконечная рекурсия. Поэтому прыжок откладывается
    // в микрозадачу; повторные уведомления до неё сводятся в один вызов.
    if (n is ScrollEndNotification && !_snapScheduled) {
      _snapScheduled = true;
      scheduleMicrotask(_snapToGrid);
    }
    // После первой раскладки и при смене размеров перерисовываем полосу.
    if (n is ScrollMetricsNotification) setState(() {});
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              assert(box.hasBoundedHeight,
                  'PixelList нужна ограниченная высота: оберните в SizedBox или Expanded');
              final w = (box.maxWidth / scale).floor();
              final h = (box.maxHeight / scale).floor();
              return PixelCanvas(
                scale: scale,
                atlas: widget.atlas,
                background: const Color(0x00000000),
                touchMode: PixelTouchMode.transparent,
                layers: w < 8 || h < 4 ? const [] : _frameLayers(w, h),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(scale.toDouble()), // рамка 1 пиксель сцены
          child: Row(
            children: [
              Expanded(
                child: NotificationListener<Notification>(
                  onNotification: _onNotification,
                  child: ListView.builder(
                    controller: _controller,
                    padding: EdgeInsets.zero,
                    itemExtent: (_rowH * scale).toDouble(),
                    itemCount: widget.labels.length,
                    itemBuilder: (context, i) => _row(i),
                  ),
                ),
              ),
              SizedBox(
                width: (_barW * scale).toDouble(),
                child: _ScrollBar(
                  controller: _controller,
                  scale: scale,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Пиксельная полоса прокрутки: дорожка и ползунок. Ползунок можно тянуть,
/// на дорожку можно нажать, чтобы перейти в это место.
class _ScrollBar extends StatelessWidget {
  const _ScrollBar({
    required this.controller,
    required this.scale,
    required this.color,
  });

  final ScrollController controller;
  final int scale;
  final Color color;

  // Размеры ползунка в пикселях сцены для дорожки высотой [trackH]:
  // (высота, смещение сверху) или null, если прокручивать нечего.
  ({int height, int top})? _thumb(int trackH) {
    if (!controller.hasClients) return null;
    final pos = controller.position;
    if (!pos.hasContentDimensions || pos.maxScrollExtent <= 0) return null;
    final viewport = pos.viewportDimension;
    final total = viewport + pos.maxScrollExtent;
    final height = math.max(6, (trackH * viewport / total).round());
    final free = math.max(0, trackH - height);
    final top = (free * (pos.pixels / pos.maxScrollExtent)).round();
    return (height: height, top: top.clamp(0, free));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth / scale).floor();
        final trackH = (box.maxHeight / scale).floor();

        // Перевод вертикального сдвига пальца в смещение списка.
        void dragBy(double dy) {
          final t = _thumb(trackH);
          if (t == null) return;
          final pos = controller.position;
          final free = trackH - t.height;
          if (free <= 0) return;
          final ratio = pos.maxScrollExtent / (free * scale);
          controller.jumpTo((pos.pixels + dy * ratio)
              .clamp(0.0, pos.maxScrollExtent)
              .toDouble());
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Нажатие на дорожку ставит середину ползунка под палец.
          onTapDown: (d) {
            final t = _thumb(trackH);
            if (t == null) return;
            final y = d.localPosition.dy / scale;
            dragBy((y - (t.top + t.height / 2)) * scale);
          },
          onVerticalDragUpdate: (d) => dragBy(d.delta.dy),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final thumb = _thumb(trackH);
              final track = pixelDarken(color, 0.65);
              return PixelCanvas(
                scale: scale,
                background: const Color(0x00000000),
                touchMode: PixelTouchMode.transparent,
                layers: w < 3 || trackH < 8
                    ? const []
                    : [
                        PixelLayer(id: 'scrollbar', items: [
                          PixelRect(
                              x: 1, y: 0, width: w - 2, height: trackH, color: track),
                          if (thumb != null) ...[
                            PixelRect(
                              x: 0,
                              y: thumb.top,
                              width: w,
                              height: thumb.height,
                              color: pixelDarken(color, 0.4),
                            ),
                            PixelRect(
                              x: 1,
                              y: thumb.top + 1,
                              width: w - 2,
                              height: thumb.height - 2,
                              color: color,
                            ),
                          ],
                        ]),
                      ],
              );
            },
          ),
        );
      },
    );
  }
}
