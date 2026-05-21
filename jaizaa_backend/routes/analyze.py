from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from ai_agents import pipeline

router = APIRouter()

@router.post("/analyze")
async def analyze_report(
    patient_id: str = Form(...),
    file: UploadFile = File(...)
):
    try:
        file_bytes = await file.read()
        result = await pipeline.run(file_bytes, file.filename, patient_id)
        return result
    except HTTPException as he:
        raise he
    except Exception as e:
        import traceback
        traceback.print_exc()
        err_msg = str(e)
        if "402" in err_msg or "credit" in err_msg.lower() or "afford" in err_msg.lower() or "payment required" in err_msg.lower():
            raise HTTPException(
                status_code=402,
                detail="Analysis failed: insufficient API credits. Please try again."
            )
        raise HTTPException(status_code=500, detail={"error": "PipelineError", "message": str(e)})
