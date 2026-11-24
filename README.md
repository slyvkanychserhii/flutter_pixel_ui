# flutter_pixel_ui

Пиксельные элементы интерфейса для Flutter: кнопка, переключатель, флажок,
радиокнопка, индикатор прогресса, панель, ползунок, диалог, вкладки, сегменты,
счётчик, выпадающий список, 9-slice рамка, список, подсказка, поле ввода (с
масками), выбор времени и общая тема.

Построено на [flutter_pixel_canvas](../flutter_pixel_canvas): каждый элемент
это пиксельный холст из атласа, поэтому выглядит одинаково при любом масштабе.

## Подключение

Требуется Flutter 3.27 или новее. Пакет зависит от flutter_pixel_canvas:

```yaml
dependencies:
  flutter_pixel_canvas:
    git: https://github.com/<ваш-аккаунт>/flutter_pixel_canvas.git
  flutter_pixel_ui:
    git: https://github.com/<ваш-аккаунт>/flutter_pixel_ui.git
```

Для локальной разработки (репозитории рядом друг с другом) используйте `path`:

```yaml
dependencies:
  flutter_pixel_canvas:
    path: ../flutter_pixel_canvas
  flutter_pixel_ui:
    path: ../flutter_pixel_ui
```

В самом flutter_pixel_ui зависимость от холста сейчас указана через `path:
../flutter_pixel_canvas`. После того как холст окажется на GitHub, замените её
в `pubspec.yaml` на `git:` (закомментированный вариант там уже есть).

## Как взять только нужное

**Способ 1. Импорт одного виджета.** У каждого виджета своя библиотека. Код
остальных виджетов в приложение не попадёт: Dart при сборке отбрасывает
неиспользуемое.

```dart
import 'package:flutter_pixel_ui/button.dart';
import 'package:flutter_pixel_ui/switch.dart';
import 'package:flutter_pixel_ui/stepper.dart';
import 'package:flutter_pixel_ui/time_picker.dart';
import 'package:flutter_pixel_ui/theme.dart';   // общая тема, если нужна
```

Всё сразу: `import 'package:flutter_pixel_ui/flutter_pixel_ui.dart';`

**Способ 2. Скопировать файлы в свой проект.** Скрипт берёт выбранные виджеты и
всё, что им нужно, и кладёт в одну папку:

```
python3 tool/extract.py --list
python3 tool/extract.py --to ../my_app/lib/pixel_ui button switch stepper time_picker
```

Получится 7 файлов и `pixel_ui.dart` (ворота с экспортом). В проекте всё равно
нужен пакет flutter_pixel_canvas и атлас в assets. В коде:
`import 'pixel_ui/pixel_ui.dart';`

Что нужно каждому виджету (файлы из `lib/src`, без префикса `pixel_`; сам файл
виджета первый в списке):

| Виджет | Файлов | Состав |
|---|---|---|
| button | 4 | button, colors, nine_slice, theme |
| checkbox | 3 | checkbox, colors, theme |
| dialog | 5 | dialog, panel, colors, nine_slice, theme |
| dropdown | 3 | dropdown, colors, theme |
| list | 3 | list, colors, theme |
| mask | 1 | mask |
| nine_slice | 2 | nine_slice, theme |
| panel | 4 | panel, colors, nine_slice, theme |
| progress_bar | 3 | progress_bar, colors, theme |
| radio | 3 | radio, colors, theme |
| segmented | 3 | segmented, colors, theme |
| slider | 3 | slider, colors, theme |
| stepper | 3 | stepper, colors, theme |
| switch | 3 | switch, colors, theme |
| tabs | 3 | tabs, colors, theme |
| text_field | 4 | text_field, colors, mask, theme |
| theme | 1 | theme |
| time_picker | 3 | time_picker, colors, theme |
| tooltip | 3 | tooltip, colors, theme |

Тема (`theme`) и цвета (`colors`) маленькие и общие почти для всех. Кнопка и
панель дополнительно берут `nine_slice` для рамок из спрайтов.

## Пример и тесты

Пример приложения лежит в `example/`: главный экран со списком демонстраций,
каждый виджет на своём экране.

```
cd example
flutter create --platforms=android,ios,macos,web .   # один раз: папки платформ
flutter pub get
flutter run
cd ..
flutter test          # тесты пакета
```

Демо-атлас (`example/assets/atlas.png` и `atlas.json`) создаёт скрипт
`python3 tool/make_demo_atlas.py` (нужен Pillow). Для своего приложения нужен
свой атлас: у виджетов есть кадры по именам (см. раздел про атлас в
flutter_pixel_canvas).

## Виджеты

`PixelButton` и `PixelSwitch` это обычные виджеты, их можно класть в любую
раскладку рядом с другими виджетами. Внутри они используют `PixelCanvas`
и сами считают свой размер: целое число пикселей сцены, умноженное на `scale`.

```dart
PixelButton(
  atlas: atlas,
  label: 'Нажми',
  scale: 3,
  color: const Color(0xFF2E7D32),   // рамка и нажатая заливка считаются из него
  onPressed: () => ...,             // null: кнопка отключена (серая)
)

PixelSwitch(
  value: sound,
  onChanged: (v) => setState(() => sound = v),   // null: отключён
)
```

У кнопки под рамкой тень в один пиксель; при нажатии кнопка опускается
на пиксель и закрывает тень (размер виджета при этом не меняется).
Переключатель плоский. Кнопке нужны атлас и шрифт для подписи (`font`, по умолчанию `'main'`),
остальные элементы (кроме заголовка панели) рисуются только примитивами.

```dart
PixelCheckbox(value: sound, onChanged: (v) => setState(() => sound = v))

// Группа: выбрана та радиокнопка, у которой value == groupValue.
PixelRadio<int>(value: 0, groupValue: level, onChanged: (v) => setState(() => level = v))

PixelProgressBar(value: 0.4, width: 60)               // сплошная полоса
PixelProgressBar(value: 0.4, width: 60, segments: 10) // шкала из 10 блоков

PixelPanel(atlas: atlas, title: 'Настройки', child: Column(...))

// Ползунок: значение хранит приложение; divisions даёт деления.
PixelSlider(value: volume, width: 80, onChanged: (v) => setState(() => volume = v))
PixelSlider(value: stars, min: 1, max: 5, divisions: 4, onChanged: ...)

// Диалог поверх экрана; результат задаёт Navigator.pop(context, значение).
final ok = await showPixelDialog<bool>(
  context: context,
  builder: (ctx) => PixelDialog(
    atlas: atlas,
    title: 'Выход',
    content: const Text('Выйти без сохранения?'),
    actions: [
      PixelButton(atlas: atlas, label: 'Нет', onPressed: () => Navigator.pop(ctx, false)),
      PixelButton(atlas: atlas, label: 'Да', onPressed: () => Navigator.pop(ctx, true)),
    ],
  ),
);

// Сегментные кнопки: карта «значение → подпись», выбрано одно.
PixelSegmented<int>(atlas: atlas, segments: const {0: 'Лёгкая', 1: 'Средняя'},
    value: level, onChanged: (v) => setState(() => level = v))

// Вкладки: выбор хранит приложение, содержимое подставляется по номеру.
PixelTabs(atlas: atlas, tabs: const ['Игра', 'Звук'], index: tab,
    onChanged: (i) => setState(() => tab = i), child: content)

// Шаговый счётчик: «−», число, «+»; при удержании значение меняется само,
// а перетаскивание по числу вправо/влево увеличивает/уменьшает его.
PixelStepper(atlas: atlas, value: count, min: 0, max: 10,
    onChanged: (v) => setState(() => count = v))

// Выпадающий список: меню открывается поверх экрана (через Overlay).
PixelDropdown<String>(atlas: atlas, items: const {'ru': 'Русский', 'en': 'English'},
    value: lang, onChanged: (v) => setState(() => lang = v))

// Растягиваемая рамка из кадра атласа (9-slice): углы целы, края тянутся.
PixelNineSlice(atlas: atlas, frame: 'window', slice: const EdgeInsets.all(4),
    scale: 3, child: Text('Окно'))

// Прокручиваемый список строк с выбором (высоту задаёт родитель).
SizedBox(height: 160, child: PixelList(atlas: atlas, labels: names,
    selectedIndex: index, onSelected: (i) => setState(() => index = i)))

// Подсказка: долгое нажатие или наведение мыши.
PixelTooltip(atlas: atlas, message: 'Сохранить файл', child: saveButton)

// Кнопки и панели из спрайтов: рамка 9-slice из кадров атласа вместо
// примитивов. slice это неизменяемые полосы кадра в его пикселях. У кнопки
// можно дать кадры нажатого и отключённого состояния (иначе подкраска).
// Рамку задают параметром frame или один раз в теме (buttonFrame, panelFrame).
const button = PixelFrameStyle(frame: 'btn', slice: EdgeInsets.all(3),
    pressedFrame: 'btn_down', disabledFrame: 'btn_off');
PixelButton(atlas: atlas, label: 'Играть', frame: button, onPressed: play)
PixelPanel(atlas: atlas, title: 'Окно', expand: true,   // expand: на всё место
    frame: const PixelFrameStyle(frame: 'window', slice: EdgeInsets.all(4)),
    child: content)

// Общая тема: шрифт, масштаб и цвета в одном месте. Виджеты берут значение
// так: параметр виджета, затем тема, затем собственное умолчание. Тему ставят
// над MaterialApp, чтобы её видели диалоги и меню (они живут в Overlay).
PixelThemeScope(
  theme: const PixelTheme(primary: Color(0xFFE91E63), scale: 3),
  child: MaterialApp(...),
)

// Однострочное поле ввода: текст шрифтом атласа, ввод через EditableText.
PixelTextField(atlas: atlas, width: 100, hint: 'Имя', onChanged: (t) => ...)
```

`PixelNineSlice` берёт кадр атласа и растягивает его до любого размера;
`slice` это ширина неизменяемых полос кадра (left, top, right, bottom в
пикселях кадра). С `tile: true` края и центр повторяются плитками, что
нужно для рамок с узором. Размер определяет родитель (как у `PixelTabs`);
без ограничения размер берётся по содержимому. Углы всегда рисуются в
полном размере, поэтому если область меньше суммы полос, рамка не
рисуется.

`PixelList` занимает всё место родителя и требует ограниченную высоту.
Прокручивается как обычный ListView; справа пиксельная полоса (ползунок
тянется, дорожка отвечает на нажатия). По окончании прокрутки смещение
округляется до целого пикселя сцены.

`PixelTooltip` оборачивает любой виджет: долгое нажатие (палец) или пауза
мыши над виджетом показывают плашку над ним (под ним, если сверху нет
места). Плашка не перехватывает нажатия; текст одна строка.

`PixelTextField`: невидимый `EditableText` под полем принимает ввод
(системная и аппаратная клавиатура, стрелки, копирование и вставка), а
рамку, текст, курсор и выделение рисуют холсты шрифтом из атласа. Принимаются
только символы, которые есть в шрифте. Нажатие ставит курсор,
перетаскивание выделяет, двойное нажатие выделяет слово. Однострочное;
ширина `width` в пикселях сцены или вся ширина родителя.

```dart
PixelTextField(atlas: atlas, obscureText: true, hint: 'Пароль')  // пароль, символы «*»
PixelTextField(atlas: atlas, mask: '+7 (###) ###-##-##')         // ввод по шаблону
```

`PixelTimePicker` выбирает длительность (`Duration`): три колонки
«часы:минуты:секунды» со стрелками вверх и вниз. Значение меняется
нажатием на стрелку, удержанием стрелки (непрерывно) и вертикальным
перетаскиванием по числу; разряды переносятся как на часах, а значение
ограничено диапазоном от нуля до `maxHours:59:59`. С `showSeconds: false`
колонки секунд нет. С `wrapAround: true` (будильник, время суток) каждая колонка
идёт по кругу независимо: после 00 вниз часы показывают 23, минуты 59, без
переноса в соседнюю колонку.

```dart
PixelTimePicker(atlas: atlas, value: duration,
    onChanged: (d) => setState(() => duration = d))
```

В шаблоне `#` цифра, `A` буква, `*` любой символ, остальные знаки
вставляются сами (`PixelMaskFormatter` годится и для обычного поля
Flutter). В поле пароля символ «*» должен быть в шрифте, а двойное нажатие
выделяет весь текст. Не поддерживаются: несколько строк, лупа и меню
выделения.


Ряд ярлыков `PixelTabs` должен помещаться по ширине (перенос не
поддерживается). Выбранный ярлык срастается с панелью.

Ползунок без `onChanged` отключён. Нажатие мимо диалога закрывает его с
результатом `null` (отключается через `barrierDismissible: false`).

Подписи рядом с элементами это обычные виджеты (`Row` с `Text`). Размер
`PixelPanel` определяется содержимым плюс `padding`; панель рисует рамку
холстом на заднем плане, а содержимое остаётся обычными виджетами и
получает нажатия как обычно.

## Устройство

| Файл (lib/src) | Что делает |
|---|---|
| pixel_theme.dart | общая тема: PixelTheme, PixelThemeScope, PixelFrameStyle (рамка из спрайтов) |
| pixel_colors.dart | pixelLighten, pixelDarken |
| pixel_button.dart, pixel_switch.dart, pixel_checkbox.dart, pixel_radio.dart, pixel_progress_bar.dart, pixel_panel.dart, pixel_slider.dart, pixel_dialog.dart, pixel_segmented.dart, pixel_tabs.dart, pixel_stepper.dart, pixel_dropdown.dart, pixel_nine_slice.dart, pixel_list.dart, pixel_tooltip.dart, pixel_text_field.dart, pixel_mask.dart, pixel_time_picker.dart | элементы интерфейса |

У каждого виджета публичный класс это тонкая обёртка, которая берёт значения
из темы, а работает внутренний класс `_PixelXxxImpl` в том же файле.

