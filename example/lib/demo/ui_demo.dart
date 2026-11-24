import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 14: готовые элементы интерфейса.
///
/// [PixelButton] и [PixelSwitch] это обычные виджеты: лежат в Row и Column
/// рядом с обычным текстом, а нарисованы пиксельным холстом. Переключатель
/// справа включает и выключает вторую кнопку (у выключенной нет onPressed,
/// и она серая). Масштаб меняет размер всех элементов целыми шагами.
class UiDemo extends StatefulWidget {
  const UiDemo({super.key});

  @override
  State<UiDemo> createState() => _UiDemoState();
}

class _UiDemoState extends State<UiDemo> {
  int _scale = 3;
  int _presses = 0;
  int _greenPresses = 0;
  bool _enabled = true;
  bool _sound = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кнопки и переключатель')),
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
                  onPressed: _scale < 6 ? () => setState(() => _scale++) : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PixelButton(
                  atlas: atlas,
                  scale: _scale,
                  label: 'Нажми',
                  onPressed: () => setState(() => _presses++),
                ),
                PixelButton(
                  atlas: atlas,
                  scale: _scale,
                  label: 'Зелёная',
                  color: const Color(0xFF2E7D32),
                  // null отключает кнопку.
                  onPressed:
                      _enabled ? () => setState(() => _greenPresses++) : null,
                ),
                PixelButton(
                  atlas: atlas,
                  scale: _scale,
                  label: 'OK',
                  minWidth: 40,
                  color: const Color(0xFFC62828),
                  onPressed: () => setState(() => _presses++),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Нажатий: $_presses, зелёной: $_greenPresses'),
            const SizedBox(height: 24),
            Row(
              children: [
                PixelSwitch(
                  scale: _scale,
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
                const SizedBox(width: 12),
                Text(_enabled ? 'Зелёная кнопка включена' : 'Зелёная выключена'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                PixelSwitch(
                  scale: _scale,
                  value: _sound,
                  onColor: const Color(0xFF1565C0),
                  onChanged: (value) => setState(() => _sound = value),
                ),
                const SizedBox(width: 12),
                Text(_sound ? 'Звук: да' : 'Звук: нет'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Без onChanged переключатель отключён.
                PixelSwitch(scale: _scale, value: true, onChanged: null),
                const SizedBox(width: 12),
                const Text('Отключён'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
