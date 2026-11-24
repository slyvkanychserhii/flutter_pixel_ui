import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 25: общая тема.
///
/// Все виджеты ниже созданы БЕЗ параметров цвета, шрифта и масштаба. Их
/// берёт PixelTheme из PixelThemeScope: переключатели сверху меняют тему, и
/// весь набор виджетов перекрашивается сразу. Исключение — оранжевая
/// кнопка: параметр у самого виджета сильнее темы.
class ThemeDemo extends StatefulWidget {
  const ThemeDemo({super.key});

  @override
  State<ThemeDemo> createState() => _ThemeDemoState();
}

class _ThemeDemoState extends State<ThemeDemo> {
  // Готовые темы для выбора.
  static const _themes = <String, PixelTheme>{
    'Синяя': PixelTheme(),
    'Розовая': PixelTheme(
      primary: Color(0xFFE91E63),
      surface: Color(0xFF4A1F33),
      success: Color(0xFFFF9800),
      track: Color(0xFF5D2A40),
    ),
    'Зелёная': PixelTheme(
      primary: Color(0xFF2E7D32),
      surface: Color(0xFF1B3A2A),
      success: Color(0xFF8BC34A),
      track: Color(0xFF2E4A3A),
    ),
  };

  String _themeName = 'Синяя';
  int? _scale; // null: у каждого виджета свой привычный масштаб

  bool _check = true;
  bool _switch = true;
  int _radio = 1;
  double _volume = 0.6;
  int _count = 3;
  int _segment = 0;
  String _lang = 'ru';

  PixelTheme get _theme => _themes[_themeName]!.copyWith(scale: _scale);

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Общая тема')),
      body: AtlasLoader(
        builder: (context, atlas) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final name in _themes.keys)
                  ChoiceChip(
                    label: Text(name),
                    selected: _themeName == name,
                    onSelected: (_) => setState(() => _themeName = name),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final s in <int?>[null, 2, 3])
                  ChoiceChip(
                    label: Text(s == null ? 'Масштаб: свой' : 'Масштаб x$s'),
                    selected: _scale == s,
                    onSelected: (_) => setState(() => _scale = s),
                  ),
              ],
            ),
            // Всё ниже берёт цвета, шрифт и масштаб из этой темы.
            PixelThemeScope(
              theme: _theme,
              child: Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Кнопки'),
                    Row(
                      children: [
                        PixelButton(atlas: atlas, label: 'Тема', onPressed: () {}),
                        const SizedBox(width: 8),
                        // Параметр у виджета сильнее темы.
                        PixelButton(
                          atlas: atlas,
                          label: 'Оранжевая',
                          color: const Color(0xFFFB8C00),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        PixelButton(
                          atlas: atlas,
                          label: 'Диалог',
                          onPressed: () => showPixelDialog<void>(
                            context: context,
                            // Диалог живёт в Navigator выше этой темы,
                            // поэтому передаём её ему явно.
                            builder: (ctx) => PixelThemeScope(
                              theme: _theme,
                              child: PixelDialog(
                                atlas: atlas,
                                title: 'Диалог',
                                content: const Text('Тема подхвачена.'),
                                actions: [
                                  PixelButton(
                                    atlas: atlas,
                                    label: 'Ок',
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _label('Флажок, переключатель, радио'),
                    Row(
                      children: [
                        PixelCheckbox(value: _check, onChanged: (v) => setState(() => _check = v)),
                        const SizedBox(width: 16),
                        PixelSwitch(value: _switch, onChanged: (v) => setState(() => _switch = v)),
                        const SizedBox(width: 16),
                        for (final i in [0, 1, 2]) ...[
                          PixelRadio<int>(
                            value: i,
                            groupValue: _radio,
                            onChanged: (v) => setState(() => _radio = v),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    _label('Прогресс и ползунок'),
                    PixelProgressBar(value: _volume),
                    const SizedBox(height: 8),
                    PixelSlider(
                      value: _volume,
                      width: 80,
                      onChanged: (v) => setState(() => _volume = v),
                    ),
                    _label('Счётчик, сегменты, список'),
                    PixelStepper(
                      atlas: atlas,
                      value: _count,
                      min: 0,
                      max: 10,
                      onChanged: (v) => setState(() => _count = v),
                    ),
                    const SizedBox(height: 8),
                    PixelSegmented<int>(
                      atlas: atlas,
                      segments: const {0: 'Раз', 1: 'Два', 2: 'Три'},
                      value: _segment,
                      onChanged: (v) => setState(() => _segment = v),
                    ),
                    const SizedBox(height: 8),
                    PixelDropdown<String>(
                      atlas: atlas,
                      items: const {'ru': 'Русский', 'de': 'Deutsch', 'en': 'English'},
                      value: _lang,
                      onChanged: (v) => setState(() => _lang = v),
                    ),
                    _label('Панель'),
                    PixelPanel(
                      atlas: atlas,
                      title: 'Заголовок',
                      child: const Text('Цвет панели из темы', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
