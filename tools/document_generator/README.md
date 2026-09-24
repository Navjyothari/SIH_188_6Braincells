# Synthetic Fictional Document Generator

This tool generates a batch of purely synthetic, fictional document images to serve as test fixtures for the similarity and clustering module.

**CRITICAL NOTE:** All output from this generator is entirely synthetic. There are no real names, dates, identification numbers, or photographs of real individuals. No real issuing authority symbols are used. These documents are completely safe to include in a public repository or demonstration.

## Features
- **Fictional Data**: Uses "REPUBLIC OF KELWANIA" and procedurally generated geometric avatars.
- **Embedded Watermarks**: Every image is explicitly watermarked "SPECIMEN — SYNTHETIC TEST DOCUMENT — NOT A REAL DOCUMENT".
- **Ground Truth Export**: Outputs `ground_truth.json` mapping each document to its "Kit" or independent status for evaluating clustering accuracy.
- **Controlled Variations**:
  - `Kit_A`: Injects a distinctive red, rotated stamp.
  - `Kit_B`: Injects a specific background noise/tint pattern.
  - `Kit_C`: Injects a vertical layout shift (misalignment).
  - `Independent`: Random generation, no shared artifacts.
  - `Coincidental`: Documents that share the same template and font, but no kit artifacts, to test false positive rates.
  - `Tamper`: Injects date-of-birth inconsistencies between the printed text and the MRZ.

## Requirements
- Python 3
- `Pillow` library (`pip install Pillow`)

## Usage
Run the generator from the command line:

```bash
python generate_synthetic_docs.py --count 100 --outdir output/synthetic_docs --seed 42
```

### Arguments
- `--count`: Total number of documents to generate (default: 100)
- `--outdir`: Directory to save the images and manifest (default: `output/synthetic_docs`)
- `--seed`: Random seed for reproducible datasets (default: 42)

## Outputs
- `output/synthetic_docs/DOC_XXXX.jpg`: The generated images.
- `output/synthetic_docs/ground_truth.json`: A manifest linking `doc_id` to its `group`, `tampered` status, and raw field data.
