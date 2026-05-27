from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites" / "battle" / "party"
SIZE = (64, 48)


CLASSES = {
    "fighter": {"main": (176, 54, 44), "trim": (220, 164, 82), "hat": (92, 80, 80), "weapon": "sword"},
    "thief": {"main": (55, 144, 83), "trim": (207, 188, 111), "hat": (45, 74, 54), "weapon": "dagger"},
    "blackbelt": {"main": (132, 92, 52), "trim": (235, 216, 164), "hat": (69, 54, 40), "weapon": "fist"},
    "redmage": {"main": (196, 60, 55), "trim": (238, 222, 157), "hat": (152, 42, 55), "weapon": "staff"},
    "whitemage": {"main": (226, 225, 207), "trim": (101, 180, 125), "hat": (180, 60, 66), "weapon": "staff"},
    "blackmage": {"main": (104, 65, 150), "trim": (222, 184, 82), "hat": (48, 39, 86), "weapon": "staff"},
}


OUTLINE = (31, 27, 28, 255)
SKIN = (205, 145, 104, 255)
SHADOW = (19, 17, 20, 80)


def draw_sprite(cfg: dict) -> Image.Image:
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    main = (*cfg["main"], 255)
    trim = (*cfg["trim"], 255)
    hat = (*cfg["hat"], 255)
    draw.ellipse((18, 39, 48, 45), fill=SHADOW)
    draw.rectangle((27, 15, 38, 28), fill=SKIN)
    draw.rectangle((25, 11, 40, 20), fill=OUTLINE)
    draw.rectangle((27, 12, 38, 19), fill=SKIN)
    draw.point((30, 16), fill=OUTLINE)
    draw.point((36, 16), fill=OUTLINE)
    draw.polygon([(24, 21), (42, 21), (47, 39), (19, 39)], fill=OUTLINE)
    draw.polygon([(26, 22), (40, 22), (44, 38), (22, 38)], fill=main)
    draw.line((27, 25, 41, 25), fill=trim, width=2)
    draw.line((32, 22, 32, 38), fill=(max(cfg["main"][0] - 35, 0), max(cfg["main"][1] - 35, 0), max(cfg["main"][2] - 35, 0), 255))
    draw.rectangle((24, 38, 30, 42), fill=OUTLINE)
    draw.rectangle((36, 38, 42, 42), fill=OUTLINE)
    draw.rectangle((25, 38, 29, 41), fill=main)
    draw.rectangle((37, 38, 41, 41), fill=main)
    draw.polygon([(24, 11), (33, 3), (42, 11)], fill=OUTLINE)
    draw.polygon([(27, 10), (33, 5), (39, 10)], fill=hat)
    if cfg["weapon"] == "sword":
        draw.line((45, 17, 55, 7), fill=(205, 214, 212, 255), width=2)
        draw.line((43, 19, 48, 24), fill=trim, width=2)
    elif cfg["weapon"] == "dagger":
        draw.line((45, 24, 53, 20), fill=(205, 214, 212, 255), width=2)
        draw.point((44, 25), fill=trim)
    elif cfg["weapon"] == "fist":
        draw.ellipse((43, 26, 50, 33), fill=SKIN)
        draw.point((47, 29), fill=OUTLINE)
    else:
        draw.line((45, 12, 50, 40), fill=(94, 62, 38, 255), width=2)
        draw.ellipse((43, 8, 49, 14), fill=trim)
    return img


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, cfg in CLASSES.items():
        path = OUT_DIR / f"{name}.png"
        draw_sprite(cfg).save(path)
        print(f"Wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
