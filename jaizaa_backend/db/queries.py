import json

async def get_patient(pool, patient_id: int) -> dict:
    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT * FROM patients WHERE patient_id = $1", patient_id)
        if row:
            result = dict(row)
            # Convert datetime objects to strings for JSON serialization
            for k, v in result.items():
                if hasattr(v, 'isoformat'):
                    result[k] = v.isoformat()
            return result
        return None

async def get_all_patients(pool) -> list:
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """SELECT * FROM patients 
               ORDER BY CASE risk_level
                   WHEN 'CRITICAL' THEN 1
                   WHEN 'HIGH' THEN 2
                   WHEN 'MEDIUM' THEN 3
                   WHEN 'LOW' THEN 4
                   ELSE 5 END"""
        )
        results = []
        for r in rows:
            d = dict(r)
            for k, v in d.items():
                if hasattr(v, 'isoformat'):
                    d[k] = v.isoformat()
            results.append(d)
        return results

async def create_appointment(pool, data: dict) -> dict:
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """INSERT INTO appointments (patient_id, specialty, scheduled_slot, reason)
               VALUES ($1, $2, $3, $4) RETURNING *""",
            data['patient_id'], data['specialty'], data['scheduled_slot'], data.get('reason', '')
        )
        result = dict(row)
        for k, v in result.items():
            if hasattr(v, 'isoformat'):
                result[k] = v.isoformat()
        return result

async def create_alert(pool, data: dict) -> dict:
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """INSERT INTO alerts (patient_id, flagged_values, clinical_pattern, urgency_level, message)
               VALUES ($1, $2::jsonb, $3, $4, $5) RETURNING *""",
            data['patient_id'], json.dumps(data.get('flagged_values', {})), data['clinical_pattern'],
            data['urgency_level'], data['message']
        )
        result = dict(row)
        for k, v in result.items():
            if hasattr(v, 'isoformat'):
                result[k] = v.isoformat()
        return result

async def create_notification(pool, data: dict) -> dict:
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """INSERT INTO notifications (patient_id, channel, message_text)
               VALUES ($1, $2, $3) RETURNING *""",
            data['patient_id'], data['channel'], data['message_text']
        )
        result = dict(row)
        for k, v in result.items():
            if hasattr(v, 'isoformat'):
                result[k] = v.isoformat()
        return result

async def get_all_alerts(pool) -> list:
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """SELECT a.*, p.name as patient_name 
               FROM alerts a
               JOIN patients p ON a.patient_id = p.patient_id
               ORDER BY a.created_at DESC"""
        )
        results = []
        for r in rows:
            d = dict(r)
            for k, v in d.items():
                if hasattr(v, 'isoformat'):
                    d[k] = v.isoformat()
                elif k == 'flagged_values' and isinstance(v, str):
                    try:
                        d[k] = json.loads(v)
                    except Exception:
                        pass
            results.append(d)
        return results

async def get_analysis_history(pool) -> list:
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """SELECT patient_id, name, phone, risk_level, follow_up_status, care_gap,
                      last_analyzed_at, last_analysis_result
               FROM patients
               WHERE last_analysis_result IS NOT NULL
               ORDER BY last_analyzed_at DESC"""
        )
        results = []
        for r in rows:
            d = dict(r)
            for k, v in d.items():
                if hasattr(v, 'isoformat'):
                    d[k] = v.isoformat()
            results.append(d)
        return results

async def update_patient_record(pool, patient_id: int, updates: dict) -> dict:
    async with pool.acquire() as conn:
        if 'last_analysis_result' in updates:
            row = await conn.fetchrow(
                """UPDATE patients 
                   SET risk_level = $1, follow_up_status = $2, care_gap = $3, 
                       last_analyzed_at = NOW(), last_analysis_result = $4::jsonb
                   WHERE patient_id = $5 RETURNING *""",
                updates.get('risk_level', 'UNKNOWN'), updates.get('follow_up_status', 'NONE'), 
                updates.get('care_gap', 'OPEN'), json.dumps(updates.get('last_analysis_result')), patient_id
            )
        else:
            row = await conn.fetchrow(
                """UPDATE patients 
                   SET risk_level = $1, follow_up_status = $2, care_gap = $3, last_analyzed_at = NOW()
                   WHERE patient_id = $4 RETURNING *""",
                updates.get('risk_level', 'UNKNOWN'), updates.get('follow_up_status', 'NONE'), 
                updates.get('care_gap', 'OPEN'), patient_id
            )
        if row:
            result = dict(row)
            for k, v in result.items():
                if hasattr(v, 'isoformat'):
                    result[k] = v.isoformat()
            return result
        return None

