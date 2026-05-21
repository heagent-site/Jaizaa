from fastapi import APIRouter
from pydantic import BaseModel
from db.database import get_pool
from db import queries

router = APIRouter()

class AppointmentCreate(BaseModel):
    patient_id: int
    specialty: str
    scheduled_slot: str
    reason: str = ""

@router.post("/appointments")
async def create_appointment(data: AppointmentCreate):
    pool = await get_pool()
    return await queries.create_appointment(pool, data.dict())
