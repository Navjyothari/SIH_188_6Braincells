"""Small deterministic color-corner JPEG vectors; no user photos are used."""
from pathlib import Path
from PIL import Image, ImageDraw

out = Path(__file__).resolve().parents[1] / 'test' / 'fixtures' / 'orientation'
out.mkdir(parents=True, exist_ok=True)
upright = Image.new('RGB', (120, 80))
draw = ImageDraw.Draw(upright)
for box, color in [((0, 0, 59, 39), (255, 0, 0)), ((60, 0, 119, 39), (0, 255, 0)),
                   ((0, 40, 59, 79), (0, 0, 255)), ((60, 40, 119, 79), (255, 255, 0))]:
    draw.rectangle(box, fill=color)
for rotation, orientation in [(0, 1), (90, 6), (180, 3), (270, 8)]:
    # Pillow rotates counterclockwise; CameraX's correction rotates clockwise.
    raw = upright.rotate(rotation, expand=True)
    raw.save(out / f'raw-{rotation}.jpg', quality=100, subsampling=0)
    exif = Image.Exif()
    exif[274] = orientation
    raw.save(out / f'exif-{rotation}.jpg', quality=100, subsampling=0, exif=exif)
