import os
import json
import random
import argparse
from datetime import datetime, timedelta
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# --- CONFIGURATION ---
COUNTRY_NAME = "REPUBLIC OF KELWANIA"
WATERMARK_TEXT = "SPECIMEN — SYNTHETIC TEST SPECIMEN — NOT A REAL DOCUMENT"
CARD_WIDTH, CARD_HEIGHT = 800, 520

FIRST_NAMES = ["Zorblax", "Kelwan", "Lumina", "Vortigan", "Marlex", "Thalira", "Garrick", "Elara", "Tarik", "Sylas", "Nyx", "Oberon"]
LAST_NAMES = ["Smithson", "Vane", "Stirling", "Thorne", "Korvax", "Finch", "Drakos", "Windrider", "Cobalt", "Ironclad"]

# Real-world border security modeling: Source & Destination Checkpoints
SOURCE_PORTS = [
    "Sylas Port (North Sector)",
    "Vortigan Border Crossing",
    "Zorba Transit Hub",
    "Kelwan Outpost",
    "Thalira Maritime Pier"
]

DESTINATION_PORTS = [
    "Delhi ICP (Terminal 3)",
    "Attari Land Checkpoint",
    "Mumbai Sea Gate 2",
    "Kolkata Port Entry",
    "Chennai Maritime Wing"
]

# High-threat transit corridors often targeted by syndicates
SYNDICATE_CORRIDORS = {
    "Kit_A": ("Sylas Port (North Sector)", "Delhi ICP (Terminal 3)"),
    "Kit_B": ("Vortigan Border Crossing", "Attari Land Checkpoint"),
    "Kit_C": ("Zorba Transit Hub", "Mumbai Sea Gate 2"),
}

def generate_random_date(start_year, end_year):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    random_date = start + timedelta(days=random.randint(0, (end - start).days))
    return random_date.strftime("%d-%m-%Y"), random_date.strftime("%y%m%d")

def calculate_check_digit(data: str) -> int:
    """ICAO 9303 7-3-1 weight check digit calculation."""
    weights = [7, 3, 1]
    total = 0
    for idx, char in enumerate(data):
        if char.isdigit():
            val = int(char)
        elif char.isalpha():
            val = ord(char.upper()) - 55
        else:
            val = 0
        total += val * weights[idx % 3]
    return total % 10

def generate_mrz(name, dob_mrz, doc_num, expiry_mrz, corrupt_checksum=False):
    """Generates standard 2-line ICAO Doc 9303 TD3 MRZ."""
    parts = name.split(" ")
    surname = parts[0]
    given = parts[1] if len(parts) > 1 else "X"
    
    line1 = f"P<KLW{surname}<<{given}".ljust(44, '<')
    
    doc_num_clean = doc_num[:9].ljust(9, '<')
    doc_check = calculate_check_digit(doc_num_clean)
    if corrupt_checksum:
        doc_check = (doc_check + 3) % 10  # Deliberate checksum tamper
        
    dob_check = calculate_check_digit(dob_mrz)
    exp_check = calculate_check_digit(expiry_mrz)
    
    composite_data = f"{doc_num_clean}{doc_check}{dob_mrz}{dob_check}{expiry_mrz}{exp_check}"
    composite_check = calculate_check_digit(composite_data)
    
    line2 = f"{doc_num_clean}{doc_check}KLW{dob_mrz}{dob_check}M{expiry_mrz}{exp_check}<<<<<<<<<<<<<{composite_check}"
    line2 = line2.ljust(44, '<')[:44]
    
    return f"{line1}\n{line2}", line1, line2

def draw_avatar(draw, x, y, width, height, seed):
    random.seed(seed)
    bg_color = (random.randint(210, 245), random.randint(210, 245), random.randint(210, 245))
    draw.rectangle([x, y, x+width, y+height], fill=bg_color, outline="#1E293B", width=2)
    
    head_color = (random.randint(70, 160), random.randint(70, 160), random.randint(70, 160))
    body_color = (random.randint(50, 120), random.randint(50, 120), random.randint(80, 150))
    
    # Head
    head_radius = width * 0.26
    head_cx, head_cy = x + width/2, y + height * 0.36
    draw.ellipse([head_cx - head_radius, head_cy - head_radius, head_cx + head_radius, head_cy + head_radius], fill=head_color)
    
    # Body
    body_w = width * 0.72
    body_h = height * 0.42
    body_cx, body_cy = x + width/2, y + height * 0.82
    draw.ellipse([body_cx - body_w/2, body_cy - body_h, body_cx + body_w/2, body_cy + body_h], fill=body_color)
    
    # Clip frame
    draw.rectangle([x, y+height, x+width, y+height+20], fill="white")
    draw.rectangle([x, y, x+width, y+height], outline="#1E293B", width=2)
    random.seed()

def draw_stamp(img, x, y, kit_type):
    stamp = Image.new('RGBA', (160, 160), (255, 255, 255, 0))
    d = ImageDraw.Draw(stamp)
    
    if kit_type == "Kit_A":
        # Syndicate Kit A: Cloned red fraudulent border clearance seal
        d.ellipse([10, 10, 150, 150], outline=(220, 38, 38, 200), width=4)
        d.ellipse([22, 22, 138, 138], outline=(220, 38, 38, 180), width=2)
        d.text((38, 55), "BORDER EXEMPT", fill=(220, 38, 38, 210))
        d.text((44, 75), "* KIT-A-SEAL *", fill=(220, 38, 38, 190))
        stamp = stamp.rotate(18, expand=1)
    elif kit_type == "Kit_B":
        # Syndicate Kit B: Blue diplomatic forged cachet
        d.ellipse([10, 10, 150, 150], outline=(37, 99, 235, 200), width=3)
        d.polygon([(80, 20), (140, 130), (20, 130)], outline=(37, 99, 235, 190), width=2)
        d.text((45, 80), "CONSULAR-B", fill=(37, 99, 235, 210))
        stamp = stamp.rotate(-12, expand=1)
    elif kit_type == "Kit_C":
        # Syndicate Kit C: Purple transit visa forgery
        d.rectangle([15, 25, 145, 125], outline=(147, 51, 234, 200), width=3)
        d.text((30, 48), "TRANSIT PERMIT", fill=(147, 51, 234, 210))
        d.text((40, 72), "[ AUTH SEC-C ]", fill=(147, 51, 234, 180))
        stamp = stamp.rotate(6, expand=1)
    else:
        # Standard checkpoint entry stamp
        d.ellipse([15, 15, 145, 145], outline=(16, 185, 129, 160), width=2)
        d.text((48, 68), "IMMIGRATION", fill=(16, 185, 129, 170))
        
    img.paste(stamp, (x, y), stamp)

def generate_document(doc_id, group, is_tampered=False):
    # Determine identity
    fname = random.choice(FIRST_NAMES)
    lname = random.choice(LAST_NAMES)
    full_name = f"{lname} {fname}"
    
    # Dates
    actual_dob_disp, dob_mrz = generate_random_date(1968, 2002)
    issue_disp, issue_mrz = generate_random_date(2018, 2023)
    expiry_disp, expiry_mrz = generate_random_date(2026, 2034)
    doc_num = f"{random.randint(10000000, 99999999)}"
    
    # Assign Source and Destination Ports
    if group in SYNDICATE_CORRIDORS and random.random() < 0.75:
        # Syndicate funneling through their established high-risk route
        source_port, destination_port = SYNDICATE_CORRIDORS[group]
    else:
        source_port = random.choice(SOURCE_PORTS)
        destination_port = random.choice(DESTINATION_PORTS)
        
    corridor = f"{source_port} -> {destination_port}"
    
    # Base background
    bg_color = (248, 250, 252)
    if group == "Kit_B":
        bg_color = (235, 243, 252)  # subtle tint artifact
    elif group == "Kit_C":
        bg_color = (248, 245, 255)
        
    img = Image.new('RGB', (CARD_WIDTH, CARD_HEIGHT), color=bg_color)
    draw = ImageDraw.Draw(img)
    
    # Layout shifts
    offset_y = 12 if group == "Kit_C" else 0
    
    # Header Banner
    draw.rectangle([0, 0, CARD_WIDTH, 56], fill=(30, 41, 59))
    draw.text((24, 18), f"{COUNTRY_NAME}  |  OFFICIAL IDENTITY PASSPORT SPECIMEN", fill="#38BDF8")
    
    # Photo Avatar
    photo_seed = hash(doc_id) & 0xFFFFFFFF
    draw_avatar(draw, 32, 75 + offset_y, 145, 185, seed=photo_seed)
    
    # Tampering logic
    tamper_types = []
    print_dob = actual_dob_disp
    corrupt_mrz_checksum = False
    
    if is_tampered:
        tamper_mode = random.choice(["DOB_ALTERATION", "CHECKSUM_SPOOF", "EXPIRED_OVERRIDE", "STAMP_CLONED"])
        if tamper_mode == "DOB_ALTERATION":
            # Visual printed DOB changed (e.g. to appear younger/older), MRZ left un-updated
            print_dob = "01-01-2005"
            tamper_types.append("DOB_MISMATCH")
        elif tamper_mode == "CHECKSUM_SPOOF":
            corrupt_mrz_checksum = True
            tamper_types.append("MRZ_CHECKSUM_FAILURE")
        elif tamper_mode == "EXPIRED_OVERRIDE":
            expiry_disp = "15-11-2021"  # Visually altered or expired
            tamper_types.append("EXPIRY_TAMPER")
        elif tamper_mode == "STAMP_CLONED":
            tamper_types.append("CLONED_SYNDICATE_SEAL")
            
        if group.startswith("Kit"):
            tamper_types.append(f"FORGERY_RING_{group}")
    
    # Text Fields (Visual Inspection Zone)
    text_x = 205
    text_y = 75 + offset_y
    lh = 26
    
    draw.text((text_x, text_y), f"Full Name: {full_name.upper()}", fill="#0F172A")
    draw.text((text_x, text_y + lh*1), f"Document No: {doc_num}", fill="#0F172A")
    draw.text((text_x, text_y + lh*2), f"Date of Birth: {print_dob}", fill="#0F172A")
    draw.text((text_x, text_y + lh*3), f"Date of Issue: {issue_disp}", fill="#0F172A")
    draw.text((text_x, text_y + lh*4), f"Date of Expiry: {expiry_disp}", fill="#0F172A")
    
    # Routing / Checkpoint Fields (Source & Destination)
    draw.line([(text_x, text_y + lh*5.2), (text_x + 380, text_y + lh*5.2)], fill="#CBD5E1", width=1)
    draw.text((text_x, text_y + lh*5.5), f"Origin Port: {source_port}", fill="#1E293B")
    draw.text((text_x, text_y + lh*6.5), f"Port of Entry: {destination_port}", fill="#1E293B")
    
    # Stamp placement
    if group in ["Kit_A", "Kit_B", "Kit_C"]:
        draw_stamp(img, 620, 80 + offset_y, group)
    elif random.random() < 0.35:
        draw_stamp(img, 620, 80, "Standard")
        
    # MRZ Generation
    mrz_text, mrz_line1, mrz_line2 = generate_mrz(full_name, dob_mrz, doc_num, expiry_mrz, corrupt_checksum=corrupt_mrz_checksum)
    
    # MRZ Zone Box
    draw.rectangle([0, CARD_HEIGHT - 95, CARD_WIDTH, CARD_HEIGHT], fill=(226, 232, 240))
    draw.line([(0, CARD_HEIGHT - 95), (CARD_WIDTH, CARD_HEIGHT - 95)], fill="#94A3B8", width=2)
    draw.text((24, CARD_HEIGHT - 75), mrz_line1, fill="#0F172A")
    draw.text((24, CARD_HEIGHT - 45), mrz_line2, fill="#0F172A")
    
    # Watermark overlay
    watermark = Image.new('RGBA', img.size, (255, 255, 255, 0))
    w_draw = ImageDraw.Draw(watermark)
    w_draw.text((60, 220), WATERMARK_TEXT, fill=(220, 38, 38, 55))
    watermark = watermark.rotate(10, expand=0)
    img.paste(watermark, (0, 0), watermark)
    
    if group == "Kit_B":
        img = img.filter(ImageFilter.GaussianBlur(radius=0.4))
        
    return img, {
        "doc_id": doc_id,
        "name": full_name,
        "doc_num": doc_num,
        "dob_visual": print_dob,
        "dob_mrz": dob_mrz,
        "issue_date": issue_disp,
        "expiry_date": expiry_disp,
        "source_port": source_port,
        "destination_port": destination_port,
        "corridor": corridor,
        "group": group,
        "tampered": is_tampered,
        "tamper_types": tamper_types,
        "mrz_line1": mrz_line1,
        "mrz_line2": mrz_line2
    }

def main():
    parser = argparse.ArgumentParser(description="Synthetic Document Generator with Corridor & Tampering Modeling")
    parser.add_argument('--count', type=int, default=150, help='Total documents to generate')
    parser.add_argument('--outdir', type=str, default='tools/document_generator/output/synthetic_docs', help='Output directory')
    parser.add_argument('--seed', type=int, default=42, help='Random seed')
    args = parser.parse_args()
    
    random.seed(args.seed)
    os.makedirs(args.outdir, exist_ok=True)
    
    manifest = []
    groups = ["Kit_A", "Kit_B", "Kit_C", "Independent", "Independent", "Coincidental"]
    
    print(f"Generating {args.count} synthetic documents in '{args.outdir}'...")
    for i in range(args.count):
        doc_id = f"DOC_{i:04d}"
        group = random.choice(groups)
        
        # Syndicates have higher tampering frequency
        tamper_prob = 0.45 if group.startswith("Kit") else 0.08
        is_tampered = random.random() < tamper_prob
        
        img, meta = generate_document(doc_id, group, is_tampered)
        out_path = os.path.join(args.outdir, f"{doc_id}.jpg")
        img.save(out_path, "JPEG", quality=85)
        
        meta["image_path"] = out_path
        manifest.append(meta)
        
    manifest_path = os.path.join(args.outdir, "ground_truth.json")
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=4)
        
    tampered_count = sum(1 for d in manifest if d["tampered"])
    print(f"Done! Generated {args.count} documents ({tampered_count} tampered).")
    print(f"Manifest written to: {manifest_path}")

if __name__ == "__main__":
    main()
