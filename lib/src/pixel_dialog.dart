import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

import 'pixel_panel.dart';
import 'pixel_theme.dart';

/// Показывает пиксельный диалог поверх текущего экрана.
///
/// Экран под диалогом затемняется. Нажатие мимо диалога закрывает его (если
/// [barrierDismissible]), результат будет null. Закрыть диалог кнопкой
/// можно через `Navigator.pop(context, результат)`; результат вернётся из
/// этой функции.
///
///     final ok = await showPixelDialog<bool>(
///       context: context,
///       builder: (context) => PixelDialog(
///         atlas: atlas,
///         title: 'Выход',
///         content: const Text('Выйти без сохранения?'),
///         actions: [
///           PixelButton(atlas: atlas, label: 'Нет',
///               onPressed: () => Navigator.pop(context, false)),
///           PixelButton(atlas: atlas, label: 'Да',
///               onPressed: () => Navigator.pop(context, true)),
///         ],
///       ),
///     );
Future<T?> showPixelDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Закрыть',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 80),
    pageBuilder: (context, _, __) => builder(context),
  );
}

/// Пиксельный диалог: [PixelPanel] с заголовком, содержимым и рядом кнопок.
///
/// Обычно показывается через [showPixelDialog]. Ширина равна доступной, но не
/// больше [maxWidth]; высота по содержимому. Кнопки [actions] выстраиваются
/// в ряд справа и переносятся, если не помещаются.
class PixelDialog extends StatelessWidget {
  const PixelDialog({
    super.key,
    required this.atlas,
    required this.title,
    required this.content,
    this.actions = const [],
    this.font,
    this.scale,
    this.color,
    this.maxWidth = 300,
  });

  /// Атлас со шрифтом [font] (для заголовка).
  final PixelAtlas atlas;

  final String title;

  /// Содержимое: обычный виджет (Text, Column...). Цвет текста по умолчанию
  /// белый.
  final Widget content;

  /// Кнопки внизу, обычно [PixelButton].
  final List<Widget> actions;

  /// null: берётся из [PixelTheme] (font).
  final String? font;

  /// Целый множитель масштаба рамки, как у [PixelPanel.scale].
  /// null: берётся из [PixelTheme.scale], а если и там null, то 2.
  final int? scale;

  /// null: берётся из [PixelTheme] (surface).
  final Color? color;

  /// Наибольшая ширина диалога в обычных пикселях.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = PixelTheme.of(context);
    return _PixelDialogImpl(
      atlas: atlas,
      title: title,
      content: content,
      actions: actions,
      font: font ?? theme.font,
      scale: scale ?? theme.scale ?? 2,
      color: color ?? theme.surface,
      maxWidth: maxWidth,
    );
  }
}

/// Реализация PixelDialog: все значения уже подобраны (параметр, тема или умолчание).
class _PixelDialogImpl extends StatelessWidget {
  const _PixelDialogImpl({
    required this.atlas,
    required this.title,
    required this.content,
    this.actions = const [],
    this.font = 'main',
    this.scale = 2,
    this.color = const Color(0xFF2B2B3A),
    this.maxWidth = 300,
  });

  /// Атлас со шрифтом [font] (для заголовка).
  final PixelAtlas atlas;

  final String title;

  /// Содержимое: обычный виджет (Text, Column...). Цвет текста по умолчанию
  /// белый.
  final Widget content;

  /// Кнопки внизу, обычно [PixelButton].
  final List<Widget> actions;

  final String font;

  /// Целый множитель масштаба рамки, как у [PixelPanel.scale].
  final int scale;

  final Color color;

  /// Наибольшая ширина диалога в обычных пикселях.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // Material нужен только как основа для текста: маршрут диалога его не
    // создаёт, и без него Text рисуется с жёлтым подчёркиванием.
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: PixelPanel(
            atlas: atlas,
            font: font,
            title: title,
            scale: scale,
            color: color,
            padding: const EdgeInsets.all(12),
            child: DefaultTextStyle(
              style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
