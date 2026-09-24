# Backend

## Architecture

`OCRDocument` → `RegionExtractor` → modular `Detector`s → deterministic `validate` → versioned `FindingsMessage` → `FindingsConsumer`.

The stable public contracts are in `app/schemas/models.py`. OCR integration maps its output to `OCRDocument`, providing a document ID, page image references/dimensions, text blocks, layout regions, boxes, optional confidences, and arbitrary OCR metadata. `app/messaging/publisher.py` serializes messages to JSON and supplies a no-op publisher that can later be replaced by a queue adapter without changing the message contract.

## Install and run

```powershell
cd backend
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Visit `http://127.0.0.1:8000/docs`. Run tests with `pytest` from `backend`.

## API

- `POST /api/v1/documents/analyze` — accepts an `OCRDocument`, performs extraction/detection/validation, and returns a `FindingsMessage`.
- `GET /api/v1/documents/{document_id}/findings` — retrieves the in-memory generated message.
- `GET /health` — service health.

Submit [`fixtures/sample_ocr.json`](fixtures/sample_ocr.json) to the analyze endpoint. It is deliberately marked synthetic. The output contains `message_id`, `schema_version`, timestamp, findings, validation results, warnings/errors, and metadata; it is JSON serializable via `FindingsMessage.model_dump_json()`.

## Detectors and limitations

The four MVP detectors are metadata/OCR heuristics for photographs, text, stamps/signatures, and physical damage. They do not load images or make forensic claims, and scores are explicitly heuristic anomaly indicators—not validated confidence. Replace each implementation in `app/detectors/heuristics.py` with evaluated models while keeping the `Detector` interface and `Finding` message stable. Storage is deliberately in-memory and the downstream publisher is no-op for this MVP.
