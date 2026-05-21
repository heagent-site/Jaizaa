from fastapi import APIRouter
from db.database import get_pool
from db import queries

router = APIRouter()

@router.get("/history")
async def get_history():
    pool = await get_pool()
    return await queries.get_analysis_history(pool)
