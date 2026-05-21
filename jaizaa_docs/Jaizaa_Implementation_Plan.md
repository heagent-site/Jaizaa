# Jaizaa — Implementation Plan

**Version:** 1.0 — Final
**App Name:** Jaizaa (جائزہ)
**Document Type:** Implementation Plan
**Build Platform:** Google Antigravity
**Timeline:** 1 day (phased execution)

---

## Overview

This document provides the implementation roadmap for building Jaizaa in Google Antigravity. The project is divided into **4 phases**, each with clear deliverables and acceptance gates. Phases 1–2 run in parallel using Antigravity Manager View. Phase 3 executes sequentially. Phase 4 integrates pre-generated UI.

**Critical constraint:** 1 day timeline — prioritize core demo flow over edge cases.

---

## Phase Execution Strategy

```
┌─────────────────────────────────────────────────────────┐
│  PARALLEL EXECUTION (Antigravity Manager View)          │
│                                                          │
│  Phase 1: Foundation        Phase 2: Agent Pipeline     │
│  (Backend + DB)             (6 AI Agents)               │
│  Agent A: FastAPI scaffold  Agent B: Agent code         │
│  Agent C: DB migration      Agent D: OpenAI integration │
│                                                          │
│  Duration: 2–3 hours        Duration: 2–3 hours         │
└────────────┬────────────────────────┬───────────────────┘
             │                        │
             └────────┬───────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  SEQUENTIAL EXECUTION                                    │
│                                                          │
│  Phase 3: Execution Layer                               │
│  (4 actions + Neon Postgres writes)                     │
│  Duration: 2–3 hours                                    │
└────────────────────────┬────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  INTEGRATION PHASE                                       │
│                                                          │
│  Phase 4: Flutter UI Integration                        │
│  ⚠️ UI screens already generated via Stitch             │
│  Task: Connect screens to backend API                   │
│  Duration: 2–3 hours                                    │
└─────────────────────────────────────────────────────────┘
```

**Total estimated time:** 8–12 hours (within 1 day)

---

## Phase 1 — Foundation (Backend + Database)

### Objective
Set up Neon Postgres with all 4 tables and deploy a running FastAPI backend with empty endpoint stubs.

### Deliverables
1. Neon Postgres database live with 4 tables created
2. FastAPI app deployed on Railway with `/health` returning 200
3. All 8 endpoints defined (stubbed — can return mock responses)
4. Database connection verified from FastAPI

### Antigravity Manager View Tasks

**Task 1A — Database Schema**
```
Instruction to Antigravity Agent:
"Create a SQL migration file at migrations/001_initial.sql that creates 4 tables:
patients, appointments, alerts, notifications. Use the exact schema from 
Jaizaa_TRD_v1.md section 4. Include CHECK constraints for enum fields.
Include indexes on patients.risk_level, alerts.status. Use gen_random_uuid() for UUIDs."
```

**Task 1B — FastAPI Project Scaffold**
```
Instruction to Antigravity Agent:
"Create FastAPI backend structure: main.py with CORS, routes/ folder with 5 files,
db/connection.py with asyncpg pool, db/queries.py with stub functions, models/ folder,
requirements.txt with all dependencies, Procfile for Railway deployment.
Each endpoint returns mock JSON. Goal: running server, not full logic."
```

### Acceptance Criteria
- [ ] Run migration SQL — all tables created
- [ ] FastAPI running locally: `GET /health` returns 200
- [ ] Deploy to Railway completes
- [ ] Railway URL accessible

### Time: 2–3 hours

---

## Phase 2 — Agent Pipeline (AI Layer)

### Objective
Build 6-agent AI pipeline using OpenAI Agents SDK. Pipeline runs end-to-end.

### Deliverables
1. 6 agent files with clear I/O contracts
2. Pipeline orchestrator runs agents 1–6 sequentially
3. Agent 5 & 6 are pure Python (no LLM)
4. Pipeline tested with sample PDF

### Antigravity Tasks

**Task 2A — Agents 1–4 (LLM-based)**
```
Create 4 agent files using OpenAI Agents SDK:
- agent1_reader.py: PDF/image → lab values JSON
- agent2_analyzer.py: values → clinical patterns JSON
- agent3_risk.py: patterns → risk assessment JSON
- agent4_planner.py: risk → action plan (4 actions)
System prompts from TRD section 6. All return valid JSON only.
```

**Task 2B — Agents 5 & 6 (Pure Python)**
```
- agent5_executor.py: calls 4 FastAPI endpoints via httpx
- agent6_reporter.py: assembles before/after comparison
No LLM. Reference TRD sections 6.7 and 6.8.
```

**Task 2C — Pipeline Orchestrator**
```
agents/pipeline.py:
- Runs agents 1→6 sequentially
- Logs each agent's output
- Returns combined result
Wire to POST /analyze endpoint.
```

### Acceptance Criteria
- [ ] Upload PDF → pipeline runs without errors
- [ ] Agent 1 extracts 3+ lab values
- [ ] Agent 4 returns exactly 4 actions
- [ ] Pipeline completes in under 30 seconds
- [ ] agent_trace contains 6 log entries

### Time: 2–3 hours (parallel with Phase 1)

---

## Phase 3 — Execution Layer (Database Writes)

### Objective
Implement 4 database write operations. Agent 5 persists to Neon Postgres.

### Deliverables
1. All 4 write endpoints fully implemented
2. Agent 5 successfully writes to all 4 tables
3. Before/After state verifiable in Neon dashboard

### Tasks

**Task 3A — Implement Write Endpoints**
```
Complete these 4 endpoints using db/queries.py:
- POST /appointments: insert appointment row, return with ID
- POST /alerts: insert alert row with status=UNREAD
- POST /notifications: insert notification with status=GENERATED
- PATCH /patients/{id}: update risk_level, follow_up_status, care_gap
```

**Task 3B — Test Agent 5 Execution**
```
Run full pipeline with test PDF. Query Neon Postgres:
- SELECT COUNT(*) FROM appointments; -- Should return 1
- SELECT COUNT(*) FROM alerts; -- Should return 1
- SELECT COUNT(*) FROM notifications; -- Should return 1
- SELECT * FROM patients WHERE ...; -- Should show updated risk_level
```

### Acceptance Criteria
- [ ] All 4 endpoints return 200
- [ ] Agent 5 completes without errors
- [ ] All 4 tables show new rows in Neon
- [ ] Patient risk_level changes from UNKNOWN → HIGH
- [ ] Before/After shows correct state change

### Time: 2–3 hours

---

## Phase 4 — Flutter UI Integration

### Objective
Connect pre-generated Flutter UI to backend API. Full demo flow works end-to-end.

### ⚠️ Important Note

**Flutter UI screens already generated via Stitch.** Component-level code complete. Phase 4 is **integration and refinement only** — not building screens from scratch.

### Deliverables
1. All 7 screens connected to FastAPI backend
2. Processing Screen plays back agent trace
3. Execution Screen reveals 4 cards sequentially
4. Before/After Screen displays state comparison
5. App runs full demo without crash

### Tasks

**Task 4A — API Service Integration**
```
Update services/api_service.dart:
- Set ApiConfig.baseUrl to Railway URL
- Verify analyzeReport() multipart/form-data works
- Add error handling for network timeouts
Test each API call independently.
```

**Task 4B — Processing Screen Playback**
```
In processing_screen.dart:
- Extract agent_trace from POST /analyze response
- Loop with 1.5s delay per step
- Update agent status badges: PENDING → RUNNING → DONE
- Auto-navigate to Results when done
Do NOT modify UI components — only state logic.
```

**Task 4C — Execution Screen Reveal**
```
In execution_screen.dart:
- Execute actions in order with 800ms delay
- Show loading → checkmark per action
- Show 'View Before/After' button after all 4 complete
Do NOT modify card components — only animation logic.
```

**Task 4D — Before/After Data Binding**
```
In before_after_screen.dart:
- Bind result['report']['before'] and result['report']['after'] to table
- Color code: red (before) → green (after)
- Show summary: '4 fields updated'
UI layout exists — only bind data.
```

**Task 4E — Responsiveness & Polish**
```
Review all screens for:
- Responsive layout on different screen sizes
- Loading states show spinners
- Error states show retry buttons
- Navigation back button works
Fix layout issues only — do not redesign.
```

### Demo Scenario Test
Run full flow from PRD section 14:
1. Home → Analyze New Report
2. Upload PDF → Processing (6 agents)
3. Results → Execute All
4. Execution → 4 cards appear
5. Before/After → state comparison
6. Home → new alert appears

### Acceptance Criteria
- [ ] Full demo completes without crash
- [ ] All screens render correctly
- [ ] Agent trace animation smooth
- [ ] 4 cards appear with correct timing
- [ ] Before/After shows correct changes
- [ ] Run demo 3 consecutive times — all succeed

### Time: 2–3 hours

---

## Testing & Validation Checklist

### Pre-Demo Verification (30 min before submission)

**Backend:**
- [ ] GET /health returns 200
- [ ] Upload PDF → pipeline completes in <60s
- [ ] All 4 tables show new rows
- [ ] Agent trace has 6 entries

**Frontend:**
- [ ] App launches without crash
- [ ] Upload opens file picker
- [ ] Processing shows 6 agents
- [ ] Results 3 tabs render
- [ ] Execution 4 cards appear
- [ ] Before/After table populated

**Demo Scenario:**
- [ ] Run end-to-end 3 times
- [ ] All 3 runs succeed
- [ ] Neon shows 3 sets of records

**Judge Evidence:**
- [ ] Logs tab shows agent trace
- [ ] Before/After shows state change
- [ ] Antigravity Artifacts exported

---

## Risk Mitigation

| Risk | Mitigation |
|---|---|
| Agent timeout (>60s) | Cache PDF parsing, optimize prompts |
| DB connection fails | Test connection before demo, have backup Railway deploy |
| Flutter crash on device | Test on emulator AND physical device |
| Agent returns invalid JSON | Add JSON validation + fallback error handling |
| Network timeout during demo | Pre-upload test PDF to Railway, use local backend as backup |

---

## Submission Checklist

Before hackathon submission:

- [ ] GitHub repository created with all code
- [ ] README.md includes: setup instructions, Railway URL, Neon connection tested
- [ ] Demo video (3–5 min) recorded showing full flow
- [ ] Antigravity Artifacts exported (Plan, Execution, Verification)
- [ ] APK file built and tested on Android device
- [ ] PRD, TRD, Technical Design, Implementation Plan included in submission
- [ ] Before/After screenshot showing database state change
- [ ] Agent trace logs exported as text file

---

**End of Implementation Plan**
