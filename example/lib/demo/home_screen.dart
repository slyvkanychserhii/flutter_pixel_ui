import 'package:flutter/material.dart';

import 'demos.dart';

/// Главный экран: список демонстраций. Нажатие открывает выбранный экран.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pixel UI: демонстрации')),
      body: ListView.separated(
        itemCount: demos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final demo = demos[index];
          return ListTile(
            title: Text(demo.title),
            subtitle: Text(demo.description),
            trailing: const Icon(Icons.chevron_right),
            // Navigator.push кладёт новый экран поверх текущего;
            // кнопка "назад" в AppBar вернёт на этот список.
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: demo.builder),
            ),
          );
        },
      ),
    );
  }
}
