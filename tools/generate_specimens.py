"""Fixed-seed, intentionally fictional layout. No real identity data or portraits."""
import hashlib
import json
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'specimens'
SEED = 1882026


def generate():
    OUT.mkdir(exist_ok=True)
    rng = random.Random(SEED)
    font_path = ROOT / 'tools' / 'specimen-font.ttf'
    # Pin and redistribute only a licensed font; see tools/FONT-LICENSE.txt.
    font = ImageFont.truetype(str(font_path), 38)
    heading = ImageFont.truetype(str(font_path), 44)
    small = ImageFont.truetype(str(font_path), 28)
    records = []
    for index in range(5):
        number = f'TEST{rng.randrange(100000, 999999)}'
        for altered in (False, True):
            repeated = number[:-1] + str((int(number[-1]) + 1) % 10) if altered else number
            name = f'{index + 1:02d}-' + ('altered' if altered else 'clean')
            im = Image.new('RGB', (1600, 1000), '#f9f7ec')
            d = ImageDraw.Draw(im)
            d.rectangle((20, 20, 1580, 980), outline='#174e57', width=8)
            d.text((65, 55), 'SPECIMEN - NOT VALID FOR TRAVEL', font=font, fill='black')
            d.text((65, 140), 'FICTIONAL PASSPORT ALPHA', font=heading, fill='black')
            d.text((65, 230), 'ISSUER: IMAGINARY TRAINING REPUBLIC', font=small, fill='black')
            d.rectangle((65, 310, 355, 670), outline='#174e57', width=3)
            d.text((90, 430), 'NO PHOTO', font=small, fill='#174e57')
            d.text((90, 480), 'TEST ONLY', font=small, fill='#174e57')
            d.text((420, 340), f'HOLDER: SAMPLE PERSON {index + 1:02d}', font=font, fill='black')
            d.text((420, 445), f'DOCUMENT NUMBER: {number}', font=font, fill='black')
            d.text((65, 735), f'REPEATED NUMBER: {repeated}', font=font, fill='black')
            d.text((65, 880), 'SYNTHETIC TRAINING DATA - NO LEGAL OR IDENTITY VALUE', font=small, fill='#9c2525')
            path = OUT / f'{name}.png'
            im.save(path)
            text = '\n'.join(['SPECIMEN - NOT VALID FOR TRAVEL', 'FICTIONAL PASSPORT ALPHA',
                'ISSUER: IMAGINARY TRAINING REPUBLIC', f'HOLDER: SAMPLE PERSON {index + 1:02d}',
                f'DOCUMENT NUMBER: {number}', f'REPEATED NUMBER: {repeated}',
                'SYNTHETIC TRAINING DATA - NO LEGAL OR IDENTITY VALUE'])
            (OUT / f'{name}.txt').write_text(text + '\n', encoding='utf-8')
            records.append({'id': name, 'image': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'expectedFields': {'documentNumber': number, 'repeatedNumber': repeated},
                'expectedState': 'REVIEW_REQUIRED' if altered else 'NO_INCONSISTENCY_DETECTED',
                'alterations': [{'field': 'repeatedNumber', 'before': number, 'after': repeated,
                    'boxXYXY': [65, 735, 1100, 800]}] if altered else []})
    (OUT / 'manifest.json').write_text(json.dumps({'seed': SEED, 'synthetic': True,
        'layout': 'FICTIONAL PASSPORT ALPHA', 'imageSize': [1600, 1000],
        'fontSha256': hashlib.sha256(font_path.read_bytes()).hexdigest(),
        'reviewStatus': 'PENDING_INDEPENDENT_HUMAN_CHECK', 'specimens': records}, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    generate()
