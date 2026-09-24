from abc import ABC, abstractmethod
from time import perf_counter
from uuid import uuid4
from app.schemas.models import Finding, FindingCategory, FindingStatus, OCRDocument, ExtractedRegion, RegionKind
class Detector(ABC):
    name: str; version="0.1.0"; category: FindingCategory; supported_regions: set[RegionKind]
    @abstractmethod
    def inspect(self, document: OCRDocument, region: ExtractedRegion) -> tuple[bool,str,float|None,dict]: ...
    def run(self, document: OCRDocument, regions: list[ExtractedRegion]) -> list[Finding]:
        results=[]
        for region in regions:
            if region.kind not in self.supported_regions: continue
            start=perf_counter()
            try:
                detected,description,score,explainability=self.inspect(document,region)
                if detected: results.append(Finding(finding_id=str(uuid4()),category=self.category,detector_name=self.name,detector_version=self.version,page_number=region.page_number,region_coordinates=region.coordinates,description=description,anomaly_score=score,explainability=explainability,processing_ms=round((perf_counter()-start)*1000,2)))
            except Exception as exc:
                results.append(Finding(finding_id=str(uuid4()),category=self.category,detector_name=self.name,detector_version=self.version,page_number=region.page_number,region_coordinates=region.coordinates,description="Detector could not evaluate this region.",status=FindingStatus.requires_review,detector_error=str(exc),processing_ms=round((perf_counter()-start)*1000,2)))
        return results
