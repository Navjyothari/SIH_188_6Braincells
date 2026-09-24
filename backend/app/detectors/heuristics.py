from app.detectors.base import Detector
from app.schemas.models import FindingCategory, RegionKind
class PhotographHeuristic(Detector):
    name="photograph-metadata-heuristic"; category=FindingCategory.photograph; supported_regions={RegionKind.photograph}
    def inspect(self,document,region):
        hit=any(x in (region.label or "").lower() for x in ("edited","mismatch","anomaly"))
        return hit,"Layout metadata marks the photograph region as visually inconsistent.",.55,{"signal":"layout_label","limitation":"No pixel-forensic model is used."}
class TextHeuristic(Detector):
    name="text-ocr-heuristic"; category=FindingCategory.text; supported_regions={RegionKind.text}
    def inspect(self,document,region):
        label=(region.label or "").lower(); hit="[illegible]" in label or "overwritten" in label or "�" in label
        return hit,"OCR text contains an illegibility or overwrite indicator; inspect source image.",.45,{"signal":"ocr_indicator","limitation":"This does not establish alteration."}
class StampSignatureHeuristic(Detector):
    name="stamp-signature-reference-heuristic"; category=FindingCategory.stamp_signature; supported_regions={RegionKind.stamp,RegionKind.signature}
    def inspect(self,document,region):
        hit=any(x in (region.label or "").lower() for x in ("mismatch","unknown"))
        return hit,"Region metadata indicates a reference/template mismatch.",.5,{"signal":"reference_label","limitation":"Presence does not establish authenticity."}
class DamageHeuristic(Detector):
    name="physical-damage-layout-heuristic"; category=FindingCategory.damage; supported_regions={RegionKind.other}
    def inspect(self,document,region):
        hit=any(x in (region.label or "").lower() for x in ("tear","missing","damage","crease"))
        return hit,"Layout metadata identifies possible physical damage, separate from intentional tampering.",.5,{"signal":"layout_label","classification":"physical_damage"}
