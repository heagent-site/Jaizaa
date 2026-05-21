def report(before: dict, action_plan: dict, execution: dict, logs: list) -> dict:
    plan_list = action_plan.get("action_plan", [])
    record_update = next((a for a in plan_list if a["action_type"] == "app_record_update"), None)

    if record_update:
        after_risk = record_update["updates"].get("risk_level", "HIGH")
    else:
        after_risk = before.get("risk_level", "UNKNOWN")

    return {
        "before": {
            "patient_id": before.get("patient_id"),
            "name": before.get("name", "Unknown"),
            "phone": before.get("phone", ""),
            "risk_level": before.get("risk_level", "UNKNOWN"),
            "follow_up_status": before.get("follow_up_status", "NONE"),
            "care_gap": before.get("care_gap", "OPEN"),
            "doctor_awareness": before.get("doctor_awareness", "UNAWARE")
        },
        "after": {
            "patient_id": before.get("patient_id"),
            "name": before.get("name", "Unknown"),
            "phone": before.get("phone", ""),
            "risk_level": after_risk,
            "follow_up_status": "SCHEDULED" if record_update else before.get("follow_up_status"),
            "care_gap": "CLOSED" if record_update else before.get("care_gap"),
            "doctor_awareness": "ALERTED"
        },
        "execution_results": execution,
        "agent_trace": logs
    }
