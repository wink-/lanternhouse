from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
BUILDINGS_DIR = ROOT / "assets/sprites/town/buildings"
SHOPS_DIR = ROOT / "assets/sprites/town/shops/buildings"

def make_transparent_and_crop(sub_img, bg_color):
    rgba = sub_img.convert("RGBA")
    data = rgba.getdata()
    new_data = []
    
    # Check if the pixel matches the bg_color (with tolerance <= 2)
    br, bg, bb = bg_color
    for item in data:
        r, g, b, a = item
        if abs(r - br) <= 2 and abs(g - bg) <= 2 and abs(b - bb) <= 2:
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append(item)
    rgba.putdata(new_data)
    
    # Get bbox of non-transparent pixels
    bbox = rgba.getbbox()
    if bbox:
        return rgba.crop(bbox)
    return rgba

def split_sheet_2x2(name, targets):
    path = BUILDINGS_DIR / f"{name}.png"
    if not path.exists():
        print(f"File not found: {path}")
        return
    img = Image.open(path).convert("RGBA")
    bg_color = img.getpixel((0, 0))[:3]
    w, h = img.size
    qw, qh = w // 2, h // 2
    
    for row in range(2):
        for col in range(2):
            target_path = targets[row][col]
            if not target_path:
                continue
            sub = img.crop((col * qw, row * qh, (col + 1) * qw, (row + 1) * qh))
            cropped = make_transparent_and_crop(sub, bg_color)
            target_path.parent.mkdir(parents=True, exist_ok=True)
            cropped.save(target_path)
            print(f"Saved {target_path.relative_to(ROOT)} (size: {cropped.size})")

def split_sheet_3col(name, targets):
    path = BUILDINGS_DIR / f"{name}.png"
    if not path.exists():
        print(f"File not found: {path}")
        return
    img = Image.open(path).convert("RGBA")
    bg_color = img.getpixel((0, 0))[:3]
    w, h = img.size
    
    col_boundaries = [0, 106, 213, 320]
    for i in range(3):
        target_path = targets[i]
        if not target_path:
            continue
        sub = img.crop((col_boundaries[i], 0, col_boundaries[i+1], h))
        cropped = make_transparent_and_crop(sub, bg_color)
        target_path.parent.mkdir(parents=True, exist_ok=True)
        cropped.save(target_path)
        print(f"Saved {target_path.relative_to(ROOT)} (size: {cropped.size})")

def main():
    # 1. Shop split sheet
    shop_targets = [
        [SHOPS_DIR / "armor_shop.png", SHOPS_DIR / "weapon_shop.png"],
        [BUILDINGS_DIR / "tavern.png", BUILDINGS_DIR / "workshop.png"]
    ]
    split_sheet_2x2("runtime_shop_split_sheet", shop_targets)
    
    # 2. Public split sheet
    public_targets = [
        SHOPS_DIR / "inn.png",
        SHOPS_DIR / "chapel.png",
        BUILDINGS_DIR / "elder_hall.png"
    ]
    split_sheet_3col("runtime_public_split_sheet", public_targets)
    
    # 3. Home split sheet
    home_targets = [
        [BUILDINGS_DIR / "small_house.png", BUILDINGS_DIR / "large_house.png"],
        [BUILDINGS_DIR / "house_timber.png", BUILDINGS_DIR / "house_mossy.png"]
    ]
    split_sheet_2x2("runtime_home_split_sheet", home_targets)

if __name__ == "__main__":
    main()
