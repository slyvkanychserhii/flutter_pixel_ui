import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 20: прокручиваемый список строк.
///
/// Высоту списку задаёт родитель (здесь SizedBox). Список прокручивается
/// пальцем или колесом мыши, справа пиксельная полоса прокрутки: за ползунок
/// можно тянуть, а на дорожку нажимать. Выбранную строку хранит экран.
class ListDemo extends StatefulWidget {
  const ListDemo({super.key});

  @override
  State<ListDemo> createState() => _ListDemoState();
}

class _ListDemoState extends State<ListDemo> {
  // 40 строк: заведомо больше, чем помещается.
  static final List<String> _labels = [
    for (var i = 1; i <= 40; i++) 'Пункт $i',
  ];

  int _scale = 3;
  int? _selected = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Список')),
      body: AtlasLoader(
        builder: (context, atlas) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text(_selected == null
                  ? 'Ничего не выбрано'
                  : 'Выбрано: ${_labels[_selected!]}'),
              const SizedBox(height: 8),
              // Список занимает всё, что осталось под заголовком.
              Expanded(
                child: PixelList(
                  atlas: atlas,
                  scale: _scale,
                  labels: _labels,
                  selectedIndex: _selected,
                  onSelected: (i) => setState(() => _selected = i),
                ),
              ),
              const SizedBox(height: 8),
              // Короткий список без прокрутки: полоса без ползунка.
              SizedBox(
                height: 70,
                child: PixelList(
                  atlas: atlas,
                  scale: 2,
                  color: const Color(0xFF2E7D32),
                  labels: const ['Раз', 'Два', 'Три'],
                  selectedIndex: null,
                  onSelected: null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
