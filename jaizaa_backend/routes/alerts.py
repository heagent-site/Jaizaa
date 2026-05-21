from fastapi import APIRouter
from pydantic import BaseModel
from db.database import get_pool
from db import queries

router = APIRouter()

class AlertCreate(BaseModel):
    patient_id: int
    flagged_values: dict
    clinical_pattern: str
    urgency_level: str
    message: str

@router.post("/alerts")
async def create_alert(data: AlertCreate):
    pool = await get_pool()
    return await queries.create_alert(pool, data.dict())

@router.get("/alerts")
async def get_alerts():
    pool = await get_pool()
    return await queries.get_all_alerts(pool)

