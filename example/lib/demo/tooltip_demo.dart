import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 21: подсказки.
///
/// Подсказка появляется при долгом нажатии (палец) или когда мышь постоит
/// над виджетом. Оборачивать можно что угодно: пиксельную кнопку,
/// переключатель, обычный виджет. Верхняя кнопка у самого края проверяет,
/// что плашка уходит вниз, если сверху нет места.
class TooltipDemo extends StatefulWidget {
  const TooltipDemo({super.key});

  @override
  State<TooltipDemo> createState() => _TooltipDemoState();
}

class _TooltipDemoState extends State<TooltipDemo> {
  int _scale = 2;
  bool _sound = true;
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подсказки')),
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
            const Text('Удерживайте палец или наведите мышь:'),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelTooltip(
                atlas: atlas,
                scale: _scale,
                message: 'Сохранить файл',
                child: PixelButton(
                  atlas: atlas,
                  scale: _scale,
                  label: 'Сохранить',
                  onPressed: () => setState(() => _taps++),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Обычных нажатий на кнопку: $_taps'),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelTooltip(
                atlas: atlas,
                scale: _scale,
                message: 'Включает и выключает звук',
                child: PixelSwitch(
                  value: _sound,
                  scale: _scale,
                  onChanged: (v) => setState(() => _sound = v),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: PixelTooltip(
                atlas: atlas,
                scale: _scale,
                color: const Color(0xFF7B2D2D),
                message: 'Простой блок без текста',
                child: Container(width: 80, height: 40, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
