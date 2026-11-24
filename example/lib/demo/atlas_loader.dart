import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pixel_canvas/flutter_pixel_canvas.dart';

/// Вспомогательный виджет для демонстраций: загружает демо-атлас, пока
/// идёт загрузка показывает индикатор, при ошибке показывает её текст,
/// а когда экран закрывается, освобождает атлас.
class AtlasLoader extends StatefulWidget {
  const AtlasLoader({
    super.key,
    required this.builder,
    this.jsonPath = 'assets/atlas.json',
  });

  /// Строит содержимое, когда атлас загружен.
  final Widget Function(BuildContext context, PixelAtlas atlas) builder;

  /// Путь к JSON атласа в ассетах.
  final String jsonPath;

  @override
  State<AtlasLoader> createState() => _AtlasLoaderState();
}

class _AtlasLoaderState extends State<AtlasLoader> {
  PixelAtlas? _atlas; // null, пока грузится или если была ошибка
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final atlas = await PixelAtlas.load(rootBundle, widget.jsonPath);
      // Пока грузили, экран могли закрыть: тогда сразу освобождаем атлас.
      if (!mounted) {
        atlas.dispose();
        return;
      }
      setState(() => _atlas = atlas);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _atlas?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Не удалось загрузить атлас:\n$error'),
      );
    }
    final atlas = _atlas;
    if (atlas == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder(context, atlas);
  }
}
