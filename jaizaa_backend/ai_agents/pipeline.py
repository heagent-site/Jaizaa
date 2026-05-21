import os
import tempfile
from db.database import get_pool
from db import queries
from . import agent1_reader, agent2_analyzer, agent3_risk, agent4_planner, agent5_executor, agent6_reporter

async def run(file_bytes: bytes, filename: str, patient_id: str) -> dict:
    logs = []

    # Determine suffix — support pdf, png, jpg/jpeg images
    lower_name = filename.lower()
    if lower_name.endswith(".pdf"):
        suffix = ".pdf"
        file_type = "pdf"
    elif lower_name.endswith(".png"):
        suffix = ".png"
        file_type = "image"
    elif lower_name.endswith(".jpg") or lower_name.endswith(".jpeg"):
        suffix = ".jpg"
        file_type = "image"
    else:
        suffix = ".pdf"
        file_type = "pdf"

    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix, mode='wb') as f:
        f.write(file_bytes)
        f.flush()
        os.fsync(f.fileno())
        tmp_path = f.name
    print(f"[OK] Temp file written: {tmp_path} ({os.path.getsize(tmp_path)} bytes)")

    pid = int(patient_id)

    try:
        # --- ADDED: Pipeline start log ---
        print(f"[START] Starting analysis pipeline for patient_id={pid}, file={filename}")

        try:
            # Fetch before state directly from DB
            pool = await get_pool()
            async with pool.acquire() as conn:
                before_row = await conn.fetchrow("SELECT * FROM patients WHERE patient_id = $1", pid)
            before = dict(before_row) if before_row else {"name": "Unknown", "phone": "", "risk_level": "UNKNOWN"}

            # Agent 1
            values = await agent1_reader.run(tmp_path, file_type)
            # --- ADDED: Fail-fast check ---
            if "error" in values or not values.get("values"):
                raise Exception(f"Agent 1 failed: {values.get('error', 'No values extracted')}")
            val_count = len(values.get("values", {}))
            logs.append({"agent": "Document Reader", "status": "DONE",
                         "key_output": f"Extracted {val_count} lab values via {values.get('extraction_method')}"})

            # Agent 2
            findings = await agent2_analyzer.run(values)
            # Empty findings is valid (all-normal report) — only fail on actual error key
            if "error" in findings:
                raise Exception(f"Agent 2 failed: {findings['error']}")
            find_count = len(findings.get("findings", []))
            status_msg = f"{find_count} clinical patterns detected" if find_count > 0 else "All values normal — no abnormal patterns"
            logs.append({"agent": "Clinical Analyzer", "status": "DONE",
                         "key_output": status_msg})

            # Agent 3
            risk = await agent3_risk.run(findings)
            # UNKNOWN means agent errored; LOW/MEDIUM/HIGH/CRITICAL are all valid
            if "error" in risk or risk.get("overall_risk") == "UNKNOWN":
                raise Exception(f"Agent 3 failed: {risk.get('error', 'Risk unknown')}")
            logs.append({"agent": "Risk Assessor", "status": "DONE",
                         "key_output": f"Overall risk: {risk.get('overall_risk')}"})

            # Agent 4
            plan = await agent4_planner.run(risk, before.get("name", "Unknown"), before.get("phone", ""))
            if "error" in plan or not plan.get("action_plan"):
                raise Exception(f"Agent 4 failed: {plan.get('error', 'No action plan')}")
            act_count = len(plan.get("action_plan", []))
            logs.append({"agent": "Action Planner", "status": "DONE",
                         "key_output": f"{act_count} actions planned"})

            # Agent 5 — execute directly via DB, not via HTTP
            execution = await agent5_executor.execute(plan, pid)
            ok_count = sum(1 for v in execution.values() if v.get("status") == "ok")
            logs.append({"agent": "Execution Agent", "status": "DONE",
                         "key_output": f"{ok_count}/{act_count} actions written to Neon Postgres"})

            # Agent 6
            outcome = agent6_reporter.report(before, plan, execution, logs)
            logs.append({"agent": "Outcome Reporter", "status": "DONE",
                         "key_output": "Before/After state generated"})
            outcome["agent_trace"] = logs

            result = {
                "values": values,
                "findings": findings,
                "risk": risk,
                "action_plan": plan,
                "execution": execution,
                "report": outcome
            }

            # Save full analysis result in the patient's record in Neon Postgres
            try:
                import json as _json
                final_risk = outcome.get('after', {}).get('risk_level', before.get('risk_level', 'UNKNOWN'))
                final_follow_up = outcome.get('after', {}).get('follow_up_status', before.get('follow_up_status', 'NONE'))
                final_care_gap = outcome.get('after', {}).get('care_gap', before.get('care_gap', 'OPEN'))

                print(f"[SAVE] Saving analysis for patient_id={pid}: risk={final_risk}")
                async with pool.acquire() as conn:
                    await conn.execute(
                        """
                        UPDATE patients
                        SET risk_level = $1,
                            follow_up_status = $2,
                            care_gap = $3,
                            last_analysis_result = $4::jsonb,
                            last_analyzed_at = NOW()
                        WHERE patient_id = $5
                        """,
                        final_risk,
                        final_follow_up,
                        final_care_gap,
                        _json.dumps(result),
                        pid
                    )
                    # Verify the save actually committed
                    verify = await conn.fetchrow(
                        "SELECT patient_id, risk_level, last_analyzed_at FROM patients WHERE patient_id = $1", pid
                    )
                print(f"[OK] SAVED & VERIFIED — patient_id={verify['patient_id']} risk={verify['risk_level']} at={verify['last_analyzed_at']}")
            except Exception as db_err:
                print(f"[ERROR] DATABASE SAVE FAILED for patient {pid}: {db_err}")
                raise


            return result
        except Exception as e:
            print(f"[ERROR] Pipeline logic failed: {e}")
            err_msg = str(e)
            if "402" in err_msg or "credit" in err_msg.lower() or "afford" in err_msg.lower() or "payment required" in err_msg.lower():
                from fastapi import HTTPException
                raise HTTPException(
                    status_code=402,
                    detail="Analysis failed: insufficient API credits. Please try again."
                )
            raise e

    finally:
        os.unlink(tmp_path)
        # --- ADDED: Pipeline end log ---
        print(f"[OK] Pipeline completed for patient_id={pid}")
