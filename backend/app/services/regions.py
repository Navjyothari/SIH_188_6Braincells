from uuid import uuid4
from app.schemas.models import OCRDocument, ExtractedRegion, RegionKind
class RegionExtractor:
    """OCR-implementation-independent relevant-region extractor."""
    def extract(self, document: OCRDocument) -> list[ExtractedRegion]:
        output=[]
        for page in document.pages:
            text_boxes=set()
            for item in page.regions:
                output.append(ExtractedRegion(region_id=str(uuid4()),document_id=document.document_id,page_number=page.page_number,kind=item.kind,coordinates=item.bounding_box,label=item.label,source="layout"))
                if item.kind is RegionKind.text: text_boxes.add((item.bounding_box.x,item.bounding_box.y,item.bounding_box.width,item.bounding_box.height))
            for block in page.text_blocks:
                key=(block.bounding_box.x,block.bounding_box.y,block.bounding_box.width,block.bounding_box.height)
                if key not in text_boxes: output.append(ExtractedRegion(region_id=str(uuid4()),document_id=document.document_id,page_number=page.page_number,kind=RegionKind.text,coordinates=block.bounding_box,label=block.text[:160],source="ocr_text_block"))
        return output
