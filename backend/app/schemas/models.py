"""Stable OCR input and downstream findings contracts."""
from __future__ import annotations
from enum import Enum
from typing import Any
from pydantic import BaseModel, Field, model_validator

class RegionKind(str, Enum):
    text="text"; photograph="photograph"; signature="signature"; stamp="stamp"; other="other"
class FindingCategory(str, Enum):
    photograph="photograph_tampering"; text="text_modification"; stamp_signature="stamp_signature_inconsistency"; damage="physical_document_damage"
class FindingStatus(str, Enum):
    detected="detected"; flagged="flagged"; requires_review="requires_review"; dismissed="dismissed"
class Coordinates(BaseModel):
    x: float=Field(ge=0); y: float=Field(ge=0); width: float=Field(gt=0); height: float=Field(gt=0)
    @property
    def right(self)->float: return self.x+self.width
    @property
    def bottom(self)->float: return self.y+self.height
class TextBlock(BaseModel):
    text: str; bounding_box: Coordinates; page_number: int=Field(ge=1); confidence: float|None=Field(default=None,ge=0,le=1)
class LayoutRegion(BaseModel):
    kind: RegionKind; bounding_box: Coordinates; page_number: int=Field(ge=1); label: str|None=None; confidence: float|None=Field(default=None,ge=0,le=1); reference_id: str|None=None
class OCRPage(BaseModel):
    page_number: int=Field(ge=1); image_reference: str|None=None; image_width: int|None=Field(default=None,gt=0); image_height: int|None=Field(default=None,gt=0); text_blocks: list[TextBlock]=Field(default_factory=list); regions: list[LayoutRegion]=Field(default_factory=list)
class OCRDocument(BaseModel):
    document_id: str=Field(min_length=1,max_length=200); image_reference: str|None=None; extracted_text: str=""; pages: list[OCRPage]=Field(min_length=1); ocr_metadata: dict[str,Any]=Field(default_factory=dict)
    @model_validator(mode="after")
    def unique_pages(self):
        if len({p.page_number for p in self.pages}) != len(self.pages): raise ValueError("page_number values must be unique")
        return self
class ExtractedRegion(BaseModel):
    region_id: str; document_id: str; page_number: int; kind: RegionKind; coordinates: Coordinates; label: str|None=None; source: str
class Finding(BaseModel):
    finding_id: str; category: FindingCategory; detector_name: str; detector_version: str; page_number: int; region_coordinates: Coordinates; description: str; evidence_references: list[str]=Field(default_factory=list); anomaly_score: float|None=Field(default=None,ge=0,le=1); confidence: float|None=Field(default=None,ge=0,le=1); status: FindingStatus=FindingStatus.detected; explainability: dict[str,Any]=Field(default_factory=dict); processing_ms: float|None=None; detector_error: str|None=None
class ValidationResult(BaseModel):
    finding_id: str; status: FindingStatus; applied_rules: list[str]=Field(default_factory=list); rationale: list[str]=Field(default_factory=list)
class FindingsMessage(BaseModel):
    message_id: str; schema_version: str="1.0"; document_id: str; processing_status: str; timestamp: str; findings: list[Finding]; validation_results: list[ValidationResult]; warnings: list[str]=Field(default_factory=list); errors: list[str]=Field(default_factory=list); metadata: dict[str,Any]=Field(default_factory=dict)
