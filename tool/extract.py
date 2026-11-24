#!/usr/bin/env python3
"""Копирует выбранные виджеты из flutter_pixel_ui в свой проект.

Нужно, если не хочется подключать весь пакет, а нужны, например, только
кнопки, переключатели, счётчики и выбор времени. Скрипт берёт файлы
выбранных виджетов и всё, что им нужно (тема, цвета, 9-slice...), кладёт
их в одну папку и создаёт файл-ворота `pixel_ui.dart`, который их
экспортирует.

Примеры:

    python3 tool/extract.py --list
    python3 tool/extract.py --to ../my_app/lib/pixel_ui button switch stepper time_picker

После копирования в pubspec.yaml своего проекта нужен пакет холста:

    flutter_pixel_canvas:
      git: https://github.com/<вы>/flutter_pixel_canvas.git

и атлас с кадрами/шрифтом в assets. В коде:

    import 'pixel_ui/pixel_ui.dart';

Скрипт ничего не удаляет и не перезаписывает без флага --force.
"""
import argparse
import re
import shutil
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "lib" / "src"
IMPORT = re.compile(r"^import '(pixel_\w+\.dart)';", re.M)


def widgets():
    """Имена виджетов: файлы pixel_<имя>.dart, кроме служебных."""
    skip = {"colors"}
    return sorted(
        p.stem[len("pixel_"):]
        for p in SRC.glob("pixel_*.dart")
        if p.stem[len("pixel_"):] not in skip
    )


def needs(name, seen=None):
    """Файлы (с расширением), нужные виджету, включая его самого."""
    seen = seen if seen is not None else []
    fname = f"pixel_{name}.dart"
    if fname in seen:
        return seen
    seen.append(fname)
    text = (SRC / fname).read_text(encoding="utf-8")
    for dep in IMPORT.findall(text):
        needs(dep[len("pixel_"):-len(".dart")], seen)
    return seen


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("names", nargs="*", help="виджеты: button, switch, stepper, time_picker, ...")
    ap.add_argument("--to", help="папка назначения (создаётся)")
    ap.add_argument("--list", action="store_true", help="показать виджеты и их зависимости")
    ap.add_argument("--force", action="store_true", help="перезаписывать существующие файлы")
    args = ap.parse_args()

    known = widgets()
    if args.list:
        for n in known:
            deps = [d[len("pixel_"):-len(".dart")] for d in needs(n)[1:]]
            print(f"{n:14} + {', '.join(deps) if deps else '-'}")
        return 0

    if not args.names or not args.to:
        ap.print_usage()
        print("Укажите виджеты и --to <папка>. Список: --list")
        return 2
    bad = [n for n in args.names if n not in known]
    if bad:
        print(f"Неизвестные виджеты: {', '.join(bad)}. Доступны: {', '.join(known)}")
        return 2

    files = []
    for n in args.names:
        for f in needs(n):
            if f not in files:
                files.append(f)

    dest = Path(args.to)
    dest.mkdir(parents=True, exist_ok=True)
    clash = [f for f in files if (dest / f).exists() and not args.force]
    if clash:
        print("Уже существуют (используйте --force):", ", ".join(clash))
        return 1
    for f in files:
        shutil.copy(SRC / f, dest / f)

    # Файл-ворота: экспортирует только запрошенные виджеты.
    gate = ["// Создано tool/extract.py из flutter_pixel_ui.", "library;", ""]
    for n in args.names:
        gate.append(f"export 'pixel_{n}.dart';")
    # Тема нужна почти всем: даём её наружу, если она скопирована.
    if "pixel_theme.dart" in files and "theme" not in args.names:
        gate.append("export 'pixel_theme.dart';")
    (dest / "pixel_ui.dart").write_text("\n".join(gate) + "\n", encoding="utf-8")

    print(f"Скопировано файлов: {len(files)} в {dest}")
    for f in files:
        print("  ", f)
    print("\nДобавьте в pubspec.yaml пакет flutter_pixel_canvas и атлас в assets.")
    print("Импорт: import 'pixel_ui/pixel_ui.dart';")
    return 0


if __name__ == "__main__":
    sys.exit(main())
