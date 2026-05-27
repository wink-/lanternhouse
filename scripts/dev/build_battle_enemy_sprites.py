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


def crab() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((24, 36, 72, 44), fill=SHADOW)
    draw.ellipse((34, 18, 62, 36), fill=OUTLINE)
    draw.ellipse((37, 20, 59, 34), fill=(197, 80, 55, 255))
    draw.line((34, 27, 22, 21), fill=OUTLINE, width=2)
    draw.line((62, 27, 74, 21), fill=OUTLINE, width=2)
    draw.arc((15, 15, 27, 27), 30, 320, fill=(225, 108, 69, 255), width=3)
    draw.arc((69, 15, 81, 27), 220, 150, fill=(225, 108, 69, 255), width=3)
    draw.point((43, 24), fill=OUTLINE)
    draw.point((53, 24), fill=OUTLINE)
    return img


def bat() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((29, 35, 67, 43), fill=SHADOW)
    draw.polygon([(47, 14), (17, 8), (27, 28), (38, 23)], fill=OUTLINE)
    draw.polygon([(49, 14), (79, 8), (69, 28), (58, 23)], fill=OUTLINE)
    draw.polygon([(47, 17), (23, 12), (30, 25), (40, 22)], fill=(74, 54, 88, 255))
    draw.polygon([(49, 17), (73, 12), (66, 25), (56, 22)], fill=(74, 54, 88, 255))
    draw.ellipse((38, 13, 58, 32), fill=OUTLINE)
    draw.ellipse((41, 16, 55, 30), fill=(91, 67, 109, 255))
    draw.point((44, 22), fill=(232, 211, 92, 255))
    draw.point((52, 22), fill=(232, 211, 92, 255))
    return img


def bandit() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((28, 37, 68, 44), fill=SHADOW)
    draw.rectangle((39, 14, 57, 30), fill=OUTLINE)
    draw.rectangle((41, 16, 55, 29), fill=(198, 137, 94, 255))
    draw.rectangle((40, 18, 56, 23), fill=(41, 38, 38, 255))
    draw.point((44, 21), fill=(236, 222, 160, 255))
    draw.point((52, 21), fill=(236, 222, 160, 255))
    draw.polygon([(32, 29), (64, 29), (68, 41), (28, 41)], fill=OUTLINE)
    draw.polygon([(35, 30), (61, 30), (64, 39), (32, 39)], fill=(92, 86, 71, 255))
    draw.line((63, 26, 75, 16), fill=(198, 205, 196, 255), width=2)
    return img


def serpent() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((21, 37, 75, 44), fill=SHADOW)
    draw.arc((24, 18, 72, 48), 185, 352, fill=OUTLINE, width=8)
    draw.arc((27, 20, 69, 44), 185, 352, fill=(197, 155, 73, 255), width=5)
    draw.ellipse((57, 12, 75, 28), fill=OUTLINE)
    draw.ellipse((59, 14, 73, 26), fill=(215, 177, 84, 255))
    draw.point((68, 19), fill=OUTLINE)
    draw.line((72, 22, 80, 20), fill=(191, 52, 55, 255))
    return img


def mossling() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((25, 36, 71, 44), fill=SHADOW)
    draw.ellipse((31, 17, 65, 39), fill=OUTLINE)
    draw.ellipse((34, 20, 62, 37), fill=(76, 133, 66, 255))
    for x, y in [(36, 18), (43, 15), (51, 17), (59, 20)]:
        draw.ellipse((x - 2, y - 2, x + 3, y + 3), fill=(111, 177, 82, 255))
    draw.point((42, 27), fill=OUTLINE)
    draw.point((54, 27), fill=OUTLINE)
    draw.rectangle((39, 35, 45, 42), fill=OUTLINE)
    draw.rectangle((52, 35, 58, 42), fill=OUTLINE)
    return img


def jelly() -> Image.Image:
    img, draw = new_img()
    draw.ellipse((28, 36, 68, 44), fill=SHADOW)
    draw.ellipse((31, 12, 65, 32), fill=OUTLINE)
    draw.ellipse((34, 15, 62, 30), fill=(82, 173, 201, 210))
    for x in [36, 43, 50, 57]:
        draw.line((x, 29, x - 3, 40), fill=(68, 142, 173, 230), width=2)
    draw.point((43, 22), fill=OUTLINE)
    draw.point((53, 22), fill=OUTLINE)
    draw.point((39, 17), fill=(166, 231, 241, 255))
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
    save("crab", crab())
    save("bat", bat())
    save("bandit", bandit())
    save("serpent", serpent())
    save("mossling", mossling())
    save("jelly", jelly())


if __name__ == "__main__":
    main()
