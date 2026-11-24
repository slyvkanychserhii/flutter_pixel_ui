import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 26: кнопки и панели из спрайтов (9-slice).
///
/// Те же PixelButton и PixelPanel, но вместо примитивов их рамка берётся из
/// кадров атласа и растягивается по размеру. Рамку можно задать параметром
/// `frame` у виджета или один раз в PixelTheme (buttonFrame, panelFrame).
/// Ещё здесь показан параметр panel.expand: панель занимает всё место,
/// которое дал родитель.
class SpriteStyleDemo extends StatefulWidget {
  const SpriteStyleDemo({super.key});

  @override
  State<SpriteStyleDemo> createState() => _SpriteStyleDemoState();
}

class _SpriteStyleDemoState extends State<SpriteStyleDemo> {
  // Кадры кнопки: обычный, нажатый, отключённый (см. tools/make_demo_atlas.py).
  static const _button = PixelFrameStyle(
    frame: 'btn',
    slice: EdgeInsets.all(3),
    pressedFrame: 'btn_down',
    disabledFrame: 'btn_off',
  );
  // Только основной кадр: нажатие и отключение дают подкраску.
  static const _buttonTinted = PixelFrameStyle(frame: 'btn', slice: EdgeInsets.all(3));
  static const _window = PixelFrameStyle(frame: 'window', slice: EdgeInsets.all(4));
  static const _plate = PixelFrameStyle(frame: 'plate', slice: EdgeInsets.all(3));

  // Тема, в которой рамки заданы один раз.
  static const _spriteTheme = PixelTheme(buttonFrame: _button, panelFrame: _window);

  int _scale = 3;
  int _taps = 0;

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кнопки и панели из спрайтов')),
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
            _label('Примитивы и спрайты рядом (нажатий: $_taps)'),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PixelButton(
                  atlas: atlas,
                  scale: _scale,
                  label: 'Примитивы',
                  onPressed: () => setState(() => _taps++),
                ),
                PixelButton(
                  atlas: atlas,
                  scale: _scale,
                  label: 'Спрайты',
                  frame: _button,
                  onPressed: () => setState(() => _taps++),
                ),
                PixelButton(
                  atlas: atlas,
                  scale: _scale,
                  label: 'Подкраска',
                  frame: _buttonTinted,
                  onPressed: () => setState(() => _taps++),
                ),
                PixelButton(
                  atlas: atlas,
                  scale: _scale,
                  label: 'Отключена',
                  frame: _button,
                  onPressed: null,
                ),
              ],
            ),
            _label('Панели: примитивы, окно (slice 4), табличка (slice 3)'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                PixelPanel(
                  atlas: atlas,
                  scale: _scale,
                  title: 'Примитивы',
                  child: const Text('Рамка нарисована', style: TextStyle(color: Colors.white)),
                ),
                PixelPanel(
                  atlas: atlas,
                  scale: _scale,
                  title: 'Окно',
                  frame: _window,
                  child: const Text('Рамка из кадра', style: TextStyle(color: Colors.white)),
                ),
                PixelPanel(
                  atlas: atlas,
                  scale: _scale,
                  title: 'Табличка',
                  frame: _plate,
                  child: const Text('Другой кадр', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            _label('expand: панель на всё место родителя (SizedBox 160 высотой)'),
            SizedBox(
              height: 160,
              child: PixelPanel(
                atlas: atlas,
                scale: _scale,
                title: 'На всё место',
                frame: _window,
                expand: true,
                child: const Text('Размер задаёт родитель', style: TextStyle(color: Colors.white)),
              ),
            ),
            _label('Тема с рамками: виджеты без параметра frame'),
            PixelThemeScope(
              theme: _spriteTheme.copyWith(scale: _scale),
              child: Builder(
                builder: (context) => PixelPanel(
                  atlas: atlas,
                  title: 'Тема',
                  child: Row(
                    children: [
                      PixelButton(atlas: atlas, label: 'Кнопка', onPressed: () => setState(() => _taps++)),
                      const SizedBox(width: 8),
                      PixelButton(
                        atlas: atlas,
                        label: 'Диалог',
                        onPressed: () => showPixelDialog<void>(
                          context: context,
                          // Диалог живёт в Navigator выше этой темы:
                          // передаём тему явно.
                          builder: (ctx) => PixelThemeScope(
                            theme: _spriteTheme.copyWith(scale: _scale),
                            child: PixelDialog(
                              atlas: atlas,
                              title: 'Диалог',
                              content: const Text('Рамка из атласа.'),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
