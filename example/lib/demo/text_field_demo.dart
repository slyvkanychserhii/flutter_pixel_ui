import 'package:flutter/material.dart';
import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';

import 'atlas_loader.dart';

/// Демонстрация 22: поле ввода.
///
/// Текст рисуется шрифтом из атласа, а ввод выполняет обычный EditableText
/// под ним, поэтому работает системная клавиатура, стрелки, Backspace,
/// Ctrl+C и Ctrl+V. Символов, которых нет в шрифте (например, смайлики),
/// поле не принимает. Нажатие ставит курсор, перетаскивание выделяет текст,
/// двойное нажатие выделяет слово. Есть поле пароля (символы заменены на «*»)
/// и поле с шаблоном телефона.
class TextFieldDemo extends StatefulWidget {
  const TextFieldDemo({super.key});

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  final TextEditingController _name = TextEditingController();
  int _scale = 3;
  String _submitted = '';
  bool _showPassword = false;
  final TextEditingController _password = TextEditingController();
  String _phone = '';

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поле ввода')),
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
            _label('Имя (во всю ширину, Enter отправляет):'),
            PixelTextField(
              atlas: atlas,
              scale: _scale,
              controller: _name,
              hint: 'Введите имя',
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => setState(() => _submitted = v),
            ),
            const SizedBox(height: 8),
            Text('Привет, ${_name.text.isEmpty ? '...' : _name.text}'),
            Text('Отправлено по Enter: ${_submitted.isEmpty ? '-' : _submitted}'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  _name.clear();
                  setState(() => _submitted = '');
                },
                child: const Text('Очистить'),
              ),
            ),
            _label('Код до 8 символов (ширина 70):'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelTextField(
                atlas: atlas,
                scale: _scale,
                width: 70,
                maxLength: 8,
                hint: 'Код',
                color: const Color(0xFF2E7D32),
              ),
            ),
            _label('Пароль (двойное нажатие выделяет всё):'),
            Row(
              children: [
                PixelTextField(
                  atlas: atlas,
                  scale: _scale,
                  width: 80,
                  controller: _password,
                  hint: 'Пароль',
                  obscureText: !_showPassword,
                  color: const Color(0xFFAD1457),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ],
            ),
            _label('Телефон по шаблону +7 (###) ###-##-##: $_phone'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelTextField(
                atlas: atlas,
                scale: _scale,
                width: 130,
                mask: '+7 (###) ###-##-##',
                hint: 'Телефон',
                color: const Color(0xFFEF6C00),
                onChanged: (v) => setState(() => _phone = v),
              ),
            ),
            _label('Отключённое поле:'),
            Align(
              alignment: Alignment.centerLeft,
              child: PixelTextField(
                atlas: atlas,
                scale: _scale,
                width: 70,
                hint: 'Отключено',
                enabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
