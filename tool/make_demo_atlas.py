"""Генерирует демо-атлас: example/assets/atlas.png и example/assets/atlas.json.

Запуск из корня проекта: python3 tool/make_demo_atlas.py
Нужен Pillow: pip install pillow

Атлас это одна картинка, в которой рядом лежат маленькие кадры, и JSON,
который говорит, где какой кадр находится.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "example" / "assets"

WHITE = (255, 255, 255, 255)


def solid(color):
    """Квадрат 16x16 заданного цвета с белой рамкой в 1 пиксель."""
    size = 16
    img = Image.new("RGBA", (size, size), color)
    for i in range(size):
        for p in ((i, 0), (i, size - 1), (0, i), (size - 1, i)):
            img.putpixel(p, WHITE)
    return img


def from_ascii(rows, palette):
    """Картинка из текста: каждый символ это пиксель, '.' прозрачный."""
    img = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        assert len(row) == len(rows[0]), "строки разной длины"
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), palette[ch])
    return img


HEART = from_ascii(
    [
        ".##...##.",
        "#h#######",
        "#########",
        "#########",
        ".#######.",
        "..#####..",
        "...###...",
        "....#....",
    ],
    {"#": (220, 40, 60, 255), "h": (255, 170, 180, 255)},
)

# Флажок: несимметричный и без пустых полей по краям (рамка точно по
# рисунку), поэтому на нём хорошо видно поворот и отражение.
FLAG = from_ascii(
    [
        "pf.......",
        "pfff.....",
        "pfffff...",
        "pfffffff.",
        "pfffff...",
        "pfff.....",
        "pf.......",
        "p........",
        "p........",
        "p........",
        "ppp......",
    ],
    {"p": (150, 100, 50, 255), "f": (230, 60, 60, 255)},
)

SMILEY_ROWS = [
    "....####....",
    "..########..",
    ".##########.",
    ".##k####k##.",
    "###k####k###",
    "############",
    "############",
    "##k######k##",
    ".##kkkkkk##.",
    ".##########.",
    "..########..",
    "....####....",
]
SMILEY_PALETTE = {"#": (255, 220, 40, 255), "k": (30, 30, 30, 255)}
SMILEY = from_ascii(SMILEY_ROWS, SMILEY_PALETTE)

# Смайлик с закрытыми глазами (кадр для анимации моргания): верхний ряд
# глаз стираем, остаётся нижний.
SMILEY_BLINK = from_ascii(
    SMILEY_ROWS[:3] + [".##########."] + SMILEY_ROWS[4:], SMILEY_PALETTE
)

def frame9(size, rings, fill_a, fill_b):
    """Рамка для 9-slice: квадрат size x size из колец и узорчатого центра.

    rings это цвета колец снаружи внутрь, по одному пикселю на кольцо;
    сколько колец, столько и пикселей фиксированной полосы (slice). Центр
    залит шахматным узором из fill_a и fill_b. Углы срезаны (прозрачный
    пиксель), поэтому рамка скруглена. Узор и кольца повторяются с периодом
    в 1-2 пикселя, поэтому растягивание краёв и плиточный режим дают
    одинаково ровный результат на краях, а центр показывает разницу.
    """
    img = Image.new("RGBA", (size, size), fill_a)
    for y in range(size):
        for x in range(size):
            if (x + y) % 2:
                img.putpixel((x, y), fill_b)
    d = ImageDraw.Draw(img)
    for i, color in enumerate(rings):
        d.rectangle([i, i, size - 1 - i, size - 1 - i], outline=color)
    for p in ((0, 0), (size - 1, 0), (0, size - 1), (size - 1, size - 1)):
        img.putpixel(p, (0, 0, 0, 0))
    return img


# Окно: фиксированная полоса 4 пикселя (slice 4).
WINDOW = frame9(
    16,
    [(20, 20, 40, 255), (110, 130, 220, 255), (70, 90, 180, 255), (30, 35, 70, 255)],
    (44, 48, 84, 255),
    (50, 55, 94, 255),
)

# Табличка: фиксированная полоса 3 пикселя (slice 3).
PLATE = frame9(
    12,
    [(60, 30, 0, 255), (240, 170, 60, 255), (160, 100, 30, 255)],
    (96, 60, 24, 255),
    (104, 66, 28, 255),
)

# Кадры кнопки для 9-slice (slice 3): обычная, нажатая, отключённая. Центр
# залит ровным цветом, поэтому растягивание не заметно.
BTN = frame9(
    10,
    [(20, 25, 70, 255), (130, 150, 240, 255), (90, 110, 210, 255)],
    (63, 81, 181, 255),
    (63, 81, 181, 255),
)
BTN_DOWN = frame9(
    10,
    [(20, 25, 70, 255), (70, 85, 170, 255), (55, 70, 160, 255)],
    (48, 63, 150, 255),
    (48, 63, 150, 255),
)
BTN_OFF = frame9(
    10,
    [(80, 80, 80, 255), (170, 170, 170, 255), (150, 150, 150, 255)],
    (140, 140, 140, 255),
    (140, 140, 140, 255),
)

# Спрайты. Порядок кадров = порядок раскладки в атласе.
SPRITES = {
    "red": solid((220, 50, 50, 255)),
    "green": solid((50, 180, 80, 255)),
    "blue": solid((60, 100, 230, 255)),
    "yellow": solid((240, 200, 40, 255)),
    "heart": HEART,
    "smiley": SMILEY,
    "smiley_blink": SMILEY_BLINK,
    "flag": FLAG,
    "window": WINDOW,
    "plate": PLATE,
    "btn": BTN,
    "btn_down": BTN_DOWN,
    "btn_off": BTN_OFF,
}

# Анимации: последовательность кадров атласа, скорость и зацикленность.
# Кадрами могут быть любые кадры атласа, в том числе глифы шрифта.
ANIMATIONS = {
    # Квадраты по кругу, 4 кадра в секунду, бесконечно.
    "cycle": {
        "frames": ["red", "green", "blue", "yellow"],
        "fps": 4,
        "loop": True,
    },
    # Моргание: один раз, потом остаётся последний кадр.
    "blink": {
        "frames": ["smiley", "smiley_blink", "smiley"],
        "fps": 6,
        "loop": False,
    },
    # Обратный отсчёт цифрами из шрифта: 3, 2, 1, 0.
    "count": {
        "frames": ["main_0033", "main_0032", "main_0031", "main_0030"],
        "fps": 1,
        "loop": False,
    },
}

GAP = 1  # зазор между кадрами в атласе
MAX_WIDTH = 256  # ширина атласа: кадры укладываются рядами

# Шрифт, из которого рисуем глифы. Моноширинный: у всех символов одна ширина.
FONT_PATHS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    "/usr/share/fonts/dejavu/DejaVuSansMono.ttf",
    "/Library/Fonts/DejaVuSansMono.ttf",
    "C:/Windows/Fonts/consola.ttf",
]
FONT_SIZE = 10
FONT_NAME = "main"

# Какие символы кладём в шрифт: ASCII, русские буквы, Ё и ё.
CHARS = (
    [chr(c) for c in range(0x20, 0x7F)]
    + [chr(c) for c in range(0x410, 0x450)]
    + ["\u0401", "\u0451"]
)


def find_font():
    for path in FONT_PATHS:
        if Path(path).exists():
            return ImageFont.truetype(path, FONT_SIZE)
    raise SystemExit("Не найден шрифт DejaVuSansMono: поправьте FONT_PATHS")


def make_glyphs():
    """Возвращает (кадры глифов, высота строки). Глиф: белые пиксели на
    прозрачном фоне, без сглаживания (каждый пиксель либо есть, либо нет)."""
    font = find_font()
    ascent, descent = font.getmetrics()
    line_height = ascent + descent

    glyphs = {}
    for ch in CHARS:
        width = round(font.getlength(ch))
        mask = Image.new("L", (width, line_height), 0)
        draw = ImageDraw.Draw(mask)
        draw.fontmode = "1"  # без сглаживания
        draw.text((0, 0), ch, font=font, fill=255)

        img = Image.new("RGBA", (width, line_height), (0, 0, 0, 0))
        for y in range(line_height):
            for x in range(width):
                if mask.getpixel((x, y)) > 0:
                    img.putpixel((x, y), WHITE)
        glyphs[f"{FONT_NAME}_{ord(ch):04X}"] = (ch, img)
    return glyphs, line_height


def main():
    OUT_DIR.mkdir(exist_ok=True)

    glyphs, line_height = make_glyphs()

    # Все кадры вместе: спрайты, затем глифы.
    images = dict(SPRITES)
    images.update({name: img for name, (_, img) in glyphs.items()})

    # Раскладываем рядами слева направо; когда ряд заполнен, начинаем новый.
    positions = {}
    x = y = GAP
    row_height = 0
    for name, img in images.items():
        if x + img.width + GAP > MAX_WIDTH:
            x = GAP
            y += row_height + GAP
            row_height = 0
        positions[name] = (x, y)
        x += img.width + GAP
        row_height = max(row_height, img.height)
    height = y + row_height + GAP

    atlas = Image.new("RGBA", (MAX_WIDTH, height), (0, 0, 0, 0))
    frames_json = {}
    for name, img in images.items():
        px, py = positions[name]
        atlas.paste(img, (px, py))
        frames_json[name] = {"x": px, "y": py, "w": img.width, "h": img.height}

    fonts_json = {
        FONT_NAME: {
            "lineHeight": line_height,
            "spacing": 0,
            # символ -> имя кадра
            "glyphs": {ch: name for name, (ch, _) in glyphs.items()},
        }
    }

    atlas.save(OUT_DIR / "atlas.png")
    with open(OUT_DIR / "atlas.json", "w", encoding="utf-8") as f:
        json.dump(
            {
                "image": "atlas.png",
                "frames": frames_json,
                "animations": ANIMATIONS,
                "fonts": fonts_json,
            },
            f,
            indent=1,
            ensure_ascii=False,
        )
    print(f"atlas {MAX_WIDTH}x{height}, sprites: {len(SPRITES)}, "
          f"glyphs: {len(glyphs)}, line height: {line_height}")


if __name__ == "__main__":
    main()
