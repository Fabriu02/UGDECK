from PIL import Image
import os

base = 'ug-deck/assets/sprites_personajes'
FRAME_COLUMNS = 5

for d in sorted(os.listdir(base)):
    folder = os.path.join(base, d)
    if not os.path.isdir(folder):
        continue
    for f in sorted(os.listdir(folder)):
        if not f.endswith('.png') or '.import' in f:
            continue
        path = os.path.join(folder, f)
        img = Image.open(path)
        w, h = img.size
        frame_w = w // FRAME_COLUMNS
        remainder = w % FRAME_COLUMNS
        status = "OK" if remainder == 0 else f"BAD (remainder={remainder}px)"
        print(f"{d}/{f:40s} {w:5d}x{h:<5d} frame={frame_w}x{h}  {status}")
