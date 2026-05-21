from db.database import get_pool
from db import queries

async def execute(action_plan: dict, patient_id: int) -> dict:
    results = {}
    pool = await get_pool()
    plan = action_plan.get("action_plan", [])

    # Action 1: Appointment
    appt = next((a for a in plan if a.get("action_type") == "appointment"), None)
    if appt:
        try:
            row = await queries.create_appointment(pool, {
                "patient_id": patient_id,
                "specialty": appt.get("specialty", "General"),
                "scheduled_slot": appt.get("scheduled_slot", "TBD"),
                "reason": appt.get("reason", "")
            })
            results["appointment"] = {"status": "ok", "id": row.get("id")}
        except Exception as e:
            results["appointment"] = {"status": "failed", "error": str(e)}

    # Action 2: Alert
    alert = next((a for a in plan if a.get("action_type") == "alert"), None)
    if alert:
        try:
            row = await queries.create_alert(pool, {
                "patient_id": patient_id,
                "flagged_values": alert.get("flagged_values", {}),
                "clinical_pattern": alert.get("clinical_pattern", "Unknown"),
                "urgency_level": alert.get("urgency_level", "HIGH"),
                "message": alert.get("message", "")
            })
            results["alert"] = {"status": "ok", "id": row.get("id")}
        except Exception as e:
            results["alert"] = {"status": "failed", "error": str(e)}

    # Action 3: Notification
    notif = next((a for a in plan if a.get("action_type") == "notification"), None)
    if notif:
        try:
            row = await queries.create_notification(pool, {
                "patient_id": patient_id,
                "channel": "WhatsApp",
                "message_text": notif.get("message_text", "")
            })
            results["notification"] = {"status": "ok", "id": row.get("id")}
        except Exception as e:
            results["notification"] = {"status": "failed", "error": str(e)}

    # Action 4: App Record Update
    record = next((a for a in plan if a.get("action_type") == "app_record_update"), None)
    if record:
        try:
            updates = record.get("updates", {})
            row = await queries.update_patient_record(pool, patient_id, updates)
            results["app_record_update"] = {"status": "ok"}
        except Exception as e:
            results["app_record_update"] = {"status": "failed", "error": str(e)}

    return results
