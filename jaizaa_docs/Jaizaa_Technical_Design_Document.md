# Jaizaa — Technical Design Document

**Version:** 1.0 — Final
**App Name:** Jaizaa (جائزہ)
**Document Type:** Technical Design Document
**Status:** Implementation Ready

---

## Table of Contents

1. [System Architecture](#1-system-architecture)
2. [User Navigation Flow](#2-user-navigation-flow)
3. [Database Schema Design](#3-database-schema-design)
4. [Core Modules Breakdown](#4-core-modules-breakdown)
5. [Data Flow Architecture](#5-data-flow-architecture)
6. [Security & Access Control](#6-security--access-control)

---

## 1. System Architecture

### High-Level Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                     │
│                   Flutter Android App                     │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────┐  │
│  │  Screens   │  │  Providers │  │  API Service     │  │
│  │  (7 total) │  │  (State)   │  │  (dio HTTP)      │  │
│  └────────────┘  └────────────┘  └──────────────────┘  │
└────────────────────────┬─────────────────────────────────┘
                         │ HTTPS/JSON
                         ▼
┌──────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                      │
│                    Python FastAPI                         │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────┐  │
│  │  Routes    │  │  Agent     │  │  DB Queries      │  │
│  │  (8 REST)  │  │  Pipeline  │  │  (asyncpg)       │  │
│  └────────────┘  └────────────┘  └──────────────────┘  │
└────────┬──────────────────┬──────────────────────────────┘
         │ OpenAI SDK       │ SQL (async)
         ▼                  ▼
┌─────────────────┐  ┌─────────────────────────────────────┐
│  AI LAYER       │  │     DATA PERSISTENCE LAYER          │
│  OpenAI GPT-4o  │  │     Neon Postgres (Cloud)           │
│  6 Agents:      │  │  ┌──────────┐  ┌──────────────┐   │
│  1. Reader      │  │  │ patients │  │ appointments │   │
│  2. Analyzer    │  │  └──────────┘  └──────────────┘   │
│  3. Risk        │  │  ┌──────────┐  ┌──────────────┐   │
│  4. Planner     │  │  │  alerts  │  │notifications │   │
│  5. Executor    │  │  └──────────┘  └──────────────┘   │
│  6. Reporter    │  │                                     │
└─────────────────┘  └─────────────────────────────────────┘
```

### Component Responsibilities

| Layer | Component | Responsibility |
|---|---|---|
| Presentation | Flutter Screens | UI rendering, user input capture, navigation |
| Presentation | Providers | State management, cache management |
| Presentation | API Service | HTTP communication with backend |
| Application | FastAPI Routes | Request validation, response formatting |
| Application | Agent Pipeline | AI orchestration, clinical reasoning |
| Application | DB Queries | Data persistence, retrieval |
| AI | OpenAI Agents | Document parsing, pattern detection, decision-making |
| Data | Neon Postgres | Permanent storage, relational integrity |

---

## 2. User Navigation Flow

### Primary Navigation Map

```
App Launch
    ↓
┌─────────────────────┐
│  Home Dashboard     │ ← Entry point
└─────────┬───────────┘
          │ Tap "Analyze New Report"
          ↓
┌─────────────────────┐
│  Upload Screen      │
└─────────┬───────────┘
          │ Select file + patient → Tap "Analyze"
          ↓
┌─────────────────────┐
│  Processing Screen  │ ← 6 agents run (15-25s)
└─────────┬───────────┘
          │ Auto-navigate when Agent 6 completes
          ↓
┌─────────────────────┐
│  Results Screen     │
│  ┌─────┬─────┬───┐  │
│  │ Ins │ Act │Log│  │ ← 3 tabs
│  └─────┴─────┴───┘  │
└─────────┬───────────┘
          │ Tap "Execute All" on Actions tab
          ↓
┌─────────────────────┐
│  Execution Screen   │ ← 4 actions run sequentially
└─────────┬───────────┘
          │ Tap "View Before / After"
          ↓
┌─────────────────────┐
│ Before/After Screen │
└─────────┬───────────┘
          │ Tap "Back to Home"
          ↓
┌─────────────────────┐
│  Home Dashboard     │ ← Shows new alert card
└─────────────────────┘

From Home Dashboard:
  Bottom Nav "Patients" →
┌─────────────────────┐
│  Patient List       │
└─────────┬───────────┘
          │ Tap patient row
          ↓
  Returns to Results Screen (last analysis for that patient)
```

### Navigation Rules

| From Screen | Action | To Screen | Type |
|---|---|---|---|
| Home Dashboard | Tap "Analyze New Report" | Upload Screen | Push |
| Upload Screen | Tap "Analyze" | Processing Screen | Push |
| Processing Screen | Agent 6 completes | Results Screen | Replace |
| Results (Actions tab) | Tap "Execute All" | Execution Screen | Push |
| Execution Screen | Tap "View Before/After" | Before/After Screen | Push |
| Before/After Screen | Tap "Back to Home" | Home Dashboard | Pop to root |
| Home Dashboard | Bottom nav "Patients" | Patient List | Replace |
| Patient List | Tap patient row | Results Screen | Push |
| Any screen | Android back button | Previous screen | Pop |

### State Management Flow

```
User Action (Flutter)
    ↓
Provider notifies listeners
    ↓
API Service makes HTTP call (dio)
    ↓
FastAPI route handler
    ↓
Agent Pipeline OR DB Query
    ↓
JSON response returned
    ↓
Provider updates state
    ↓
Widget rebuilds with new data
```

---

## 3. Database Schema Design

### Entity Relationship Diagram

```
┌──────────────────┐
│    patients      │
│─────────────────│
│ patient_id   PK  │
│ name             │
│ phone            │◄──────┐
│ risk_level       │       │
│ follow_up_status │       │ FK
│ care_gap         │       │
│ last_analyzed_at │       │
└──────────────────┘       │
        ▲                  │
        │ FK               │
        │                  │
        ├──────────────────┼────────────────┐
        │                  │                │
┌───────┴─────────┐  ┌─────┴──────────┐  ┌┴─────────────┐
│ appointments    │  │    alerts       │  │notifications │
│────────────────│  │─────────────────│  │──────────────│
│ appointment_id  │  │ alert_id    PK  │  │notification_ │
│ patient_id   FK │  │ recipient_dr_id │  │   id      PK │
│ doctor_id       │  │ patient_id   FK │  │ patient_id FK│
│ specialty       │  │ flagged_values  │  │ channel      │
│ scheduled_slot  │  │ clinical_pattern│  │ message_text │
│ reason          │  │ urgency_level   │  │ status       │
│ status          │  │ message         │  │ created_at   │
│ created_at      │  │ status          │  └──────────────┘
└─────────────────┘  │ created_at      │
                     └─────────────────┘
```

### Table Specifications

#### patients

| Column | Type | Constraints | Default | Purpose |
|---|---|---|---|---|
| patient_id | UUID | PK | gen_random_uuid() | Unique patient identifier |
| name | TEXT | NOT NULL | — | Patient full name |
| phone | TEXT | NULL | — | Contact for notification generation |
| risk_level | TEXT | NOT NULL, CHECK | 'UNKNOWN' | CRITICAL/HIGH/MEDIUM/LOW/UNKNOWN |
| follow_up_status | TEXT | NOT NULL, CHECK | 'NONE' | NONE/SCHEDULED/COMPLETED |
| care_gap | TEXT | NOT NULL, CHECK | 'OPEN' | OPEN/CLOSED |
| last_analyzed_at | TIMESTAMP | NULL | — | Last analysis timestamp |

**Indexes:**
- `idx_patients_risk` on `risk_level` — for sorted patient list

#### appointments

| Column | Type | Constraints | Default | Purpose |
|---|---|---|---|---|
| appointment_id | UUID | PK | gen_random_uuid() | Unique appointment identifier |
| patient_id | UUID | FK, NOT NULL | — | References patients.patient_id |
| doctor_id | TEXT | NOT NULL | 'doctor_001' | Hardcoded for MVP |
| specialty | TEXT | NOT NULL | — | e.g., Nephrology, Cardiology |
| scheduled_slot | TEXT | NOT NULL | — | Simulated slot (e.g., "Tomorrow 10:00 AM") |
| reason | TEXT | NULL | — | Clinical justification |
| status | TEXT | NOT NULL | 'CONFIRMED' | Fixed in MVP |
| created_at | TIMESTAMP | NOT NULL | NOW() | Record creation time |

**Indexes:**
- `idx_appointments_patient` on `patient_id` — for patient detail view

#### alerts

| Column | Type | Constraints | Default | Purpose |
|---|---|---|---|---|
| alert_id | UUID | PK | gen_random_uuid() | Unique alert identifier |
| recipient_doctor_id | TEXT | NOT NULL | 'doctor_001' | Hardcoded for MVP |
| patient_id | UUID | FK, NOT NULL | — | References patients.patient_id |
| flagged_values | JSONB | NOT NULL | — | Lab values triggering alert |
| clinical_pattern | TEXT | NOT NULL | — | Pattern name from Agent 2 |
| urgency_level | TEXT | NOT NULL, CHECK | — | URGENT/HIGH/MEDIUM |
| message | TEXT | NOT NULL | — | Alert message for doctor |
| status | TEXT | NOT NULL, CHECK | 'UNREAD' | UNREAD/READ |
| created_at | TIMESTAMP | NOT NULL | NOW() | Record creation time |

**Indexes:**
- `idx_alerts_status` on `status` — for active alerts query
- `idx_alerts_patient` on `patient_id` — for patient detail view

#### notifications

| Column | Type | Constraints | Default | Purpose |
|---|---|---|---|---|
| notification_id | UUID | PK | gen_random_uuid() | Unique notification identifier |
| patient_id | UUID | FK, NOT NULL | — | References patients.patient_id |
| channel | TEXT | NOT NULL | 'WhatsApp' | Fixed in MVP |
| message_text | TEXT | NOT NULL | — | Full message content (Urdu/English) |
| status | TEXT | NOT NULL | 'GENERATED' | GENERATED (never SENT in MVP) |
| created_at | TIMESTAMP | NOT NULL | NOW() | Record creation time |

**Indexes:**
- None needed for MVP

### Database Integrity Rules

1. **CASCADE DELETE:** If patient deleted → all related appointments, alerts, notifications deleted
2. **CHECK CONSTRAINTS:** Enum-like fields validated at DB level
3. **NOT NULL enforcement:** Critical fields cannot be null
4. **UUID generation:** Automatic via `gen_random_uuid()`
5. **Timestamp defaults:** `created_at` auto-populated

---

## 4. Core Modules Breakdown

### Module 1 — FastAPI Backend

**Location:** `jaizaa-backend/`

**Submodules:**

| Submodule | Files | Responsibility |
|---|---|---|
| Routes | `routes/*.py` | HTTP endpoint handlers, request validation |
| Agent Pipeline | `agents/*.py` | AI orchestration, clinical reasoning |
| Database | `db/*.py` | Connection pool, query helpers |
| Models | `models/*.py` | Pydantic request/response schemas |

**Key Files:**

```python
# main.py
- FastAPI app initialization
- CORS middleware
- Route registration
- Health check endpoint

# routes/analyze.py
- POST /analyze — triggers entire pipeline
- Receives file upload + patient_id
- Returns full analysis result

# agents/pipeline.py
- run() — orchestrates 6 agents sequentially
- Handles temp file cleanup
- Returns combined output of all agents

# agents/agent5_executor.py
- execute() — pure Python function
- Calls 4 FastAPI endpoints
- No LLM involved
- Returns execution status per action

# db/connection.py
- get_pool() — asyncpg connection pool singleton
- Reused across all requests

# db/queries.py
- get_patient()
- create_appointment()
- create_alert()
- create_notification()
- update_patient_record()
```

---

### Module 2 — Flutter Frontend

**Location:** `jaizaa-flutter/lib/`

**Submodules:**

| Submodule | Files | Responsibility |
|---|---|---|
| Screens | `screens/*.dart` | UI rendering, user interactions |
| Providers | `providers/*.dart` | State management (Provider package) |
| Services | `services/*.dart` | HTTP communication (dio) |
| Models | `models/*.dart` | Data classes for API responses |
| Config | `config/*.dart` | Environment configuration |

**Key Files:**

```dart
// main.dart
- App entry point
- Theme configuration
- Initial route setup

// app.dart
- MaterialApp definition
- Named route map
- Global navigation logic

// services/api_service.dart
- analyzeReport() → POST /analyze
- getPatients() → GET /patients
- createPatient() → POST /patients
- All HTTP calls centralized here

// providers/analysis_provider.dart
- Holds current analysis state
- Notifies listeners on state change
- Used by Processing, Results, Execution screens

// screens/processing_screen.dart
- Displays 6 agents running
- Plays back agent_trace with 1.5s delay per step
- Auto-navigates to Results when complete

// screens/results_screen.dart
- 3-tab UI: Insights / Actions / Logs
- "Execute All" button on Actions tab
- Passes action_plan to Execution screen
```

---

### Module 3 — Agent Pipeline (AI Layer)

**Location:** `jaizaa-backend/agents/`

**Agent Definitions:**

| Agent | Type | Input | Output | LLM Used |
|---|---|---|---|---|
| Agent 1 — Document Reader | LLM | File path + type | Lab values JSON | GPT-4o (text + vision) |
| Agent 2 — Clinical Analyzer | LLM | Lab values JSON | Findings JSON | GPT-4o |
| Agent 3 — Risk Assessor | LLM | Findings JSON | Risk JSON | GPT-4o |
| Agent 4 — Action Planner | LLM | Risk JSON + patient info | Action plan JSON | GPT-4o |
| Agent 5 — Execution Agent | Python | Action plan + patient_id | Execution results | None |
| Agent 6 — Outcome Reporter | Python | Before + plan + execution | Before/After + trace | None |

**Agent Communication Pattern:**

```python
Agent 1 output → Agent 2 input
Agent 2 output → Agent 3 input
Agent 3 output → Agent 4 input
Agent 4 output → Agent 5 input
Agent 5 output + Patient DB state → Agent 6 input
Agent 6 output → FastAPI response to Flutter
```

**Error Propagation:**
- If Agent 1–4 fails: raise HTTPException(500)
- If Agent 5 fails partially: mark failed actions, return partial results
- Agent 6 never fails (pure data assembly)

---

### Module 4 — Database Access Layer

**Location:** `jaizaa-backend/db/`

**Query Functions:**

```python
# queries.py

async def get_patient(pool, patient_id: str) -> dict:
    """Fetch patient row by ID"""
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            "SELECT * FROM patients WHERE patient_id = $1", patient_id
        )

async def get_all_patients(pool) -> list:
    """Fetch all patients sorted by risk"""
    async with pool.acquire() as conn:
        return await conn.fetch(
            """SELECT * FROM patients 
               ORDER BY CASE risk_level
                   WHEN 'CRITICAL' THEN 1
                   WHEN 'HIGH' THEN 2
                   WHEN 'MEDIUM' THEN 3
                   WHEN 'LOW' THEN 4
                   ELSE 5 END"""
        )

async def create_appointment(pool, data: dict) -> dict:
    """Insert appointment row"""
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            """INSERT INTO appointments 
               (patient_id, specialty, scheduled_slot, reason)
               VALUES ($1, $2, $3, $4)
               RETURNING *""",
            data['patient_id'], data['specialty'], 
            data['scheduled_slot'], data.get('reason')
        )

async def create_alert(pool, data: dict) -> dict:
    """Insert alert row"""
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            """INSERT INTO alerts 
               (patient_id, flagged_values, clinical_pattern, 
                urgency_level, message)
               VALUES ($1, $2::jsonb, $3, $4, $5)
               RETURNING *""",
            data['patient_id'], json.dumps(data['flagged_values']),
            data['clinical_pattern'], data['urgency_level'], 
            data['message']
        )

async def create_notification(pool, data: dict) -> dict:
    """Insert notification row"""
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            """INSERT INTO notifications 
               (patient_id, channel, message_text)
               VALUES ($1, $2, $3)
               RETURNING *""",
            data['patient_id'], data['channel'], 
            data['message_text']
        )

async def update_patient_record(pool, patient_id: str, updates: dict) -> dict:
    """Update patient risk/status fields"""
    async with pool.acquire() as conn:
        return await conn.fetchrow(
            """UPDATE patients 
               SET risk_level = $1, follow_up_status = $2,
                   care_gap = $3, last_analyzed_at = NOW()
               WHERE patient_id = $4
               RETURNING *""",
            updates['risk_level'], updates['follow_up_status'],
            updates['care_gap'], patient_id
        )
```

---

## 5. Data Flow Architecture

### Complete Request-Response Flow

**Scenario:** Doctor analyzes Ahmed Khan's lab report

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Doctor taps "Analyze" on Upload Screen                   │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Flutter: analysis_provider.analyzeReport(file, patientId)│
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. api_service.dart: POST /analyze (multipart form)         │
│    - file: PDF bytes                                        │
│    - patient_id: "uuid-123"                                 │
└────────────────────┬────────────────────────────────────────┘
                     ↓ HTTPS
┌─────────────────────────────────────────────────────────────┐
│ 4. FastAPI: routes/analyze.py                               │
│    - Save file to /tmp                                      │
│    - Call pipeline.run(file_path, patient_id)               │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Agent Pipeline Execution (sequential)                     │
│                                                              │
│    Agent 1: Extract values from PDF                         │
│       Input:  /tmp/report.pdf                               │
│       Output: {"HbA1c": 11.2, "Creatinine": 2.4, ...}       │
│       Time:   3-5 seconds                                   │
│                                                              │
│    Agent 2: Detect clinical patterns                        │
│       Input:  Lab values JSON                               │
│       Output: [{"pattern": "diabetic nephropathy", ...}]    │
│       Time:   4-6 seconds                                   │
│                                                              │
│    Agent 3: Assess overall risk                             │
│       Input:  Findings JSON                                 │
│       Output: {"overall_risk": "HIGH", ...}                 │
│       Time:   3-4 seconds                                   │
│                                                              │
│    Agent 4: Plan 4 actions                                  │
│       Input:  Risk JSON + patient name/phone                │
│       Output: Action plan with 4 actions                    │
│       Time:   4-5 seconds                                   │
│                                                              │
│    Agent 5: Execute actions (pure Python)                   │
│       - POST /appointments   → DB write                     │
│       - POST /alerts         → DB write                     │
│       - POST /notifications  → DB write                     │
│       - PATCH /patients      → DB write                     │
│       Time:   2-3 seconds                                   │
│                                                              │
│    Agent 6: Generate before/after (pure Python)             │
│       - Fetch patient before-state from DB                  │
│       - Assemble comparison object                          │
│       - Attach agent trace logs                             │
│       Time:   <1 second                                     │
│                                                              │
│    Total Pipeline Time: 16-24 seconds                       │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. FastAPI returns complete result JSON:                    │
│    {                                                         │
│      "values": {...},                                       │
│      "findings": [...],                                     │
│      "risk": {...},                                         │
│      "action_plan": {...},                                  │
│      "execution": {...},                                    │
│      "report": {                                            │
│        "before": {...},                                     │
│        "after": {...},                                      │
│        "agent_trace": [...]                                 │
│      }                                                       │
│    }                                                         │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Flutter receives JSON response                           │
│    - analysis_provider updates state                        │
│    - Processing Screen plays back agent_trace               │
│    - Auto-navigates to Results Screen                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Security & Access Control

### MVP Security Posture

**What IS secured in MVP:**
- HTTPS enforced for all Flutter ↔ FastAPI communication
- CORS configured to allow only known origins
- Database credentials stored in environment variables (never committed)
- OpenAI API key stored in environment variables
- SQL injection prevented via parameterized queries (asyncpg)
- File upload size limits enforced (PDF 10MB, images 5MB)

**What is NOT secured in MVP (acceptable for hackathon):**
- No authentication — anyone with the app can analyze reports
- No doctor login — doctor_id hardcoded as 'doctor_001'
- No patient PHI encryption at rest (Neon Postgres default encryption only)
- No audit logging of who accessed which patient data
- No rate limiting on API endpoints

**Future Security Requirements (post-hackathon):**
- JWT-based authentication for doctors
- Role-based access control (doctor, nurse, admin)
- Patient data encryption at rest and in transit
- Audit trail for all patient record access
- Rate limiting per user
- HIPAA compliance assessment

### Error Message Sanitization

**Production-safe error messages:**
```python
# BAD — exposes internals
{"error": "Database connection failed at line 42 in queries.py"}

# GOOD — generic, no stack trace
{"error": "Service temporarily unavailable. Please retry."}
```

**Debug mode (dev only):**
```python
if os.getenv("DEBUG") == "true":
    return {"error": agent_name, "message": str(exception), "trace": traceback}
else:
    return {"error": "Analysis failed", "message": "Please retry or contact support"}
```

---

**End of Technical Design Document**
