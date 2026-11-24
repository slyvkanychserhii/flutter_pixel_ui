import 'package:flutter/widgets.dart';

import 'form_demo.dart';
import 'list_demo.dart';
import 'nine_slice_demo.dart';
import 'slider_dialog_demo.dart';
import 'sprite_style_demo.dart';
import 'stepper_dropdown_demo.dart';
import 'tabs_segmented_demo.dart';
import 'text_field_demo.dart';
import 'theme_demo.dart';
import 'time_picker_demo.dart';
import 'tooltip_demo.dart';
import 'ui_demo.dart';

/// Одна запись списка демонстраций.
class DemoEntry {
  const DemoEntry({
    required this.title,
    required this.description,
    required this.builder,
  });

  /// Название пункта на главном экране.
  final String title;

  /// Короткое пояснение, что именно показывает экран.
  final String description;

  /// Создаёт экран демонстрации.
  final WidgetBuilder builder;
}

/// Все демонстрации в порядке добавления фич.
///
/// Новая фича = новый файл *_demo.dart + одна запись в этом списке.
final List<DemoEntry> demos = [
  DemoEntry(
    title: '1. Кнопки и переключатель',
    description: 'Готовые пиксельные элементы интерфейса: PixelButton, PixelSwitch.',
    builder: (_) => const UiDemo(),
  ),
  DemoEntry(
    title: '2. Элементы формы',
    description: 'Флажок, радиокнопка, прогресс-бар и панель с заголовком.',
    builder: (_) => const FormDemo(),
  ),
  DemoEntry(
    title: '3. Ползунок и диалог',
    description: 'Ползунок (плавный и с делениями) и диалог с затемнением.',
    builder: (_) => const SliderDialogDemo(),
  ),
  DemoEntry(
    title: '4. Вкладки и сегменты',
    description: 'Сегментные кнопки и вкладки с содержимым из обычных виджетов.',
    builder: (_) => const TabsSegmentedDemo(),
  ),
  DemoEntry(
    title: '5. Счётчик и список',
    description: 'Шаговый счётчик с удержанием и выпадающий список.',
    builder: (_) => const StepperDropdownDemo(),
  ),
  DemoEntry(
    title: '6. Рамка из атласа (9-slice)',
    description: 'Кадр атласа растягивается в рамку любого размера; плитки и подкраска.',
    builder: (_) => const NineSliceDemo(),
  ),
  DemoEntry(
    title: '7. Список',
    description: 'Прокручиваемый список с выбором строки и пиксельной полосой прокрутки.',
    builder: (_) => const ListDemo(),
  ),
  DemoEntry(
    title: '8. Подсказка',
    description: 'Плашка с текстом: долгое нажатие или наведение мыши.',
    builder: (_) => const TooltipDemo(),
  ),
  DemoEntry(
    title: '9. Поле ввода',
    description: 'Однострочное поле: шрифт атласа, курсор, выделение, фильтр символов.',
    builder: (_) => const TextFieldDemo(),
  ),
  DemoEntry(
    title: '10. Выбор времени',
    description: 'Часы, минуты и секунды: стрелки, удержание, перетаскивание, перенос разрядов.',
    builder: (_) => const TimePickerDemo(),
  ),
  DemoEntry(
    title: '11. Общая тема',
    description: 'Цвета, шрифт и масштаб всех виджетов из одного PixelTheme.',
    builder: (_) => const ThemeDemo(),
  ),
  DemoEntry(
    title: '12. Кнопки и панели из спрайтов',
    description: '9-slice рамки у кнопок и панелей, рамки в теме, panel.expand.',
    builder: (_) => const SpriteStyleDemo(),
  ),
];
