from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from db.database import get_pool
from db import queries

router = APIRouter()

class PatientCreate(BaseModel):
    name: str
    phone: str = ""

class PatientUpdate(BaseModel):
    risk_level: str
    follow_up_status: str
    care_gap: str

@router.post("/patients")
async def create_patient(data: PatientCreate):
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "INSERT INTO patients (name, phone) VALUES ($1, $2) RETURNING *",
            data.name, data.phone
        )
        result = dict(row)
        for k, v in result.items():
            if hasattr(v, 'isoformat'):
                result[k] = v.isoformat()
        return result

@router.get("/patients")
async def get_patients():
    pool = await get_pool()
    return await queries.get_all_patients(pool)

@router.get("/patients/{patient_id}")
async def get_patient(patient_id: int):
    pool = await get_pool()
    patient = await queries.get_patient(pool, patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient

@router.patch("/patients/{patient_id}")
async def update_patient(patient_id: int, updates: PatientUpdate):
    pool = await get_pool()
    result = await queries.update_patient_record(pool, patient_id, updates.dict())
    if not result:
        raise HTTPException(status_code=404, detail="Patient not found")
    return result
