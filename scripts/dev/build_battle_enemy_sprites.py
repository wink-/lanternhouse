from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites" / "battle" / "enemies"
SIZE = (96, 48)


OUTLINE = (27, 23, 27, 255)
SHADOW = (12, 10, 14, 85)


def new_img() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(name: str, img: Image.Image) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    img.save(OUT_DIR / f"{name}.png")
    print(f"Wrote {(OUT_DIR / f'{name}.png').relative_to(ROOT)}")


def slime() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((26, 33, 70, 43), fill=SHADOW)
    draw.ellipse((29, 13, 67, 40), fill=OUTLINE)
    draw.ellipse((32, 16, 64, 38), fill=(64, 177, 78, 255))
    draw.point((42, 26), fill=OUTLINE)
    draw.point((55, 26), fill=OUTLINE)
    draw.arc((43, 27, 55, 35), 10, 170, fill=OUTLINE)
    draw.point((39, 18), fill=(134, 224, 139, 255))
    return img


def imp() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((24, 35, 72, 44), fill=SHADOW)
    draw.polygon([(31, 20), (24, 8), (38, 17)], fill=OUTLINE)
    draw.polygon([(65, 20), (72, 8), (58, 17)], fill=OUTLINE)
    draw.ellipse((31, 12, 65, 39), fill=OUTLINE)
    draw.ellipse((34, 15, 62, 37), fill=(139, 82, 177, 255))
    draw.point((42, 25), fill=(238, 226, 122, 255))
    draw.point((55, 25), fill=(238, 226, 122, 255))
    draw.line((36, 36, 27, 42), fill=OUTLINE, width=2)
    draw.line((60, 36, 69, 42), fill=OUTLINE, width=2)
    return img


def wolf() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((22, 35, 74, 44), fill=SHADOW)
    draw.polygon([(25, 27), (38, 14), (67, 20), (75, 31), (65, 38), (36, 38)], fill=OUTLINE)
    draw.polygon([(30, 27), (40, 17), (64, 22), (70, 30), (62, 35), (38, 35)], fill=(130, 113, 89, 255))
    draw.polygon([(40, 17), (42, 8), (49, 18)], fill=OUTLINE)
    draw.polygon([(56, 20), (62, 10), (64, 23)], fill=OUTLINE)
    draw.point((65, 27), fill=(230, 220, 150, 255))
    draw.point((72, 30), fill=OUTLINE)
    return img


def ghoul() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((27, 36, 69, 44), fill=SHADOW)
    draw.polygon([(36, 13), (60, 13), (66, 38), (30, 38)], fill=OUTLINE)
    draw.polygon([(38, 16), (58, 16), (62, 36), (34, 36)], fill=(119, 178, 119, 255))
    draw.point((43, 24), fill=OUTLINE)
    draw.point((54, 24), fill=OUTLINE)
    draw.line((39, 37, 33, 43), fill=OUTLINE, width=2)
    draw.line((58, 37, 65, 43), fill=OUTLINE, width=2)
    return img


def skeleton() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((28, 36, 68, 44), fill=SHADOW)
    bone = (226, 218, 198, 255)
    draw.ellipse((38, 8, 58, 26), fill=OUTLINE)
    draw.ellipse((40, 10, 56, 24), fill=bone)
    draw.point((44, 17), fill=OUTLINE)
    draw.point((52, 17), fill=OUTLINE)
    draw.rectangle((43, 27, 53, 39), fill=OUTLINE)
    draw.rectangle((45, 28, 51, 37), fill=bone)
    draw.line((43, 30, 31, 38), fill=bone, width=2)
    draw.line((53, 30, 65, 38), fill=bone, width=2)
    return img


def ogre() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((21, 36, 75, 44), fill=SHADOW)
    draw.ellipse((30, 10, 66, 39), fill=OUTLINE)
    draw.ellipse((33, 13, 63, 37), fill=(103, 69, 38, 255))
    draw.rectangle((30, 29, 66, 40), fill=OUTLINE)
    draw.rectangle((34, 29, 62, 37), fill=(91, 55, 31, 255))
    draw.point((42, 23), fill=(238, 221, 138, 255))
    draw.point((55, 23), fill=(238, 221, 138, 255))
    draw.line((67, 18, 79, 8), fill=(102, 78, 56, 255), width=4)
    return img


def wraith() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((28, 37, 68, 45), fill=SHADOW)
    draw.polygon([(48, 7), (66, 22), (60, 42), (49, 35), (38, 43), (31, 22)], fill=OUTLINE)
    draw.polygon([(48, 10), (62, 23), (57, 38), (49, 31), (39, 39), (35, 23)], fill=(73, 48, 102, 230))
    draw.point((43, 23), fill=(190, 154, 235, 255))
    draw.point((53, 23), fill=(190, 154, 235, 255))
    return img


def drake() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((20, 36, 76, 44), fill=SHADOW)
    draw.polygon([(25, 30), (39, 15), (63, 18), (75, 30), (62, 39), (38, 38)], fill=OUTLINE)
    draw.polygon([(31, 30), (41, 18), (61, 21), (69, 30), (59, 36), (40, 35)], fill=(187, 58, 45, 255))
    draw.polygon([(37, 18), (34, 8), (45, 16)], fill=OUTLINE)
    draw.polygon([(59, 21), (66, 11), (66, 25)], fill=OUTLINE)
    draw.point((62, 27), fill=(247, 210, 89, 255))
    return img


def golem() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((22, 37, 74, 45), fill=SHADOW)
    draw.rectangle((32, 14, 64, 39), fill=OUTLINE)
    draw.rectangle((35, 17, 61, 36), fill=(128, 128, 128, 255))
    draw.rectangle((39, 8, 57, 18), fill=OUTLINE)
    draw.rectangle((41, 10, 55, 17), fill=(154, 154, 148, 255))
    draw.point((43, 22), fill=(238, 211, 93, 255))
    draw.point((54, 22), fill=(238, 211, 93, 255))
    draw.rectangle((24, 25, 33, 35), fill=OUTLINE)
    draw.rectangle((63, 25, 72, 35), fill=OUTLINE)
    return img


def main() -> None:
    save("slime", slime())
    save("imp", imp())
    save("wolf", wolf())
    save("ghoul", ghoul())
    save("skeleton", skeleton())
    save("ogre", ogre())
    save("wraith", wraith())
    save("drake", drake())
    save("golem", golem())


if __name__ == "__main__":
    main()
