from datetime import datetime, timezone
from uuid import uuid4
from app.detectors.heuristics import PhotographHeuristic,TextHeuristic,StampSignatureHeuristic,DamageHeuristic
from app.messaging.publisher import FindingsConsumer, NoopPublisher
from app.schemas.models import OCRDocument, FindingsMessage
from app.services.regions import RegionExtractor
from app.validation.rules import validate
class TamperingPipeline:
    def __init__(self,publisher:FindingsConsumer|None=None,enabled_detectors:set[str]|None=None):
        self.extractor=RegionExtractor(); all_detectors=[PhotographHeuristic(),TextHeuristic(),StampSignatureHeuristic(),DamageHeuristic()]
        self.detectors=[d for d in all_detectors if enabled_detectors is None or d.name in enabled_detectors]; self.publisher=publisher or NoopPublisher()
    def analyze(self,document:OCRDocument)->FindingsMessage:
        regions=self.extractor.extract(document); findings=[]
        for detector in self.detectors: findings.extend(detector.run(document,regions))
        sizes={p.page_number:(p.image_width,p.image_height) for p in document.pages}; findings,validation_results=validate(findings,sizes)
        errors=[f.detector_error for f in findings if f.detector_error]
        message=FindingsMessage(message_id=str(uuid4()),document_id=document.document_id,processing_status="completed_with_errors" if errors else "completed",timestamp=datetime.now(timezone.utc).isoformat(),findings=findings,validation_results=validation_results,warnings=["Synthetic MVP heuristics are anomaly prompts, not proof of tampering, authenticity, or fraud."],errors=errors,metadata={"page_count":len(document.pages),"ocr_metadata":document.ocr_metadata,"detectors":[d.name for d in self.detectors]})
        self.publisher.publish(message); return message
