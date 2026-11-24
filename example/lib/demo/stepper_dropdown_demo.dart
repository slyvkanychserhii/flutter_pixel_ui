import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 18: шаговый счётчик и выпадающий список.
///
/// Значения хранит экран. Счётчик меняется нажатием на «−» и «+», а если
/// держать палец, то непрерывно. Ещё значение можно менять, перетаскивая
/// палец вправо или влево по самому числу. Выпадающий список открывает меню поверх
/// экрана; нажатие мимо меню закрывает его без выбора.
class StepperDropdownDemo extends StatefulWidget {
  const StepperDropdownDemo({super.key});

  @override
  State<StepperDropdownDemo> createState() => _StepperDropdownDemoState();
}

class _StepperDropdownDemoState extends State<StepperDropdownDemo> {
  int _scale = 3;
  int _count = 5;
  int _step10 = 50;
  String _lang = 'ru';

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Счётчик и список')),
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
                  onPressed: _scale < 5 ? () => setState(() => _scale++) : null,
                ),
              ],
            ),
            _label('Количество: $_count (от 0 до 10), тяните по числу'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelStepper(
                atlas: atlas,
                scale: _scale,
                value: _count,
                min: 0,
                max: 10,
                onChanged: (v) => setState(() => _count = v),
              ),
            ),
            _label('Шаг 10, от 0 до 100: $_step10 (держите палец)'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelStepper(
                atlas: atlas,
                scale: _scale,
                value: _step10,
                min: 0,
                max: 100,
                step: 10,
                color: const Color(0xFF2E7D32),
                onChanged: (v) => setState(() => _step10 = v),
              ),
            ),
            _label('Отключённый счётчик'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelStepper(
                atlas: atlas,
                scale: _scale,
                value: 3,
                min: 0,
                max: 10,
                onChanged: null,
              ),
            ),
            _label('Язык: $_lang'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelDropdown<String>(
                atlas: atlas,
                scale: _scale,
                items: const {
                  'ru': 'Русский',
                  'de': 'Deutsch',
                  'en': 'English',
                  'pl': 'Polski',
                },
                value: _lang,
                onChanged: (v) => setState(() => _lang = v),
              ),
            ),
            _label('Отключённый список'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelDropdown<String>(
                atlas: atlas,
                scale: _scale,
                items: const {'a': 'Нельзя выбрать'},
                value: 'a',
                onChanged: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
