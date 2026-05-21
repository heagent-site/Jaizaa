from fastapi import APIRouter
from pydantic import BaseModel
from db.database import get_pool
from db import queries

router = APIRouter()

class NotificationCreate(BaseModel):
    patient_id: int
    channel: str = "WhatsApp"
    message_text: str

@router.post("/notifications")
async def create_notification(data: NotificationCreate):
    pool = await get_pool()
    return await queries.create_notification(pool, data.dict())
