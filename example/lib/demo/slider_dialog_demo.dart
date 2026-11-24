import 'package:flutter/material.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 16: ползунок и диалог.
///
/// Ползунок меняют нажатием в любое место полосы или перетаскиванием.
/// Значение хранит экран, а не сам ползунок. Диалог открывается поверх
/// экрана с затемнением и возвращает выбор пользователя: «Да», «Нет» или
/// null, если нажали мимо диалога.
class SliderDialogDemo extends StatefulWidget {
  const SliderDialogDemo({super.key});

  @override
  State<SliderDialogDemo> createState() => _SliderDialogDemoState();
}

class _SliderDialogDemoState extends State<SliderDialogDemo> {
  int _scale = 3;
  double _volume = 0.6; // плавный ползунок
  double _stars = 3; // ползунок с делениями: 1..5
  String _answer = 'диалог ещё не открывали';

  Future<void> _openDialog(BuildContext context, PixelAtlas atlas) async {
    final result = await showPixelDialog<bool>(
      context: context,
      builder: (ctx) => PixelDialog(
        atlas: atlas,
        title: 'Выход',
        content: const Text('Выйти без сохранения?'),
        actions: [
          PixelButton(
            atlas: atlas,
            label: 'Нет',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          PixelButton(
            atlas: atlas,
            label: 'Да',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _answer = switch (result) {
        true => 'нажали «Да»',
        false => 'нажали «Нет»',
        null => 'нажали мимо диалога (результат null)',
      };
    });
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ползунок и диалог')),
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
            _label('Громкость: ${(_volume * 100).round()}%'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelSlider(
                value: _volume,
                scale: _scale,
                width: 80,
                onChanged: (v) => setState(() => _volume = v),
              ),
            ),
            _label('Оценка с делениями: ${_stars.round()} из 5'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelSlider(
                value: _stars,
                min: 1,
                max: 5,
                divisions: 4,
                scale: _scale,
                width: 80,
                color: const Color(0xFFFFA000),
                onChanged: (v) => setState(() => _stars = v),
              ),
            ),
            _label('Отключённый (onChanged = null)'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelSlider(
                value: 0.3,
                scale: _scale,
                width: 80,
                onChanged: null,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelButton(
                atlas: atlas,
                label: 'Открыть диалог',
                scale: _scale > 3 ? 3 : _scale,
                onPressed: () => _openDialog(context, atlas),
              ),
            ),
            _label('Результат: $_answer'),
          ],
        ),
      ),
    );
  }
}
