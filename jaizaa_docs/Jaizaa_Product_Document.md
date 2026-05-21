PRODUCT DOCUMENT

**Jaiza**

جائزہ

*Lab report upload karo. Clinical decision khud aa jayega.*

| **Platform** Android (Flutter) | **Backend** Python FastAPI |
| --- | --- |
| **AI Layer** OpenAI Agents SDK | **IDE / Build Platform** Google Antigravity |
| **Database** Neon Postgres (cloud) | **Stage** Hackathon MVP |

Google Antigravity Hackathon — Challenge 1

Autonomous Content-to-Action Agent

# **1. What is Jaiza?**

Jaiza (جائزہ) means clinical review or evaluation in Urdu — a name that is meaningful, easy to recall, and directly reflects what the app does.

Jaiza is an Android app for doctors and clinic staff in Pakistan. A doctor uploads a patient's lab report — PDF or phone camera photo. The app reads it, identifies critical clinical patterns, and automatically executes four care actions: booking a follow-up appointment, generating a doctor alert, creating a patient WhatsApp message, and updating the patient's record in the app's own database.

The entire pipeline runs through 6 AI agents built with the OpenAI Agents SDK and developed inside Google Antigravity. Every agent has one job. Together they go from raw report to real action in under 60 seconds.

# **2. Google Antigravity — Role in This Project**

| **Important Clarification** Google Antigravity is NOT a runtime agent orchestration platform. It is Google's agent-first IDE — a VS Code fork released November 2025. The OpenAI Agents SDK handles runtime orchestration of the 6 clinical agents inside the app. |
| --- |

## **Two Views in Antigravity**

| **View** | **What It Does** | **How Jaiza Uses It** |
| --- | --- | --- |
| Editor View | Standard code editor with AI agent sidebar — similar to Cursor | Writing Flutter screens, FastAPI endpoints, and agent code with AI assistance |
| Manager View | Mission control dashboard — spawn multiple agents working in parallel across different tasks | One agent builds the FastAPI backend, one writes Flutter UI, one sets up Neon Postgres schema — simultaneously |

Antigravity generates Artifacts — task plans, execution logs, and verification records — for every agent task. These Artifacts serve as the agent trace and workplan logs required by the hackathon judges.

Summary: Antigravity = development environment and build platform. OpenAI Agents SDK = runtime orchestration of the 6 clinical agents.

# **3. The Problem**

A doctor in a private Pakistani clinic reviews 40–60 lab reports daily — manually. Each report takes 3–5 minutes to read, interpret, and act on. Critical patterns get missed. Follow-ups are forgotten. Patients deteriorate silently between visits.

No tool in Pakistan reads a lab report and takes action. Existing tools only display results.

# **4. Scope**

## **In Scope — Hackathon MVP**

- Lab reports only: CBC, LFTs, RFTs, HbA1c, lipid profile, electrolytes

- PDF upload or phone camera photo

- Doctor / clinic staff as the primary app user

- Patient as recipient of a generated WhatsApp message text — not an app user, no login

- All four actions write real rows to Neon Postgres — verified state changes, not animation

- Single demo scenario (Scenario 1)

## **Out of Scope — Future Versions**

- Ultrasound, X-ray, MRI, ECG reports

- Patient-facing login or patient app

- Real WhatsApp or SMS API delivery — message text is generated and stored, not sent live

- Real email delivery — alert is generated and stored, not sent via live email service

- Integration with any external EMR or EHR system

- Multi-clinic or multi-doctor accounts

# **5. Primary User**

| **Attribute** | **Detail** |
| --- | --- |
| Who | Private practice doctor or clinic staff — GP, diabetologist, internist |
| Where | Karachi, Lahore — private clinics seeing 30+ patients per day |
| Pain | Manually reading lab reports, missing critical values, forgetting follow-ups |
| Goal | Upload a report and let the system tell them what to do next — and do it |

# **6. The 6-Agent Pipeline**

Each agent has one job. Agents are built with OpenAI Agents SDK. The sequence is a linear pipeline triggered on report upload.

| **#** | **Agent** | **Job** |
| --- | --- | --- |
| **01** | **Document Reader** | Extracts all lab values from the uploaded file into structured JSON. Uses vision model for camera photos and PDF parser for PDFs. |
| **02** | **Clinical Analyzer** | Identifies abnormal values and dangerous clinical combinations — pattern detection across multiple values, not just individual flags. Example: HbA1c 11.2 + Creatinine 2.4 = early diabetic nephropathy. |
| **03** | **Risk Assessor** | Scores overall patient risk: CRITICAL / HIGH / MEDIUM / LOW. Maps each finding to a real-world clinical consequence with explanation. |
| **04** | **Action Planner** | Decides which of the four actions to take, in what priority, directed at whom. Outputs a structured action plan. |
| **05** | **Execution Agent** | Calls FastAPI endpoints and writes all four action rows to Neon Postgres in real time. Each write is a verified state change. |
| **06** | **Outcome Reporter** | Generates the before vs after patient state. Produces the full agent trace log for the Logs tab and judges. |

# **7. The Four Actions — Execution Flow**

When the doctor taps Execute All, Agent 5 calls four FastAPI endpoints and writes four rows to Neon Postgres. Below is the exact execution flow for each action.

**Action 1 — Follow-Up Appointment Booking**

**What it does:** Creates a follow-up appointment record for the patient inside Jaiza's database

**Endpoint called:** POST /appointments

**Neon Postgres write:** Table: appointments | Fields: patient_id, doctor_id, specialty, scheduled_slot, status = CONFIRMED, created_at

**App shows:** Confirmation card: "Nephrology referral booked — Tomorrow 10:00 AM"

**Action 2 — Doctor Alert**

**What it does:** Generates an in-app alert for the treating doctor flagging critical values

**Endpoint called:** POST /alerts

**Neon Postgres write:** Table: alerts | Fields: recipient_doctor_id, patient_id, flagged_values (JSON), clinical_pattern, urgency_level, status = UNREAD, created_at

**App shows:** Red alert card on the Home Dashboard: "Ahmed Khan — HbA1c 11.2 + Creatinine 2.4 — Review required"

**Action 3 — Patient WhatsApp Message**

**What it does:** Generates a WhatsApp message text to notify the patient of their follow-up

**Endpoint called:** POST /notifications

**Neon Postgres write:** Table: notifications | Fields: patient_id, channel = WhatsApp, message_text (Urdu/English), status = GENERATED, created_at

**Note:** No live WhatsApp API is called. Message text is stored and displayed in the app with a Copy Message button. Real delivery is out of scope.

**App shows:** Message preview card with the full text the patient would receive

**Action 4 — Patient Record Update**

**What it does:** Updates the patient's record inside Jaiza's own Neon Postgres database — risk level, follow-up status, care gap flag

**Endpoint called:** PATCH /patients/{patient_id}

**Neon Postgres write:** Table: patients | Updated fields: risk_level, follow_up_status, care_gap, last_analyzed_at

**Note:** This is Jaiza's internal patient record only. No connection to any external EMR or EHR system — that is out of scope.

**App shows:** Before/After table showing all four fields flipped from red to green

# **8. Core App Screens**

| **Screen** | **What It Shows** |
| --- | --- |
| 1. Home Dashboard | Today's report count, active unread alerts, recent actions. One large Analyze New Report button. Patients sorted by risk level. |
| 2. Upload Screen | PDF upload or camera photo. Select existing patient or create new. Tap Analyze. |
| 3. Processing Screen | 6 agents running live — name, status (Running / Done), and live log feed. Runs 15–25 seconds. Makes AI reasoning visible. |
| 4. Results — Insights Tab | Abnormal values with detected clinical pattern. Example: HbA1c 11.2 + Creatinine 2.4 — Diabetic nephropathy — HIGH — 94% confidence. |
| 5. Results — Actions Tab | Four recommended actions listed by priority: URGENT / HIGH / ROUTINE. One Execute All button. |
| 6. Results — Logs Tab | Full agent trace — each agent's input, reasoning, and output. For judges to verify agentic workflow. |
| 7. Execution Screen | Four action confirmation cards appearing live as each Neon Postgres write completes. |
| 8. Before / After Screen | Side-by-side table: patient state before analysis vs after execution. Risk level, follow-up status, care gap, doctor awareness. |
| 9. Patient List | All analyzed patients sorted by risk level. HIGH and CRITICAL patients shown first with pending badges. |

# **9. Demo Scenario**

| **Primary Demo** **Who:** Dr. Ayesha, resident doctor, private clinic Karachi **Situation:** 11 PM. 60 lab reports pending. Ahmed Khan's labs just arrived. |
| --- |

| **Step** | **What Happens** |
| --- | --- |
| 1 | Dr. Ayesha opens Jaiza, taps Analyze New Report |
| 2 | Uploads Ahmed's PDF — CBC + RFTs + HbA1c |
| 3 | Processing Screen: 6 agents run sequentially with live logs |
| 4 | Insights tab: HbA1c 11.2 + Creatinine 2.4 — Early diabetic nephropathy — HIGH RISK — 94% confidence |
| 5 | Actions tab: Nephrology referral (URGENT), Doctor alert (HIGH), Patient WhatsApp message (HIGH), Record update (ROUTINE) |
| 6 | Dr. Ayesha taps Execute All |
| 7 | Four confirmation cards appear as each Neon Postgres write completes |
| 8 | Before/After: Risk UNKNOWN → HIGH. Follow-up NONE → SCHEDULED. Care gap OPEN → CLOSED. |
| 9 | Total time: under 60 seconds. Manual equivalent: 20–25 minutes. |

# **10. Database Schema — Neon Postgres**

Four tables. All writes happen via FastAPI. All are verified in real time.

| **Table** | **Key Fields** |
| --- | --- |
| patients | patient_id, name, phone, risk_level, follow_up_status, care_gap, last_analyzed_at |
| appointments | appointment_id, patient_id, doctor_id, specialty, scheduled_slot, status, created_at |
| alerts | alert_id, recipient_doctor_id, patient_id, flagged_values (JSON), clinical_pattern, urgency_level, status, created_at |
| notifications | notification_id, patient_id, channel, message_text, status, created_at |

| **Demo State** **Before demo:** appointments, alerts, and notifications tables are empty. patients row shows risk_level = UNKNOWN. **After demo:** all four tables updated — visible and verifiable in Neon dashboard. |
| --- |

# **11. Challenge 1 — Evaluation Criteria Mapping**

| **Criteria** | **Weight** | **How Jaiza Satisfies It** |
| --- | --- | --- |
| Google Antigravity Use | 25% | Entire app built inside Antigravity. Manager View runs parallel build agents. Antigravity Artifacts serve as the required agent trace and workplan logs for judges. |
| Agentic Reasoning & Workflow | 20% | 6 sequential clinical agents with defined inputs and outputs. Full reasoning trace shown in the Logs tab for judge verification. |
| Insight & Decision Quality | 20% | Clinical pattern detection — not individual value flags. Combinations like HbA1c + Creatinine mapped to nephropathy represent non-trivial clinical reasoning. |
| Action Simulation & Outcome | 15% | 4 real Neon Postgres writes per analysis. Before/After dashboard shows actual verified state change — not animation. |
| Technical Implementation | 10% | Flutter + FastAPI + OpenAI Agents SDK + Neon Postgres. Clean separation: Flutter UI layer, FastAPI backend, agent pipeline. |
| Innovation & UX | 10% | Pakistan-specific healthcare problem. BSN student founder with genuine clinical domain knowledge. Emotionally compelling demo narrative. |

# **12. Tech Stack**

| **Layer** | **Technology** |
| --- | --- |
| Mobile App | Flutter (Android) |
| Backend API | Python FastAPI |
| AI Agents Runtime | OpenAI Agents SDK |
| Development IDE | Google Antigravity |
| Database | Neon Postgres (cloud-hosted) |
| File Parsing | PyMuPDF for PDFs, GPT-4o Vision for camera photos |
| API Hosting | Railway or Render (FastAPI backend) |

# **Pitch Opening Line**

| **For Judges** *"**Every night in Pakistani clinics, doctors manually go through 50 lab reports looking for critical values. In that same time, a patient**'**s kidneys are quietly starting to fail — and nobody knows yet. Jaiza changes that. Upload a report. The agents do the rest.**"* |
| --- |
