import json
from pathlib import Path
from fastapi.testclient import TestClient
from app.main import app
from app.schemas.models import OCRDocument, Coordinates
from app.services.pipeline import TamperingPipeline
from app.services.regions import RegionExtractor
client=TestClient(app); fixture=json.loads((Path(__file__).parents[1]/"fixtures"/"sample_ocr.json").read_text())
def test_schema_rejects_duplicate_pages():
    bad=fixture|{"pages":[fixture["pages"][0],fixture["pages"][0]]}
    try: OCRDocument.model_validate(bad); assert False
    except ValueError: assert True
def test_regions_preserve_coordinates():
    regions=RegionExtractor().extract(OCRDocument.model_validate(fixture)); assert any(r.coordinates==Coordinates(x=700,y=100,width=180,height=220) for r in regions)
def test_detectors_validation_and_message_serialization():
    message=TamperingPipeline().analyze(OCRDocument.model_validate(fixture)); assert len(message.findings)==4; assert all(f.status.value=="flagged" for f in message.findings); assert OCRDocument.model_validate_json(OCRDocument.model_validate(fixture).model_dump_json()).document_id==fixture["document_id"]; assert "schema_version" in message.model_dump_json()
def test_api_and_invalid_input():
    assert client.get("/health").status_code==200
    response=client.post("/api/v1/documents/analyze",json=fixture); assert response.status_code==200
    assert client.get("/api/v1/documents/synthetic-doc-001/findings").status_code==200
    assert client.post("/api/v1/documents/analyze",json={}).status_code==422
