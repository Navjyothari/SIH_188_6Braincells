from fastapi import FastAPI
from app.api.routes import router
app=FastAPI(title="SIH Tampering Analysis",version="0.1.0",description="Post-OCR, review-oriented tampering findings service; no risk engine.")
app.include_router(router)
@app.get("/health")
def health(): return {"status":"ok","service":"tampering-analysis"}
