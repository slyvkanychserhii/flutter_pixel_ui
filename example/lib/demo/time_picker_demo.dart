import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 23: выбор часов, минут и секунд.
///
/// Значение это Duration. Меняется нажатием на стрелки, удержанием стрелки
/// (непрерывно) и вертикальным перетаскиванием по числу. Разряды
/// переносятся как на часах: к 00:00:59 прибавить секунду, будет 00:01:00.
/// У будильника включён циклический режим (wrapAround): колонки идут по кругу
/// независимо друг от друга, после 00 вниз часы показывают 23.
class TimePickerDemo extends StatefulWidget {
  const TimePickerDemo({super.key});

  @override
  State<TimePickerDemo> createState() => _TimePickerDemoState();
}

class _TimePickerDemoState extends State<TimePickerDemo> {
  int _scale = 3;
  Duration _timer = const Duration(minutes: 25);
  Duration _alarm = const Duration(hours: 7, minutes: 30);

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text),
      );

  // 01:05:09 из Duration.
  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор времени')),
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
            _label('Таймер: ${_format(_timer)} (${_timer.inSeconds} с)'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelTimePicker(
                atlas: atlas,
                scale: _scale,
                value: _timer,
                onChanged: (d) => setState(() => _timer = d),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => setState(() => _timer = const Duration(minutes: 25)),
                  child: const Text('25 минут'),
                ),
                TextButton(
                  onPressed: () => setState(() => _timer = const Duration(hours: 1)),
                  child: const Text('1 час'),
                ),
                TextButton(
                  onPressed: () => setState(() => _timer = Duration.zero),
                  child: const Text('Сброс'),
                ),
                TextButton(
                  // Крайнее значение: стрелки вверх у колонок станут серыми.
                  onPressed: () => setState(
                      () => _timer = const Duration(hours: 99, minutes: 59, seconds: 59)),
                  child: const Text('Максимум'),
                ),
              ],
            ),
            _label('Будильник по кругу (00 вниз даёт 23), без секунд: ${_format(_alarm).substring(0, 5)}'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelTimePicker(
                atlas: atlas,
                scale: _scale,
                value: _alarm,
                maxHours: 23,
                showSeconds: false,
                wrapAround: true, // по кругу: после 00 вниз идёт 23
                color: const Color(0xFF2E7D32),
                onChanged: (d) => setState(() => _alarm = d),
              ),
            ),
            _label('Отключённый'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelTimePicker(
                atlas: atlas,
                scale: _scale,
                value: const Duration(minutes: 5),
                onChanged: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
