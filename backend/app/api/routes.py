from fastapi import APIRouter, HTTPException
from app.schemas.models import OCRDocument
from app.services.pipeline import TamperingPipeline
router=APIRouter(prefix="/api/v1"); pipeline=TamperingPipeline(); messages={}
@router.post("/documents/analyze")
def analyze(document:OCRDocument):
    message=pipeline.analyze(document); messages[document.document_id]=message; return message
@router.get("/documents/{document_id}/findings")
def findings(document_id:str):
    if document_id not in messages: raise HTTPException(404,"Findings not found")
    return messages[document_id]
