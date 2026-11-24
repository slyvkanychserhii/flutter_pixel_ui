import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 15: флажки, радиокнопки, прогресс-бар и панель.
///
/// Всё собрано как экран настроек внутри [PixelPanel] с заголовком. Подписи
/// рядом с элементами это обычные виджеты Text: элементы пиксельные, а
/// раскладка и текст стандартные. Кнопки «плюс» и «минус» двигают
/// прогресс-бар, а масштаб меняет размер всех элементов целыми шагами.
class FormDemo extends StatefulWidget {
  const FormDemo({super.key});

  @override
  State<FormDemo> createState() => _FormDemoState();
}

class _FormDemoState extends State<FormDemo> {
  static const _levels = ['Лёгкий', 'Средний', 'Сложный'];

  int _scale = 3;
  bool _sound = true;
  bool _music = false;
  int _level = 1; // номер выбранной радиокнопки
  double _progress = 0.4;
  bool _locked = false;

  void _addProgress(double delta) {
    setState(() => _progress = (_progress + delta).clamp(0.0, 1.0));
  }

  // Строка: пиксельный элемент и подпись справа.
  Widget _row(Widget control, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          control,
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Элементы формы')),
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
            const SizedBox(height: 8),
            PixelPanel(
              atlas: atlas,
              scale: _scale,
              title: 'Настройки',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _row(
                    PixelCheckbox(
                      scale: _scale,
                      value: _sound,
                      onChanged: (v) => setState(() => _sound = v),
                    ),
                    'Звук',
                  ),
                  _row(
                    PixelCheckbox(
                      scale: _scale,
                      value: _music,
                      color: const Color(0xFF2E7D32),
                      // Музыка доступна только при включённом звуке: без
                      // onChanged флажок отключён.
                      onChanged:
                          _sound ? (v) => setState(() => _music = v) : null,
                    ),
                    'Музыка (нужен звук)',
                  ),
                  const Divider(color: Colors.white24),
                  const Text('Сложность',
                      style: TextStyle(color: Colors.white70)),
                  for (var i = 0; i < _levels.length; i++)
                    _row(
                      PixelRadio<int>(
                        scale: _scale,
                        value: i,
                        groupValue: _level,
                        onChanged: _locked
                            ? null
                            : (v) => setState(() => _level = v),
                      ),
                      _levels[i],
                    ),
                  _row(
                    PixelCheckbox(
                      scale: _scale,
                      value: _locked,
                      onChanged: (v) => setState(() => _locked = v),
                    ),
                    'Заблокировать сложность',
                  ),
                  const Divider(color: Colors.white24),
                  Text('Прогресс: ${(_progress * 100).round()}%',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  PixelProgressBar(
                    scale: _scale,
                    width: 60,
                    value: _progress,
                  ),
                  const SizedBox(height: 8),
                  // Шкала из блоков.
                  PixelProgressBar(
                    scale: _scale,
                    width: 60,
                    segments: 10,
                    value: _progress,
                    color: const Color(0xFFFFB300),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      PixelButton(
                        atlas: atlas,
                        scale: _scale,
                        label: '-10%',
                        onPressed: () => _addProgress(-0.1),
                      ),
                      const SizedBox(width: 12),
                      PixelButton(
                        atlas: atlas,
                        scale: _scale,
                        label: '+10%',
                        onPressed: () => _addProgress(0.1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
