# Jaizaa — Product Requirements Document (PRD)

**Version:** 1.0  
**App Name:** Jaizaa (جائزہ)  
**Document Type:** Product Requirements Document  
**Scope:** Hackathon MVP — Google Antigravity Challenge 1  
**Status:** Final — Implementation Ready

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Problem Statement](#2-problem-statement)
3. [Goals & Success Criteria](#3-goals--success-criteria)
4. [Users](#4-users)
5. [Scope](#5-scope)
6. [Phase Breakdown](#6-phase-breakdown)
7. [Functional Requirements — Phase 1](#7-functional-requirements--phase-1)
8. [Functional Requirements — Phase 2](#8-functional-requirements--phase-2)
9. [Functional Requirements — Phase 3](#9-functional-requirements--phase-3)
10. [Functional Requirements — Phase 4](#10-functional-requirements--phase-4)
11. [Non-Functional Requirements](#11-non-functional-requirements)
12. [The Four Actions — Exact Behaviour](#12-the-four-actions--exact-behaviour)
13. [Screen Inventory](#13-screen-inventory)
14. [Demo Scenario](#14-demo-scenario)
15. [Evaluation Criteria Mapping](#15-evaluation-criteria-mapping)
16. [Out of Scope](#16-out-of-scope)

---

## 1. Product Overview

**Jaizaa** is an Android app for doctors and clinic staff in Pakistan.

A doctor uploads a patient's lab report — PDF or phone camera photo. The app reads it using a 6-agent AI pipeline, identifies critical clinical patterns, and automatically executes four care actions entirely within the app:

- Books a follow-up appointment (stored in Neon Postgres)
- Shows an in-app doctor alert
- Displays a simulated patient notification card in the UI
- Updates the patient's App Record (Jaizaa's own database — not any external EMR)

The entire pipeline completes in under 60 seconds. The reasoning of every agent is visible to the doctor and to hackathon judges via a Logs tab.

**Tagline:** Lab report upload karo. Clinical decision khud aa jayega.

---

## 2. Problem Statement

A doctor in a private Pakistani clinic reviews 40–60 lab reports daily — manually. Each takes 3–5 minutes to read, interpret, and act on.

**Three failure modes occur daily:**

1. **Critical values missed** — A dangerous combination (e.g., HbA1c 11.2 + elevated Creatinine) goes unnoticed because no system flags multi-value patterns, only individual out-of-range markers.
2. **Follow-ups forgotten** — After discharge or a clinic visit, no automated mechanism ensures the patient returns. Patients deteriorate silently.
3. **Doctors have no action layer** — Every existing lab tool in Pakistan displays results. None take action on them.

---

## 3. Goals & Success Criteria

### Hackathon Goal
Deliver a working Android prototype that demonstrates the full loop:

```
Unstructured Input → Insight → Impact → Action → Simulation → Result
```

### Success Criteria

| Criterion | Target |
|---|---|
| Report to action completion time | Under 60 seconds |
| Agent pipeline visibility | All 6 agents shown live on Processing Screen |
| Neon Postgres state change | All 4 tables written and verifiable after demo |
| Before/After state | Clearly shown on dedicated screen |
| Agent trace for judges | Full trace visible in Logs tab |
| Zero scope contradictions | Document and app are fully consistent |

---

## 4. Users

### Primary User — Doctor / Clinic Staff

| Attribute | Detail |
|---|---|
| Role | GP, diabetologist, internist, or clinic nurse/coordinator |
| Location | Karachi, Lahore — private clinics |
| Volume | 30–60 patients per day |
| Pain | Manually reading lab reports, missing critical values, forgetting follow-ups |
| Goal | Upload a report and let the system decide and act |
| Technical level | Comfortable with smartphone apps — not a developer |

### Secondary Stakeholder — Patient

The patient is **not** a Jaizaa app user. The patient is the **recipient** of a generated WhatsApp notification card displayed in the app. No patient login. No patient-facing screen. The doctor sees the generated message and can copy it manually.

---

## 5. Scope

### In Scope — This Hackathon MVP

- Lab reports only: CBC, LFTs, RFTs, HbA1c, lipid profile, electrolytes
- Input formats: PDF upload or phone camera photo
- Primary user: doctor or clinic staff
- All four actions execute within the app — no external API calls for delivery
- All actions persist real rows in Neon Postgres (verified state changes)
- Single primary demo scenario

### Out of Scope — Future Versions

- Radiology or cardiology reports (X-ray, ECG, MRI, ultrasound)
- Patient-facing login or patient app
- Live WhatsApp / SMS delivery via external API
- Live email delivery via external email service
- Integration with any external EMR or EHR system
- Multi-clinic accounts or doctor team management
- Billing, insurance, or prescription modules

> **Rule:** Anything listed as Out of Scope must not appear in any screen, flow, or data model within this MVP.

---

## 6. Phase Breakdown

The app is divided into four phases. Each phase is independently buildable and testable inside Google Antigravity. A phase must pass its own acceptance criteria before the next phase begins.

```
Phase 1 — Foundation         (Database + Backend + Auth skeleton)
Phase 2 — Agent Pipeline     (6 agents: reading → analysis → planning)
Phase 3 — Execution Layer    (4 actions + Neon Postgres writes)
Phase 4 — Flutter UI         (All screens + Before/After + Logs tab)
```

**Why phases matter for a 1-day build:**
- Each phase produces a working, testable output
- If time runs short, Phases 1–3 are the demo backbone — Phase 4 can be simplified
- Bugs are caught per phase, not discovered during demo
- Google Antigravity Manager View runs Phase 1 and Phase 2 agents in parallel

---

## 7. Functional Requirements — Phase 1

### Phase 1: Foundation — Database + Backend Skeleton

**Goal:** Neon Postgres is live, all four tables exist, and FastAPI is running with empty endpoints.

**Acceptance Criteria:**
- Neon Postgres connected and accessible from FastAPI
- All four tables created with correct schema
- FastAPI running on Railway/Render, returning 200 on health check
- All four endpoints exist (even if they return placeholder responses)

---

### FR-1.1 — Database Setup (Neon Postgres)

Create four tables with the following schema.

**Table: `patients`**

| Column | Type | Notes |
|---|---|---|
| `patient_id` | UUID, PK | Auto-generated |
| `name` | TEXT | Patient full name |
| `phone` | TEXT | For notification card generation |
| `risk_level` | TEXT | Default: `UNKNOWN`. Values: UNKNOWN / LOW / MEDIUM / HIGH / CRITICAL |
| `follow_up_status` | TEXT | Default: `NONE`. Values: NONE / SCHEDULED / COMPLETED |
| `care_gap` | TEXT | Default: `OPEN`. Values: OPEN / CLOSED |
| `last_analyzed_at` | TIMESTAMP | Null until first analysis |

**Table: `appointments`**

| Column | Type | Notes |
|---|---|---|
| `appointment_id` | UUID, PK | Auto-generated |
| `patient_id` | UUID, FK → patients | |
| `doctor_id` | TEXT | Hardcoded for MVP: `doctor_001` |
| `specialty` | TEXT | e.g., Nephrology, Cardiology |
| `scheduled_slot` | TEXT | Simulated: e.g., "Tomorrow 10:00 AM" |
| `status` | TEXT | Fixed: `CONFIRMED` |
| `created_at` | TIMESTAMP | Auto |

**Table: `alerts`**

| Column | Type | Notes |
|---|---|---|
| `alert_id` | UUID, PK | Auto-generated |
| `recipient_doctor_id` | TEXT | Hardcoded for MVP: `doctor_001` |
| `patient_id` | UUID, FK → patients | |
| `flagged_values` | JSONB | e.g., `{"HbA1c": 11.2, "Creatinine": 2.4}` |
| `clinical_pattern` | TEXT | e.g., "Early diabetic nephropathy pattern" |
| `urgency_level` | TEXT | URGENT / HIGH / MEDIUM |
| `status` | TEXT | Fixed: `UNREAD` |
| `created_at` | TIMESTAMP | Auto |

**Table: `notifications`**

| Column | Type | Notes |
|---|---|---|
| `notification_id` | UUID, PK | Auto-generated |
| `patient_id` | UUID, FK → patients | |
| `channel` | TEXT | Fixed: `WhatsApp` |
| `message_text` | TEXT | Full message generated by Agent 5 |
| `status` | TEXT | Fixed: `GENERATED` |
| `created_at` | TIMESTAMP | Auto |

---

### FR-1.2 — FastAPI Endpoints (Skeleton)

All four endpoints must exist in Phase 1, even if logic is not yet wired. The agent pipeline (Phase 2–3) will fill in the logic.

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/health` | Returns `{"status": "ok"}` |
| POST | `/analyze` | Receives file upload, triggers agent pipeline |
| POST | `/appointments` | Creates appointment row |
| POST | `/alerts` | Creates alert row |
| POST | `/notifications` | Creates notification row |
| PATCH | `/patients/{patient_id}` | Updates patient App Record |
| GET | `/patients` | Returns all patients sorted by risk_level |
| GET | `/patients/{patient_id}` | Returns single patient with all related records |

---

## 8. Functional Requirements — Phase 2

### Phase 2: Agent Pipeline — Document Reading → Clinical Analysis → Action Planning

**Goal:** The 6-agent pipeline runs end-to-end and returns a structured JSON action plan. No database writes yet — that is Phase 3.

**Acceptance Criteria:**
- Upload a PDF → receive structured JSON with extracted values, risk score, and action plan
- Upload a camera photo → same output
- Agent trace log produced (list of agent name + reasoning + output per step)
- Pipeline completes in under 45 seconds

---

### FR-2.1 — Agent 1: Document Reader

**Input:** PDF file or image file  
**Output:** Structured JSON of all extracted lab values

```json
{
  "patient_name": "Ahmed Khan",
  "report_date": "2026-05-18",
  "values": {
    "HbA1c": 11.2,
    "Creatinine": 2.4,
    "Hemoglobin": 10.1,
    "WBC": 9800,
    "Platelets": 210000
  },
  "extraction_method": "pdf_parser"
}
```

**Rules:**
- PDF → use PyMuPDF text extraction
- Image/photo → use GPT-4o Vision
- If a value cannot be extracted, set it to `null` — do not hallucinate values
- Agent must log what it extracted and from which method

---

### FR-2.2 — Agent 2: Clinical Analyzer

**Input:** JSON from Agent 1  
**Output:** List of findings with clinical pattern identification

```json
{
  "findings": [
    {
      "values_involved": ["HbA1c", "Creatinine"],
      "pattern": "Early diabetic nephropathy pattern",
      "explanation": "HbA1c of 11.2 indicates severely uncontrolled diabetes. Creatinine of 2.4 indicates reduced kidney filtration. Together this combination strongly suggests early diabetic nephropathy.",
      "confidence": 0.94
    },
    {
      "values_involved": ["Hemoglobin"],
      "pattern": "Mild anemia — likely chronic disease anemia",
      "explanation": "Hemoglobin 10.1 is below normal range (12–17 g/dL). In context of diabetic nephropathy, this is consistent with anemia of chronic kidney disease.",
      "confidence": 0.78
    }
  ]
}
```

**Rules:**
- Must detect multi-value patterns, not only single out-of-range values
- Must provide a human-readable clinical explanation per finding
- Confidence score must be between 0.0 and 1.0
- Agent must log each pattern it evaluated (including ones it ruled out)

---

### FR-2.3 — Agent 3: Risk Assessor

**Input:** Findings JSON from Agent 2  
**Output:** Overall risk score + per-finding consequence mapping

```json
{
  "overall_risk": "HIGH",
  "risk_reasoning": "Patient has two concurrent findings — early nephropathy pattern with high confidence and anemia of chronic disease. Combined clinical trajectory without intervention leads to renal failure within 6–12 months.",
  "consequences": [
    {
      "pattern": "Early diabetic nephropathy pattern",
      "consequence": "Progressive renal failure risk — GFR likely declining",
      "urgency": "URGENT"
    },
    {
      "pattern": "Mild anemia",
      "consequence": "Fatigue, reduced oxygen delivery — manageable but requires monitoring",
      "urgency": "MEDIUM"
    }
  ]
}
```

**Rules:**
- Risk levels: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`
- Must justify the overall risk level in `risk_reasoning`
- Urgency per consequence must be `URGENT` / `HIGH` / `MEDIUM` / `ROUTINE`

---

### FR-2.4 — Agent 4: Action Planner

**Input:** Risk assessment JSON from Agent 3  
**Output:** Structured action plan with four actions

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
      "message": "Ahmed Khan — HbA1c 11.2 + Creatinine 2.4 — Early diabetic nephropathy — Review required"
    },
    {
      "action_type": "notification",
      "priority": "HIGH",
      "channel": "WhatsApp",
      "message_text": "Assalam o Alaikum Ahmed sahab, aapke lab results mein kuch zaroori findings hain. Kal subah 10 baje Nephrology department mein appointment book ho gayi hai. Meherbani karke waqt par aa jayen. — Clinic"
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

**Rules:**
- All four action types must always be present in the plan
- Priority order in the plan: URGENT first, then HIGH, then ROUTINE
- Notification message must be in Urdu or bilingual (Urdu + English)
- Agent must log the reasoning behind each action

---

### FR-2.5 — Agent 5: Execution Agent

**Handled in Phase 3.** In Phase 2, Agent 5 only needs to confirm it received the action plan — no writes yet.

---

### FR-2.6 — Agent 6: Outcome Reporter

**Input:** Action plan from Agent 4 + patient's current state from `patients` table  
**Output:** Before/After comparison object + full agent trace log

```json
{
  "before": {
    "risk_level": "UNKNOWN",
    "follow_up_status": "NONE",
    "care_gap": "OPEN",
    "doctor_awareness": "UNAWARE"
  },
  "after": {
    "risk_level": "HIGH",
    "follow_up_status": "SCHEDULED",
    "care_gap": "CLOSED",
    "doctor_awareness": "ALERTED"
  },
  "agent_trace": [
    {"agent": "Document Reader", "status": "DONE", "key_output": "Extracted 8 lab values via PDF parser"},
    {"agent": "Clinical Analyzer", "status": "DONE", "key_output": "2 patterns detected — nephropathy (94%), anemia (78%)"},
    {"agent": "Risk Assessor", "status": "DONE", "key_output": "Overall risk: HIGH — renal failure trajectory"},
    {"agent": "Action Planner", "status": "DONE", "key_output": "4 actions planned — 1 URGENT, 2 HIGH, 1 ROUTINE"},
    {"agent": "Execution Agent", "status": "DONE", "key_output": "4 rows written to Neon Postgres"},
    {"agent": "Outcome Reporter", "status": "DONE", "key_output": "Before/After generated — 4 fields changed"}
  ]
}
```

---

## 9. Functional Requirements — Phase 3

### Phase 3: Execution Layer — Neon Postgres Writes

**Goal:** Agent 5 is fully wired. Every action in the action plan triggers a real database write via FastAPI. The Before/After state is verifiable.

**Acceptance Criteria:**
- Tapping "Execute All" triggers Agent 5
- Agent 5 calls all four FastAPI endpoints sequentially
- All four Neon Postgres tables are updated with real rows
- Each action returns a success confirmation to the Flutter UI
- Before demo: tables empty / patient in UNKNOWN state
- After demo: all tables written — verifiable in Neon dashboard

---

### FR-3.1 — Action 1: Follow-Up Appointment Booking

**Trigger:** Agent 5 calls `POST /appointments`

**FastAPI behaviour:**
1. Receive appointment payload from Agent 5
2. Insert one row into `appointments` table
3. Return `{"status": "CONFIRMED", "appointment_id": "<uuid>", "slot": "Tomorrow 10:00 AM"}`

**What the app shows:**
A green confirmation card: *"Nephrology referral booked — Tomorrow 10:00 AM ✓"*

**There is no real calendar or scheduling system.** The slot is a simulated string generated by Agent 4.

---

### FR-3.2 — Action 2: In-App Doctor Alert

**Trigger:** Agent 5 calls `POST /alerts`

**FastAPI behaviour:**
1. Receive alert payload from Agent 5
2. Insert one row into `alerts` table with `status = UNREAD`
3. Return `{"status": "UNREAD", "alert_id": "<uuid>"}`

**What the app shows:**
- On the Execution Screen: a red alert confirmation card — *"Doctor alert created — Ahmed Khan — HbA1c 11.2 + Creatinine 2.4 ✓"*
- On the Home Dashboard: the new alert appears under "Active Alerts" immediately after execution

**There is no external email or push notification.** The alert is an in-app record only.

---

### FR-3.3 — Action 3: Patient Notification Card

**Trigger:** Agent 5 calls `POST /notifications`

**FastAPI behaviour:**
1. Receive notification payload from Agent 5
2. Insert one row into `notifications` table with `status = GENERATED`
3. Return `{"status": "GENERATED", "notification_id": "<uuid>", "message_text": "<full_message>"}`

**What the app shows:**
A simulated WhatsApp-style notification card rendered in the app UI:

```
┌─────────────────────────────────────────┐
│  📱 Patient WhatsApp Message — GENERATED │
│                                         │
│  Assalam o Alaikum Ahmed sahab,         │
│  aapke lab results mein kuch zaroori    │
│  findings hain. Kal subah 10 baje       │
│  Nephrology mein appointment book ho    │
│  gayi hai. Waqt par aa jayen. — Clinic  │
│                                         │
│  [ Copy Message ]                       │
└─────────────────────────────────────────┘
```

**There is no real WhatsApp or SMS API call.** The message is generated, stored, and displayed in the app. The doctor can copy it manually. `status = GENERATED` (not SENT).

---

### FR-3.4 — Action 4: App Record Update

**Trigger:** Agent 5 calls `PATCH /patients/{patient_id}`

**FastAPI behaviour:**
1. Receive updated fields from Agent 5
2. Update the patient row in `patients` table:
   - `risk_level` → HIGH (or CRITICAL, from Agent 3 output)
   - `follow_up_status` → SCHEDULED
   - `care_gap` → CLOSED
   - `last_analyzed_at` → current timestamp
3. Return updated patient object

**What the app shows:**
A confirmation card: *"App Record updated — Risk: HIGH, Follow-up: SCHEDULED, Care Gap: CLOSED ✓"*

**Important naming rule:** This is always called "App Record Update" in all UI labels, screen titles, and documentation. Never "EMR update" or "EHR update." Jaizaa has no connection to any external medical record system.

---

## 10. Functional Requirements — Phase 4

### Phase 4: Flutter UI — All Screens

**Goal:** All 9 screens are built and wired to the FastAPI backend. The app is demo-ready.

**Acceptance Criteria:**
- Doctor can upload a report and see the full flow end-to-end on device
- All 4 action confirmation cards render correctly
- Before/After screen is correct
- Logs tab shows full agent trace
- Patient List sorts by risk_level correctly
- App does not crash during the demo scenario

---

### FR-4.1 — Screen 1: Home Dashboard

**Purpose:** Entry point. Shows current state at a glance.

**Elements:**
- Header: "Jaizaa" app name + current date
- Stats row: Today's reports analyzed / Active alerts / Actions taken today
- "Analyze New Report" button — large, full-width, prominent
- Active Alerts section — shows latest unread alert cards (from `alerts` table, `status = UNREAD`)
- Recent Patients section — last 5 analyzed patients with risk badge

---

### FR-4.2 — Screen 2: Upload Screen

**Purpose:** Doctor selects the report file and patient.

**Elements:**
- Upload PDF button (opens file picker)
- Take Photo button (opens camera)
- Patient selector: dropdown of existing patients from `patients` table + "New Patient" option
- "New Patient" option shows a minimal form: Name + Phone only
- "Analyze" button (disabled until file + patient are both selected)

---

### FR-4.3 — Screen 3: Processing Screen

**Purpose:** Shows the 6-agent pipeline running live.

**Elements:**
- Title: "Analyzing Report..."
- Agent list — 6 rows, each showing:
  - Agent number + name
  - Status badge: PENDING → RUNNING → DONE
  - One-line summary of what the agent found (appears when status = DONE)
- Live log feed below the agent list — scrollable, real-time text output
- Progress bar (0–100%) across top
- This screen must not be skippable — it is the primary evidence of agentic reasoning

**Behaviour:**
- Agents run sequentially: Agent 1 starts, finishes, then Agent 2 starts, etc.
- Each agent status updates as it transitions
- When Agent 6 completes, automatically navigate to Results Screen

---

### FR-4.4 — Screen 4: Results Screen (3 Tabs)

**Purpose:** Shows the full output of the pipeline before execution.

**Tab A — Insights**

- Patient name + risk badge (CRITICAL / HIGH / MEDIUM / LOW) at top
- Each finding displayed as a card:
  - Values involved (e.g., "HbA1c 11.2 + Creatinine 2.4")
  - Pattern name (e.g., "Early diabetic nephropathy pattern")
  - Clinical explanation
  - Confidence percentage bar

**Tab B — Actions**

- Four action cards listed by priority (URGENT first)
- Each card shows:
  - Action type icon + label (Appointment / Alert / Notification / App Record)
  - Priority badge
  - One-line description of what will happen
- "Execute All" button — full-width, red, at the bottom
- Tapping "Execute All" navigates to Execution Screen and triggers Agent 5

**Tab C — Logs**

- Full agent trace from Agent 6's output
- Each entry shows: Agent name / Status / Key output / Timestamp
- This tab is for judges to verify agentic workflow
- Scrollable, monospace-style font for log readability

---

### FR-4.5 — Screen 5: Execution Screen

**Purpose:** Shows each of the 4 actions completing in real time.

**Behaviour:**
- Actions execute one by one (not all at once)
- Each action shows a loading state, then a confirmation card when the Neon Postgres write succeeds
- Order: Appointment → Alert → Notification → App Record Update
- After all 4 complete, a "View Results" button appears
- Tapping "View Results" navigates to the Before/After Screen

**Confirmation card format per action:**

```
[✓ green icon]  [Action label]
[One-line confirmation message]
[Timestamp]
```

---

### FR-4.6 — Screen 6: Before / After Screen

**Purpose:** Shows the verified state change — the proof that the system worked.

**Elements:**
- Title: "Patient State — Before & After"
- Side-by-side table (or stacked on small screens):

| Field | Before | After |
|---|---|---|
| Risk Level | UNKNOWN 🔴 | HIGH 🟠 |
| Follow-up Status | NONE 🔴 | SCHEDULED 🟢 |
| Care Gap | OPEN 🔴 | CLOSED 🟢 |
| Doctor Awareness | UNAWARE 🔴 | ALERTED 🟢 |

- Summary line: "4 fields changed. 4 database rows written."
- "Back to Home" button

---

### FR-4.7 — Screen 7: Patient List

**Purpose:** View all analyzed patients sorted by urgency.

**Elements:**
- List of all patients from `patients` table
- Sorted by: CRITICAL → HIGH → MEDIUM → LOW → UNKNOWN
- Each row shows: Patient name / Risk badge / Follow-up status / Last analyzed timestamp
- Tapping a patient opens their most recent analysis results

---

## 11. Non-Functional Requirements

| Requirement | Specification |
|---|---|
| Target platform | Android (Flutter) — minimum SDK 21 (Android 5.0) |
| Agent pipeline latency | Under 60 seconds end-to-end (upload to action plan ready) |
| API response time | Under 3 seconds per FastAPI endpoint call |
| Database | Neon Postgres — cloud hosted, accessible from both FastAPI and direct query tool |
| Offline behaviour | App shows an error screen if backend is unreachable — no offline mode |
| File size limits | PDF max 10MB. Image max 5MB. |
| Supported input types | `.pdf`, `.jpg`, `.jpeg`, `.png` |
| Error handling | If any agent fails, show the agent name + error message on Processing Screen. Do not crash. |
| Demo stability | App must run the primary demo scenario without crash or hang at least 3 times consecutively |

---

## 12. The Four Actions — Exact Behaviour

This section is the single source of truth for how each action works. No other section overrides this.

| # | Action Name | UI Label | DB Write | External API | App Shows |
|---|---|---|---|---|---|
| 1 | Follow-Up Appointment | "Appointment Booked" | `appointments` table — 1 row | None | Green confirmation card with slot time |
| 2 | Doctor Alert | "Doctor Alerted" | `alerts` table — 1 row | None (in-app only) | Red alert card on Execution Screen + Home Dashboard |
| 3 | Patient Notification | "Notification Generated" | `notifications` table — 1 row | None (no WhatsApp API) | Simulated WhatsApp card in app UI with Copy button |
| 4 | App Record Update | "App Record Updated" | `patients` table — PATCH | None | Confirmation card + Before/After screen |

**Naming rule — strictly enforced:**
- Action 4 is always "App Record Update" — never "EMR update," never "EHR update"
- Action 3 status in DB is always `GENERATED` — never `SENT`
- Action 2 is always "in-app alert" — never "email alert" or "push notification"

---

## 13. Screen Inventory

| # | Screen Name | Phase | Trigger |
|---|---|---|---|
| 1 | Home Dashboard | Phase 4 | App launch |
| 2 | Upload Screen | Phase 4 | Tap "Analyze New Report" |
| 3 | Processing Screen | Phase 4 | Tap "Analyze" |
| 4 | Results Screen (3 tabs) | Phase 4 | Agent 6 completes |
| 5 | Execution Screen | Phase 4 | Tap "Execute All" |
| 6 | Before / After Screen | Phase 4 | All 4 actions complete |
| 7 | Patient List | Phase 4 | Tap "Patients" in nav |

Total screens: 7 (the Results Screen counts as 1 screen with 3 tabs).

---

## 14. Demo Scenario

**Persona:** Dr. Ayesha — resident doctor, private clinic, Karachi  
**Time:** 11 PM. 60 lab reports pending.  
**Patient:** Ahmed Khan

| Step | What Happens | Screen Shown |
|---|---|---|
| 1 | Dr. Ayesha opens Jaizaa | Home Dashboard |
| 2 | Taps "Analyze New Report" | Upload Screen |
| 3 | Uploads Ahmed's PDF (CBC + RFTs + HbA1c). Selects "Ahmed Khan" | Upload Screen |
| 4 | Taps "Analyze" | Processing Screen |
| 5 | 6 agents run sequentially — each shows status + key finding | Processing Screen |
| 6 | Agent 6 completes — navigates to Results Screen | Results Screen |
| 7 | Insights tab: "HbA1c 11.2 + Creatinine 2.4 — Early diabetic nephropathy — HIGH — 94%" | Results — Insights tab |
| 8 | Actions tab: 4 action cards — Nephrology referral (URGENT), Doctor alert (HIGH), Notification (HIGH), App Record (ROUTINE) | Results — Actions tab |
| 9 | Taps "Execute All" | Execution Screen |
| 10 | 4 confirmation cards appear one by one as DB writes complete | Execution Screen |
| 11 | Taps "View Results" | Before/After Screen |
| 12 | Before: UNKNOWN / NONE / OPEN / UNAWARE → After: HIGH / SCHEDULED / CLOSED / ALERTED | Before/After Screen |

**Total time:** Under 60 seconds from upload to Before/After screen.  
**Manual equivalent:** 20–25 minutes.

---

## 15. Evaluation Criteria Mapping

| Criteria | Weight | Requirement That Satisfies It |
|---|---|---|
| Google Antigravity Use | 25% | Entire app built in Antigravity. Manager View spawns parallel build agents. Antigravity Artifacts = required workplan + agent trace logs for judges. |
| Agentic Reasoning & Workflow | 20% | FR-2.1 through FR-2.6 — 6 agents with defined input/output contracts. Processing Screen shows live reasoning. Logs tab shows full trace. |
| Insight & Decision Quality | 20% | FR-2.2 — multi-value clinical pattern detection (not just out-of-range flags). Explanation + confidence per finding. |
| Action Simulation & Outcome | 15% | FR-3.1 through FR-3.4 — 4 real Neon Postgres writes. FR-4.6 — verified Before/After screen. |
| Technical Implementation | 10% | Phase separation. Clean API contracts. FastAPI + Flutter + Neon Postgres. |
| Innovation & UX | 10% | Pakistan-specific healthcare problem. BSN founder. Urdu notification text. Emotionally compelling demo narrative. |

---

## 16. Out of Scope

The following must not appear anywhere in the app — not in screens, not in data models, not in agent prompts:

- External EMR / EHR system of any kind
- Real WhatsApp API or Twilio SMS
- Real email delivery
- Patient login or patient-facing screens
- X-ray, MRI, ECG, or ultrasound report processing
- Multi-doctor or multi-clinic features
- Billing, insurance, or prescription handling

---

*Document version: 1.0 — Final. Any change to scope, action behaviour, or screen requirements must be reflected in both the PRD and TRD simultaneously.*
