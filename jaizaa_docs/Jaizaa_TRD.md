# Jaizaa — Technical Requirements Document (TRD)

**Version:** 2.0 — Final
**App Name:** Jaizaa (جائزہ)
**Platform:** Android (Flutter) + Python FastAPI + Neon Postgres
**Status:** Implementation Ready

---

## Table of Contents

1. [System Architecture](#1-system-architecture)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Google Antigravity Build Strategy](#3-google-antigravity-build-strategy)
4. [Database Technical Specification](#4-database-technical-specification)
5. [FastAPI Backend Specification](#5-fastapi-backend-specification)
6. [Agent Pipeline Technical Specification](#6-agent-pipeline-technical-specification)
7. [Flutter Frontend Specification](#7-flutter-frontend-specification)
8. [API Contract](#8-api-contract)
9. [Error Handling Specification](#9-error-handling-specification)
10. [Environment & Configuration](#10-environment--configuration)
11. [Deployment Specification](#11-deployment-specification)

---

## 1. System Architecture

### Three-Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│              Flutter Android App                    │
│  UI Layer: screens, state, HTTP client              │
│  State: Provider                                    │
│  HTTP: dio package                                  │
└────────────────────┬────────────────────────────────┘
                     │ HTTP REST (JSON)
                     ▼
┌─────────────────────────────────────────────────────┐
│           Python FastAPI Backend                    │
│  Receives uploads, runs agent pipeline,             │
│  writes to DB, returns results to Flutter           │
│  Hosted: Railway                                    │
└──────────┬──────────────────────┬───────────────────┘
           │ OpenAI Agents SDK    │ asyncpg
           ▼                      ▼
┌──────────────────┐   ┌─────────────────────────────┐
│  6-Agent Chain   │   │       Neon Postgres          │
│  (runs inside    │   │  patients                   │
│   FastAPI        │   │  appointments               │
│   process)       │   │  alerts                     │
│  GPT-4o model    │   │  notifications              │
└──────────────────┘   └─────────────────────────────┘
```

### Key Architectural Rules

1. The agent pipeline runs **inside the FastAPI process** — not a separate microservice
2. Flutter **never calls OpenAI directly** — all AI calls go through FastAPI
3. Agent 5 (Execution Agent) is a **pure Python function** — it calls FastAPI endpoints internally; no LLM involved
4. Agent 6 (Outcome Reporter) is a **pure Python function** — deterministic assembly of before/after state; no LLM involved
5. Flutter's Processing Screen **simulates** progressive agent updates by playing back the trace array returned by FastAPI — it does not stream

---

## 2. Tech Stack & Dependencies

### Flutter (Mobile)

| Package | Version | Purpose |
|---|---|---|
| `flutter` | latest stable | Framework |
| `dio` | ^5.4.0 | HTTP client |
| `provider` | ^6.1.0 | State management |
| `file_picker` | ^8.0.0 | PDF upload |
| `image_picker` | ^1.0.0 | Camera photo |
| `shared_preferences` | ^2.2.0 | Local config storage |

### Python FastAPI (Backend)

```
fastapi==0.111.0
uvicorn==0.29.0
python-dotenv==1.0.1
asyncpg==0.29.0
sqlalchemy[asyncio]==2.0.30
openai==1.30.0
openai-agents==0.0.11
pymupdf==1.24.3
python-multipart==0.0.9
pydantic==2.7.1
httpx==0.27.0
```

---

## 3. Google Antigravity Build Strategy

### What Antigravity Is (Technical)

Antigravity is a **VS Code fork** — Google's agent-first IDE. It is a **development-time tool only**. It does not run at app runtime.

- **Editor View:** AI-assisted coding (like Cursor) for writing individual files
- **Manager View:** Spawns multiple autonomous agents working on different tasks in parallel, each producing an Artifact

### Manager View Agent Tasks for Jaizaa Build

Run these in parallel in Manager View during Phase 1:

| Antigravity Agent Task | Instruction |
|---|---|
| Backend scaffold | "Create FastAPI app with all 8 endpoints from the TRD API Contract. Use asyncpg + async SQLAlchemy. Include CORS middleware for Flutter." |
| Database schema | "Write SQL migration file for 4 tables: patients, appointments, alerts, notifications using the exact schema in the TRD." |
| Flutter scaffold | "Create Flutter Android app with 7 screens from the PRD Screen Inventory. Use Provider for state. Wire dio HTTP client to API_BASE_URL env variable." |
| Agent pipeline | "Create 6 Python agent files in agents/ folder using OpenAI Agents SDK, following the agent specs in the TRD." |

### Antigravity Artifacts → Hackathon Evidence

Every Manager View agent task produces:
- **Plan Artifact** — checklist of intended actions
- **Execution Artifact** — code diffs and files created
- **Verification Artifact** — logs proving the change worked

Export all Artifacts before submission. These ARE the workplan + agent trace logs required by judges.

---

## 4. Database Technical Specification

### Migration SQL

**File:** `migrations/001_initial.sql`

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS patients (
    patient_id     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name           TEXT        NOT NULL,
    phone          TEXT,
    risk_level     TEXT        NOT NULL DEFAULT 'UNKNOWN'
                               CHECK (risk_level IN ('UNKNOWN','LOW','MEDIUM','HIGH','CRITICAL')),
    follow_up_status TEXT      NOT NULL DEFAULT 'NONE'
                               CHECK (follow_up_status IN ('NONE','SCHEDULED','COMPLETED')),
    care_gap       TEXT        NOT NULL DEFAULT 'OPEN'
                               CHECK (care_gap IN ('OPEN','CLOSED')),
    last_analyzed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS appointments (
    appointment_id UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id     UUID        NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    doctor_id      TEXT        NOT NULL DEFAULT 'doctor_001',
    specialty      TEXT        NOT NULL,
    scheduled_slot TEXT        NOT NULL,
    reason         TEXT,
    status         TEXT        NOT NULL DEFAULT 'CONFIRMED',
    created_at     TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alerts (
    alert_id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_doctor_id TEXT   NOT NULL DEFAULT 'doctor_001',
    patient_id         UUID    NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    flagged_values     JSONB   NOT NULL,
    clinical_pattern   TEXT    NOT NULL,
    urgency_level      TEXT    NOT NULL
                               CHECK (urgency_level IN ('URGENT','HIGH','MEDIUM')),
    message            TEXT    NOT NULL,
    status             TEXT    NOT NULL DEFAULT 'UNREAD'
                               CHECK (status IN ('UNREAD','READ')),
    created_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    notification_id UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID      NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    channel         TEXT      NOT NULL DEFAULT 'WhatsApp',
    message_text    TEXT      NOT NULL,
    status          TEXT      NOT NULL DEFAULT 'GENERATED',
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_patients_risk ON patients(risk_level);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_patient ON alerts(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient ON appointments(patient_id);
```

**Run:** `psql $DATABASE_URL -f migrations/001_initial.sql`

### Demo State Verification

Before demo: Run these in Neon SQL editor to confirm clean state:
```sql
SELECT COUNT(*) FROM appointments;  -- Must return 0
SELECT COUNT(*) FROM alerts;         -- Must return 0
SELECT COUNT(*) FROM notifications;  -- Must return 0
SELECT patient_id, name, risk_level FROM patients;  -- Shows risk_level = UNKNOWN
```

After demo: Run same queries — all should return rows.

---

## 5. FastAPI Backend Specification

### Project Structure

```
jaizaa-backend/
├── main.py                    # App init, CORS, route registration
├── routes/
│   ├── analyze.py             # POST /analyze
│   ├── patients.py            # GET/POST/PATCH patients
│   ├── appointments.py        # POST /appointments
│   ├── alerts.py              # POST /alerts
│   └── notifications.py       # POST /notifications
├── agents/
│   ├── pipeline.py            # Orchestrator — runs agents 1–6 in sequence
│   ├── agent1_reader.py       # Document Reader (LLM)
│   ├── agent2_analyzer.py     # Clinical Analyzer (LLM)
│   ├── agent3_risk.py         # Risk Assessor (LLM)
│   ├── agent4_planner.py      # Action Planner (LLM)
│   ├── agent5_executor.py     # Execution Agent (pure Python — calls FastAPI)
│   └── agent6_reporter.py     # Outcome Reporter (pure Python)
├── db/
│   ├── connection.py          # asyncpg pool
│   └── queries.py             # Raw SQL helpers
├── models/
│   ├── patient.py
│   ├── appointment.py
│   ├── alert.py
│   └── notification.py
├── migrations/
│   └── 001_initial.sql
├── requirements.txt
├── Procfile                   # For Railway deployment
└── .env
```

### main.py

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import analyze, patients, appointments, alerts, notifications

app = FastAPI(title="Jaizaa API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analyze.router)
app.include_router(patients.router)
app.include_router(appointments.router)
app.include_router(alerts.router)
app.include_router(notifications.router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "jaizaa-api"}
```

### Database Connection

```python
# db/connection.py
import asyncpg, os
from dotenv import load_dotenv

load_dotenv()
_pool = None

async def get_pool():
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(
            os.getenv("DATABASE_URL"),
            min_size=1,
            max_size=5
        )
    return _pool
```

---

## 6. Agent Pipeline Technical Specification

### Agent Construction Pattern

All LLM-based agents (1–4) follow this exact pattern:

```python
from agents import Agent, Runner

agent = Agent(
    name="AgentName",
    instructions="[System prompt — see per-agent spec below]",
    model="gpt-4o"
)

async def run(input_data: dict) -> dict:
    result = await Runner.run(agent, input=str(input_data))
    raw = result.final_output.strip()
    # Strip markdown fences if present
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    import json
    return json.loads(raw.strip())
```

**Critical rule:** Every LLM agent system prompt must end with: *"Return ONLY valid JSON. No explanation text. No markdown code fences. No preamble."*

---

### Agent 1 — Document Reader

**Input:** file path (str) + file type ("pdf" | "image")
**Output:**
```json
{
  "patient_name": "string or null",
  "report_date": "YYYY-MM-DD or null",
  "extraction_method": "pdf_text | image_vision | fallback_vision",
  "values": {
    "HbA1c":     {"value": 11.2, "unit": "%",      "reference_range": "4.0–5.6"},
    "Creatinine": {"value": 2.4,  "unit": "mg/dL",  "reference_range": "0.7–1.3"}
  }
}
```

**Logic:**
```python
import fitz   # PyMuPDF
import base64

def extract_text_from_pdf(path: str) -> str:
    doc = fitz.open(path)
    return "\n".join(page.get_text() for page in doc)

def encode_image_base64(path: str) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()
```

**System prompt:**
```
You are a medical document reader. You receive either extracted text from a lab 
report PDF or a base64-encoded photo of a lab report.

Extract every lab value: name, numeric value, unit, and reference range.
If a value cannot be read, set it to null — never guess.
Return ONLY valid JSON. No explanation. No markdown fences.
```

**Fallback rule:** If PyMuPDF extracts fewer than 50 characters, automatically fall back to GPT-4o Vision. Set `extraction_method = "fallback_vision"`.

---

### Agent 2 — Clinical Analyzer

**Input:** Agent 1 output (values JSON)
**Output:**
```json
{
  "findings": [
    {
      "values_involved": ["HbA1c", "Creatinine"],
      "pattern": "Early diabetic nephropathy pattern",
      "explanation": "HbA1c 11.2 indicates severely uncontrolled diabetes. Creatinine 2.4 indicates reduced kidney filtration. Together this combination strongly suggests early diabetic nephropathy.",
      "confidence": 0.94
    }
  ]
}
```

**System prompt:**
```
You are a clinical pattern analyzer. You receive structured lab values.

Identify clinically meaningful PATTERNS — combinations of values that together 
suggest a clinical condition. Do not just flag individual out-of-range values.
Provide confidence 0.0–1.0 per pattern.
Write explanation in plain English understandable to a junior doctor.
If no significant patterns exist, return: {"findings": []}
Return ONLY valid JSON. No explanation. No markdown fences.
```

---

### Agent 3 — Risk Assessor

**Input:** Agent 2 output (findings JSON)
**Output:**
```json
{
  "overall_risk": "HIGH",
  "risk_reasoning": "Two concurrent findings — early nephropathy (94% confidence) and anemia of chronic disease. Combined trajectory without intervention: renal failure within 6–12 months.",
  "consequences": [
    {
      "pattern": "Early diabetic nephropathy pattern",
      "consequence": "Progressive renal failure — GFR declining",
      "urgency": "URGENT"
    }
  ]
}
```

**System prompt:**
```
You are a clinical risk assessor. You receive clinical findings.

Assign overall risk: CRITICAL / HIGH / MEDIUM / LOW.
CRITICAL = life-threatening within 24–72 hours.
HIGH = rapid deterioration within weeks without intervention.
Justify overall risk in risk_reasoning.
Assign urgency per consequence: URGENT / HIGH / MEDIUM / ROUTINE.
Return ONLY valid JSON. No explanation. No markdown fences.
```

---

### Agent 4 — Action Planner

**Input:** Agent 3 output + patient name + phone
**Output:** Exactly 4 actions — one of each type:
```json
{
  "action_plan": [
    {
      "action_type": "appointment",
      "priority": "URGENT",
      "specialty": "Nephrology",
      "reason": "Early diabetic nephropathy — nephrology review required within 48 hours",
      "scheduled_slot": "Tomorrow 10:00 AM"
    },
    {
      "action_type": "alert",
      "priority": "HIGH",
      "urgency_level": "HIGH",
      "clinical_pattern": "Early diabetic nephropathy pattern",
      "flagged_values": {"HbA1c": 11.2, "Creatinine": 2.4},
      "message": "Ahmed Khan — HbA1c 11.2 + Creatinine 2.4 — Early diabetic nephropathy — Urgent review required"
    },
    {
      "action_type": "notification",
      "priority": "HIGH",
      "channel": "WhatsApp",
      "message_text": "Assalam o Alaikum Ahmed sahab, aapke lab results mein kuch zaroori findings hain. Kal subah 10 baje Nephrology mein appointment book ho gayi hai. Waqt par aa jayen. — Clinic"
    },
    {
      "action_type": "app_record_update",
      "priority": "ROUTINE",
      "updates": {
        "risk_level": "HIGH",
        "follow_up_status": "SCHEDULED",
        "care_gap": "CLOSED"
      }
    }
  ]
}
```

**System prompt:**
```
You are a clinical action planner. You receive a risk assessment and patient details.

Generate EXACTLY 4 actions — one of each type:
1. appointment — specialist referral
2. alert — in-app doctor alert (NOT email, NOT push notification)
3. notification — WhatsApp message text for patient (Urdu or bilingual, under 200 chars)
4. app_record_update — risk_level, follow_up_status, care_gap updates

Priority order in list: URGENT first, then HIGH, then ROUTINE.
app_record_update priority is always ROUTINE.
Return ONLY valid JSON. No explanation. No markdown fences.
```

---

### Agent 5 — Execution Agent (Pure Python)

**No LLM. Calls FastAPI endpoints.**

```python
import httpx, os

BASE = os.getenv("API_BASE_URL", "http://localhost:8000")

async def execute(action_plan: dict, patient_id: str) -> dict:
    results = {}
    async with httpx.AsyncClient(timeout=10.0) as client:
        plan = action_plan["action_plan"]

        appt = next(a for a in plan if a["action_type"] == "appointment")
        r1 = await client.post(f"{BASE}/appointments", json={
            "patient_id": patient_id, "specialty": appt["specialty"],
            "scheduled_slot": appt["scheduled_slot"], "reason": appt["reason"]
        })
        results["appointment"] = {"status": "ok", **r1.json()} if r1.status_code == 200 else {"status": "failed", "code": r1.status_code}

        alert = next(a for a in plan if a["action_type"] == "alert")
        r2 = await client.post(f"{BASE}/alerts", json={
            "patient_id": patient_id, "flagged_values": alert["flagged_values"],
            "clinical_pattern": alert["clinical_pattern"],
            "urgency_level": alert["urgency_level"], "message": alert["message"]
        })
        results["alert"] = {"status": "ok", **r2.json()} if r2.status_code == 200 else {"status": "failed", "code": r2.status_code}

        notif = next(a for a in plan if a["action_type"] == "notification")
        r3 = await client.post(f"{BASE}/notifications", json={
            "patient_id": patient_id, "channel": "WhatsApp",
            "message_text": notif["message_text"]
        })
        results["notification"] = {"status": "ok", **r3.json()} if r3.status_code == 200 else {"status": "failed", "code": r3.status_code}

        record = next(a for a in plan if a["action_type"] == "app_record_update")
        r4 = await client.patch(f"{BASE}/patients/{patient_id}", json=record["updates"])
        results["app_record_update"] = {"status": "ok", **r4.json()} if r4.status_code == 200 else {"status": "failed", "code": r4.status_code}

    return results
```

---

### Agent 6 — Outcome Reporter (Pure Python)

**No LLM. Assembles before/after from DB state + execution results.**

```python
def report(before: dict, action_plan: dict, execution: dict, logs: list) -> dict:
    record_update = next(a for a in action_plan["action_plan"] if a["action_type"] == "app_record_update")
    return {
        "before": {
            "risk_level": before.get("risk_level", "UNKNOWN"),
            "follow_up_status": before.get("follow_up_status", "NONE"),
            "care_gap": before.get("care_gap", "OPEN"),
            "doctor_awareness": "UNAWARE"
        },
        "after": {
            "risk_level": record_update["updates"]["risk_level"],
            "follow_up_status": "SCHEDULED",
            "care_gap": "CLOSED",
            "doctor_awareness": "ALERTED"
        },
        "execution_results": execution,
        "agent_trace": logs
    }
```

---

### Pipeline Orchestrator

```python
# agents/pipeline.py
import os, tempfile
from db import queries
from agents import (agent1_reader, agent2_analyzer, agent3_risk,
                    agent4_planner, agent5_executor, agent6_reporter)

async def run(file_bytes: bytes, filename: str, patient_id: str, pool) -> dict:
    logs = []

    # Save temp file
    suffix = ".pdf" if filename.endswith(".pdf") else ".jpg"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as f:
        f.write(file_bytes)
        tmp_path = f.name

    file_type = "pdf" if suffix == ".pdf" else "image"

    # Fetch before state
    before = await queries.get_patient(pool, patient_id)

    # Agent 1
    values = await agent1_reader.run(tmp_path, file_type)
    logs.append({"agent": "Document Reader", "status": "DONE",
                 "key_output": f"Extracted {len(values.get('values', {}))} lab values via {values.get('extraction_method')}"})

    # Agent 2
    findings = await agent2_analyzer.run(values)
    logs.append({"agent": "Clinical Analyzer", "status": "DONE",
                 "key_output": f"{len(findings.get('findings', []))} clinical patterns detected"})

    # Agent 3
    risk = await agent3_risk.run(findings)
    logs.append({"agent": "Risk Assessor", "status": "DONE",
                 "key_output": f"Overall risk: {risk.get('overall_risk')}"})

    # Agent 4
    plan = await agent4_planner.run(risk, before.get("name"), before.get("phone"))
    logs.append({"agent": "Action Planner", "status": "DONE",
                 "key_output": "4 actions planned (Appointment, Alert, Notification, App Record Update)"})

    # Agent 5
    execution = await agent5_executor.execute(plan, patient_id)
    ok_count = sum(1 for v in execution.values() if v.get("status") == "ok")
    logs.append({"agent": "Execution Agent", "status": "DONE",
                 "key_output": f"{ok_count}/4 actions written to Neon Postgres"})

    # Agent 6
    outcome = agent6_reporter.report(before, plan, execution, logs)
    logs.append({"agent": "Outcome Reporter", "status": "DONE",
                 "key_output": "Before/After state generated"})
    outcome["agent_trace"] = logs

    os.unlink(tmp_path)

    return {
        "values": values,
        "findings": findings,
        "risk": risk,
        "action_plan": plan,
        "execution": execution,
        "report": outcome
    }
```

---

## 7. Flutter Frontend Specification

### Project Structure

```
jaizaa-flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp + named routes
│   ├── config/
│   │   └── api_config.dart           # BASE_URL from dart-define
│   ├── models/
│   │   ├── patient.dart
│   │   ├── analysis_result.dart      # Full pipeline response model
│   │   └── action_result.dart
│   ├── services/
│   │   └── api_service.dart          # All dio HTTP calls
│   ├── providers/
│   │   ├── patient_provider.dart     # Patient list state
│   │   └── analysis_provider.dart   # Current analysis state
│   └── screens/
│       ├── home_dashboard.dart
│       ├── upload_screen.dart
│       ├── processing_screen.dart
│       ├── results_screen.dart       # 3-tab screen
│       ├── execution_screen.dart
│       ├── before_after_screen.dart
│       └── patient_list_screen.dart
├── pubspec.yaml
└── android/app/src/main/AndroidManifest.xml
```

### api_service.dart — Core Methods

```dart
class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 90),
  ));

  Future<Map<String, dynamic>> analyzeReport(File file, String patientId) async {
    final formData = FormData.fromMap({
      'patient_id': patientId,
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
    });
    final response = await _dio.post('/analyze', data: formData);
    return response.data;
  }

  Future<List<dynamic>> getPatients() async {
    final response = await _dio.get('/patients');
    return response.data;
  }

  Future<Map<String, dynamic>> createPatient(String name, String phone) async {
    final response = await _dio.post('/patients',
        data: {'name': name, 'phone': phone});
    return response.data;
  }
}
```

### Processing Screen — Agent Trace Playback

```dart
void _playTrace(List<dynamic> trace) async {
  for (final step in trace) {
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _doneAgents.add(step['agent'] as String);
      _logs.add('[${step['agent']}] ${step['key_output']}');
    });
  }
  // Navigate to results after all agents shown
  if (mounted) {
    Navigator.pushReplacementNamed(context, '/results',
        arguments: _fullResult);
  }
}
```

### Execution Screen — Sequential Card Reveal

```dart
void _revealActions() async {
  final actions = ['appointment', 'alert', 'notification', 'app_record_update'];
  for (final key in actions) {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _completed.add(key));
  }
  setState(() => _allDone = true);
}
```

### Risk Color Utility

```dart
Color riskColor(String risk) => switch (risk) {
  'CRITICAL' => const Color(0xFFB71C1C),
  'HIGH'     => const Color(0xFFE65100),
  'MEDIUM'   => const Color(0xFFF9A825),
  'LOW'      => const Color(0xFF2E7D32),
  _          => const Color(0xFF757575),
};
```

---

## 8. API Contract

Complete endpoint specification. Flutter and FastAPI must both conform to this exactly.

### GET /health
**Response:** `{"status": "ok", "service": "jaizaa-api"}`

### POST /analyze
**Request:** `multipart/form-data` — `file` (PDF/image) + `patient_id` (string)
**Response:** Full pipeline result (values + findings + risk + action_plan + execution + report)
**Error:** `{"error": "AgentName", "message": "description"}` — HTTP 500

### POST /patients
**Request:** `{"name": "string", "phone": "string (optional)"}`
**Response:** Full patient row with default values

### GET /patients
**Response:** Array of all patients sorted by risk_level (CRITICAL first)

### GET /patients/{patient_id}
**Response:** Patient object + arrays: `appointments`, `alerts`, `notifications`

### PATCH /patients/{patient_id}
**Request:** `{"risk_level": "HIGH", "follow_up_status": "SCHEDULED", "care_gap": "CLOSED"}`
**Response:** Updated patient row

### POST /appointments
**Request:** `{"patient_id", "specialty", "scheduled_slot", "reason"}`
**Response:** `{"appointment_id", "status": "CONFIRMED", "scheduled_slot", "created_at"}`

### POST /alerts
**Request:** `{"patient_id", "flagged_values" (JSON), "clinical_pattern", "urgency_level", "message"}`
**Response:** `{"alert_id", "status": "UNREAD", "created_at"}`

### POST /notifications
**Request:** `{"patient_id", "channel": "WhatsApp", "message_text"}`
**Response:** `{"notification_id", "status": "GENERATED", "message_text", "created_at"}`

---

## 9. Error Handling Specification

### Agent Failure (Agents 1–4)
```python
try:
    result = await agent_N.run(input_data)
except Exception as e:
    raise HTTPException(status_code=500,
        detail={"error": "AgentN_Name", "message": str(e)})
```
Flutter shows: `"[AgentName] encountered an error. Tap to retry."` on Processing Screen.

### DB Write Failure (Agent 5)
- Do NOT abort remaining actions
- Mark failed action: `{"status": "failed", "code": <http_status>}`
- Return partial execution results
- Flutter shows failed action row in red on Execution Screen

### PDF Parse Failure
- If PyMuPDF extracts < 50 chars: auto-fallback to GPT-4o Vision
- Log: `extraction_method = "fallback_vision"`
- No error shown to user — transparent fallback

### Network Timeout (Flutter)
- `connectTimeout = 60s`, `receiveTimeout = 90s`
- On timeout: show "Connection failed. Check your internet and retry."
- Retry button navigates back to Upload Screen

---

## 10. Environment & Configuration

### FastAPI `.env`
```
DATABASE_URL=postgresql://user:password@host/dbname?sslmode=require
OPENAI_API_KEY=sk-...
API_BASE_URL=https://your-backend.railway.app
```

### Flutter `api_config.dart`
```dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',  // Android emulator → localhost
  );
}
```

**Build command:**
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-backend.railway.app
```

---

## 11. Deployment Specification

### FastAPI → Railway

1. Push `jaizaa-backend/` to GitHub repository
2. Create Railway project → Deploy from GitHub → Select repo
3. Set environment variables in Railway dashboard (DATABASE_URL, OPENAI_API_KEY)
4. Add `Procfile`:
   ```
   web: uvicorn main:app --host 0.0.0.0 --port $PORT
   ```
5. Railway auto-deploys on push. Copy public URL → set as `API_BASE_URL`

### Flutter → Android APK
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-backend.railway.app

# Install on demo device
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Neon Postgres
- Cloud-hosted at neon.tech — no deployment needed
- Run migration SQL once via Neon SQL editor or `psql`
- Verify connectivity: `GET /health` must return 200 after Railway deploy
