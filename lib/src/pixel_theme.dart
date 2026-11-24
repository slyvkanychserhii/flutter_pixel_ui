import 'package:flutter/widgets.dart';

/// Рамка из кадров атласа (9-slice) для кнопки или панели.
///
/// Вместо рисования примитивами виджет берёт кадр [frame] и растягивает его
/// по размеру (углы сохраняются, края и центр тянутся, см. PixelNineSlice).
/// [slice] это неизменяемые полосы кадра в его пикселях (left, top, right,
/// bottom). Подпись и содержимое должны помещаться внутри этих полос, а
/// отступы подбираются параметрами [padding] виджета.
///
/// Для кнопки можно задать отдельные кадры нажатого ([pressedFrame]) и
/// отключённого ([disabledFrame]) состояния. Если их нет, берётся [frame],
/// подкрашенный темнее (нажата) или серым (отключена). Панель использует
/// только [frame] и [tile].
@immutable
class PixelFrameStyle {
  const PixelFrameStyle({
    required this.frame,
    required this.slice,
    this.pressedFrame,
    this.disabledFrame,
    this.tile = false,
  });

  /// Имя кадра в атласе.
  final String frame;

  /// Неизменяемые полосы кадра в пикселях кадра.
  final EdgeInsets slice;

  /// Кадр нажатой кнопки или null.
  final String? pressedFrame;

  /// Кадр отключённой кнопки или null.
  final String? disabledFrame;

  /// Повторять края и центр плитками вместо растягивания.
  final bool tile;

  @override
  bool operator ==(Object other) =>
      other is PixelFrameStyle &&
      other.frame == frame &&
      other.slice == slice &&
      other.pressedFrame == pressedFrame &&
      other.disabledFrame == disabledFrame &&
      other.tile == tile;

  @override
  int get hashCode => Object.hash(frame, slice, pressedFrame, disabledFrame, tile);
}

/// Общая тема пиксельных виджетов: шрифт, масштаб и цвета в одном месте.
///
/// Каждый виджет берёт значение так: сначала параметр, заданный у самого
/// виджета, потом тема, потом собственное значение по умолчанию. Поэтому
/// достаточно один раз обернуть приложение (или экран) в [PixelThemeScope],
/// а отдельным виджетам указывать только то, что у них отличается.
///
///     PixelThemeScope(
///       theme: const PixelTheme(primary: Color(0xFFE91E63), scale: 3),
///       child: MaterialApp(...),
///     )
///
/// Важно: [PixelThemeScope] должен стоять выше всего, что его использует.
/// Меню списка, подсказки и диалоги живут в Overlay/Navigator, поэтому для
/// них тему лучше ставить над MaterialApp (WidgetsApp).
@immutable
class PixelTheme {
  const PixelTheme({
    this.font = 'main',
    this.scale,
    this.primary = const Color(0xFF3F51B5),
    this.surface = const Color(0xFF2B2B3A),
    this.success = const Color(0xFF43A047),
    this.track = const Color(0xFF424242),
    this.off = const Color(0xFF757575),
    this.text = const Color(0xFFFFFFFF),
    this.buttonFrame,
    this.panelFrame,
  }) : assert(scale == null || scale >= 1, 'scale должен быть не меньше 1');

  /// Тема по умолчанию: её значения совпадают с прежними значениями
  /// параметров виджетов, поэтому без [PixelThemeScope] ничего не меняется.
  static const PixelTheme standard = PixelTheme();

  /// Имя шрифта в секции "fonts" атласа.
  final String font;

  /// Целый множитель масштаба для всех виджетов или null: тогда у каждого
  /// виджета свой привычный масштаб (2 у текстовых, 3 у переключателей,
  /// ползунков и полос).
  final int? scale;

  /// Основной цвет: кнопки, выбранные пункты, рамки полей, бегунок.
  final Color primary;

  /// Цвет поверхностей: панели, диалоги, вкладки, подсказки.
  final Color surface;

  /// Цвет «включено» и заполнения: переключатель, полоса прогресса.
  final Color success;

  /// Цвет пустой части полос (ползунок, прогресс).
  final Color track;

  /// Цвет «выключено» у переключателя.
  final Color off;

  /// Цвет текста на кнопках и заголовков панелей.
  final Color text;

  /// Рамка кнопок из атласа или null: тогда кнопки рисуются примитивами.
  final PixelFrameStyle? buttonFrame;

  /// Рамка панелей и диалогов из атласа или null: тогда примитивами.
  final PixelFrameStyle? panelFrame;

  PixelTheme copyWith({
    String? font,
    int? scale,
    Color? primary,
    Color? surface,
    Color? success,
    Color? track,
    Color? off,
    Color? text,
    PixelFrameStyle? buttonFrame,
    PixelFrameStyle? panelFrame,
  }) =>
      PixelTheme(
        font: font ?? this.font,
        scale: scale ?? this.scale,
        primary: primary ?? this.primary,
        surface: surface ?? this.surface,
        success: success ?? this.success,
        track: track ?? this.track,
        off: off ?? this.off,
        text: text ?? this.text,
        buttonFrame: buttonFrame ?? this.buttonFrame,
        panelFrame: panelFrame ?? this.panelFrame,
      );

  /// Тема из ближайшего [PixelThemeScope] выше по дереву или [standard].
  static PixelTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PixelThemeScope>();
    return scope?.theme ?? standard;
  }

  @override
  bool operator ==(Object other) =>
      other is PixelTheme &&
      other.font == font &&
      other.scale == scale &&
      other.primary == primary &&
      other.surface == surface &&
      other.success == success &&
      other.track == track &&
      other.off == off &&
      other.text == text &&
      other.buttonFrame == buttonFrame &&
      other.panelFrame == panelFrame;

  @override
  int get hashCode =>
      Object.hash(font, scale, primary, surface, success, track, off, text,
          buttonFrame, panelFrame);
}

/// Делает [theme] доступной всем пиксельным виджетам ниже по дереву.
/// При смене темы виджеты перестраиваются сами.
class PixelThemeScope extends InheritedWidget {
  const PixelThemeScope({super.key, required this.theme, required super.child});

  final PixelTheme theme;

  @override
  bool updateShouldNotify(PixelThemeScope oldWidget) => theme != oldWidget.theme;
}
