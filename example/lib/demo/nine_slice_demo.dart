import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 19: растягиваемая рамка из кадра атласа (9-slice).
///
/// Кадры «window» (16 x 16, фиксированная полоса 4) и «plate» (12 x 12,
/// полоса 3) растягиваются до любого размера: углы остаются как нарисованы,
/// края и центр тянутся. Ползунками меняется размер окна, переключатель
/// заменяет растягивание на плитки: в центре кадра шахматный узор, и там
/// разница видна сразу (растянутый узор состоит из крупных квадратов,
/// плитки сохраняют мелкий рисунок).
class NineSliceDemo extends StatefulWidget {
  const NineSliceDemo({super.key});

  @override
  State<NineSliceDemo> createState() => _NineSliceDemoState();
}

class _NineSliceDemoState extends State<NineSliceDemo> {
  int _scale = 3;
  bool _tile = false;
  double _width = 160; // в пикселях сцены
  double _height = 70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('9-slice из атласа')),
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
            SwitchListTile(
              title: const Text('Плитки вместо растягивания'),
              value: _tile,
              onChanged: (v) => setState(() => _tile = v),
            ),
            Text('Ширина: ${_width.round()} пикселей сцены'),
            Slider(
              min: 40,
              max: 200,
              value: _width,
              onChanged: (v) => setState(() => _width = v),
            ),
            Text('Высота: ${_height.round()} пикселей сцены'),
            Slider(
              min: 30,
              max: 140,
              value: _height,
              onChanged: (v) => setState(() => _height = v),
            ),
            const SizedBox(height: 8),
            // Размер рамки задаёт родитель: SizedBox в пикселях сцены.
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _width.round() * _scale.toDouble(),
                height: _height.round() * _scale.toDouble(),
                child: PixelNineSlice(
                  atlas: atlas,
                  frame: 'window',
                  slice: const EdgeInsets.all(4),
                  scale: _scale,
                  tile: _tile,
                  padding: const EdgeInsets.all(4),
                  child: const Text(
                    'Окно из кадра window',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Тот же виджет с другим кадром и подкраской:'),
            const SizedBox(height: 8),
            // Row даёт детям неограниченную ширину, поэтому рамки берут
            // размер содержимого (в Wrap или Column они заняли бы всё
            // доступное место).
            Row(
              children: [
                PixelNineSlice(
                  atlas: atlas,
                  frame: 'plate',
                  slice: const EdgeInsets.all(3),
                  scale: _scale,
                  tile: _tile,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: const Text(
                    'Табличка',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                PixelNineSlice(
                  atlas: atlas,
                  frame: 'plate',
                  slice: const EdgeInsets.all(3),
                  scale: _scale,
                  tile: _tile,
                  tint: const Color(0xFF80C0FF),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: const Text(
                    'Синяя',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
