import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 17: сегментные кнопки и вкладки.
///
/// Выбор хранит экран: элементы только сообщают, что нажали. У вкладок
/// содержимое подставляется по номеру выбранной вкладки; внутри лежат
/// обычные виджеты и пиксельные элементы из предыдущих шагов.
class TabsSegmentedDemo extends StatefulWidget {
  const TabsSegmentedDemo({super.key});

  @override
  State<TabsSegmentedDemo> createState() => _TabsSegmentedDemoState();
}

class _TabsSegmentedDemoState extends State<TabsSegmentedDemo> {
  int _scale = 2;
  int _level = 1;
  String _unit = 'км';
  int _tab = 0;
  bool _hints = true;
  bool _vibration = false;
  double _volume = 0.5;

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text),
      );

  // Содержимое вкладки по её номеру.
  Widget _tabContent() {
    Widget row(Widget control, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            control,
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white)),
            ),
          ]),
        );

    return switch (_tab) {
      0 => Column(children: [
          row(
            PixelCheckbox(
              value: _hints,
              scale: _scale,
              onChanged: (v) => setState(() => _hints = v),
            ),
            'Подсказки',
          ),
          row(
            PixelCheckbox(
              value: _vibration,
              scale: _scale,
              onChanged: (v) => setState(() => _vibration = v),
            ),
            'Вибрация',
          ),
        ]),
      1 => Column(
          // Явно прижимаем к левому краю: по умолчанию Column центрирует.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelSlider(
              value: _volume,
              scale: _scale,
              width: 80,
              onChanged: (v) => setState(() => _volume = v),
            ),
          ],
        ),
      _ => const Text(
          'Здесь могло быть что угодно: вкладка показывает любой виджет.',
          style: TextStyle(color: Colors.white),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вкладки и сегменты')),
      body: AtlasLoader(
        builder: (context, atlas) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _scale > 1 ? () => setState(() => _scale--) : null,
                ),
                Text('Масштаб x$_scale'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _scale < 4 ? () => setState(() => _scale++) : null,
                ),
              ],
            ),
            _label('Сложность: ${const ['лёгкая', 'средняя', 'высокая'][_level]}'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelSegmented<int>(
                atlas: atlas,
                scale: _scale,
                segments: const {0: 'Лёгкая', 1: 'Средняя', 2: 'Высокая'},
                value: _level,
                onChanged: (v) => setState(() => _level = v),
              ),
            ),
            _label('Единицы: $_unit'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelSegmented<String>(
                atlas: atlas,
                scale: _scale,
                color: const Color(0xFF2E7D32),
                segments: const {'км': 'км', 'mi': 'mi'},
                value: _unit,
                onChanged: (v) => setState(() => _unit = v),
              ),
            ),
            _label('Отключённые сегменты'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelSegmented<int>(
                atlas: atlas,
                scale: _scale,
                segments: const {0: 'Раз', 1: 'Два'},
                value: 0,
                onChanged: null,
              ),
            ),
            const SizedBox(height: 24),
            // Панель занимает всё место, которое ей дали: здесь это
            // SizedBox фиксированной высоты, поэтому вкладки одного размера.
            SizedBox(
              height: 220,
              child: PixelTabs(
                atlas: atlas,
                scale: _scale,
                tabs: const ['Игра', 'Звук', 'Прочее'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
                child: _tabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
