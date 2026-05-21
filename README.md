# 🏥 Jaizaa — Intelligent Clinical Decision Support System (CDSS)

<p align="center">
  <a href="https://www.heagent.site/">
    <img src="https://img.shields.io/badge/Product%20of-HeAgent-blueviolet?style=for-the-badge&logo=rocket" alt="Product of HeAgent">
  </a>
  <img src="https://img.shields.io/badge/Backend-FastAPI-009688?style=for-the-badge&logo=fastapi" alt="FastAPI">
  <img src="img.shields.io/badge/Frontend-Flutter-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Database-Postgres%20(Neon)-4169E1?style=for-the-badge&logo=postgresql" alt="Postgres">
  <img src="https://img.shields.io/badge/AI%20Engine-OpenRouter%20(DeepSeek)-FF6F00?style=for-the-badge&logo=openai" alt="OpenRouter AI">
</p>

---

## 🌟 Introduction

**Jaizaa** is the flagship product of [HeAgent](https://www.heagent.site/), designed as a high-end, production-ready **Clinical Decision Support System (CDSS)**. It bridges the gap between raw clinical diagnostics and actionable healthcare operations. 

By utilizing a state-of-the-art **6-Agent Clinical Intelligence Pipeline**, Jaizaa processes patient lab reports (PDF or images), extracts core diagnostic markers, determines clinical risk severity, proposes evidence-based intervention plans, schedules patient follow-ups, and auto-generates patient-friendly clinical report cards.

---

## 🏗️ Architecture & Multi-Agent Orchestration

Jaizaa operates on a highly decoupled architecture: a mobile-responsive **Flutter** frontend, an asynchronous **FastAPI** backend, and a cloud-hosted serverless **Neon Postgres** database. 

```mermaid
graph TD
    A[Patient Lab Report PDF/Image] --> B[Flutter Mobile Frontend]
    B -->|POST /analyze| C[FastAPI Backend Gateway]
    C --> D[6-Agent Intelligence Pipeline]
    
    subgraph Multi-Agent AI Pipeline
        D --> E[Agent 1: Clinical Reader]
        E --> F[Agent 2: Health Analyzer]
        F --> G[Agent 3: Risk Assessor]
        G --> H[Agent 4: Intervention Planner]
        H --> I[Agent 5: Action Executor]
        I --> J[Agent 6: Summary Reporter]
    end
    
    J -->|JSON Schema| C
    C -->|Persist Records| K[(Neon Postgres DB)]
    C -->|HTTP 200 Response| B
```

### 🧠 The 6-Agent AI Pipeline
The core AI orchestration leverages specific, domain-targeted LLM agents executing in a structured cascade:

1. **Agent 1: Clinical Reader (OCR/Vision)**: Uses PyMuPDF or Vision LLMs to extract precise diagnostic numbers, reference intervals, and clinical annotations from raw uploads.
2. **Agent 2: Health Analyzer**: Comprehensively evaluates the clinical relationship between the extracted markers (e.g., LFT liver enzymes, CBC cell counts) and identifies potential pathophysiological patterns.
3. **Agent 3: Risk Assessor**: Classifies the patient's immediate clinical risk into `LOW`, `MEDIUM`, or `HIGH` based on international clinical guidelines.
4. **Agent 4: Intervention Planner**: Designs a curated set of medical interventions, lifestyle adjustments, and diet restrictions tailored specifically to the analysis.
5. **Agent 5: Action Executor**: Automatically structures actionable database records (e.g. scheduling follow-up appointments, preparing high-alert notifications for high-risk patients).
6. **Agent 6: Summary Reporter**: Compiles the entire diagnostic journey into a highly structured, patient-friendly medical summary card.

---

## 🛠️ Technology Stack

### Frontend (Mobile App)
* **Framework**: Flutter (Dart)
* **State Management**: ChangeNotifier & Provider Architecture
* **Networking**: Dio (custom client with environment fallback)
* **Android Target**: SDK 36 (Android 14+) with background camera and image-picker support
* **Build System**: Gradle 8.4+

### Backend (API Engine)
* **Web Framework**: FastAPI (Python 3.11)
* **Database Driver**: `asyncpg` (Asynchronous connection pooling)
* **Orchestration**: `openai-agents` (Structured JSON outputs and LLM cascades)
* **PDF Engine**: PyMuPDF (`fitz`)

### Cloud Infrastructure
* **Database**: Neon Postgres (Serverless)
* **Deployment Platform**: Hugging Face Spaces (Docker-based)
* **CI/CD**: GitHub Actions (Automatic container build and deployment)

---

## 📂 Project Directory Structure

```text
├── .github/
│   └── workflows/
│       ├── deploy.yml            # CI/CD pipeline to Hugging Face Spaces
│       └── build-apk.yml         # Optional GitHub Actions APK build workflow
├── jaizaa_backend/               # Python FastAPI backend
│   ├── ai_agents/                # 6-Agent implementation code
│   │   ├── agent1_reader.py      # Vision/OCR reader
│   │   ├── agent2_analyzer.py    # Health Analyzer
│   │   ├── agent3_risk.py        # Risk Assessor
│   │   ├── agent4_planner.py     # Care Planner
│   │   ├── agent5_executor.py    # Action Scheduler
│   │   ├── agent6_reporter.py    # Summary Reporter
│   │   ├── config.py             # LLM configurations & API token patcher
│   │   └── pipeline.py           # Pipeline runner & error translator
│   ├── db/
│   │   ├── database.py           # Async Connection Pooling (asyncpg)
│   │   └── queries.py            # Optimized SQL queries
│   ├── routes/                   # FastAPI route endpoints
│   ├── Dockerfile                # Production container configuration
│   ├── requirements.txt          # Python packages
│   └── main.py                   # API Entry point
└── jaizaa_flutter/               # Flutter mobile application
    ├── android/                  # Android configuration & build scripts
    ├── lib/                      # Flutter Dart source code
    │   ├── config/               # Theme & candidate URL API configs
    │   ├── models/               # Application-wide structured data models
    │   ├── providers/            # State management layer
    │   ├── screens/              # UI Screen widgets (Dashboard, Upload, Results)
    │   ├── services/             # Networking (Dio Client with candidate probe fallbacks)
    │   └── main.dart             # Application initialization entrypoint
    └── pubspec.yaml              # Flutter dependencies and assets config
```

---

## ⚙️ Environment Variables & Secrets Configuration

Create a `.env` file in the project root for local development. For production, register these variables in your target environment.

### Backend Configurations
| Variable | Description | Example / Value |
| :--- | :--- | :--- |
| `DATABASE_URL` | Neon PostgreSQL Connection URI | `postgresql://user:pass@host/dbname?sslmode=require` |
| `OPENROUTER_API_KEY` | OpenRouter Access Token | `sk-or-v1-xxxxxxxxxxxxxxxxxxxx` |
| `OPENROUTER_MODEL` | AI Model to run the pipeline | `deepseek/deepseek-v4-flash:free` |

### GitHub Secrets for Deployment
| Secret | Description |
| :--- | :--- |
| `HF_TOKEN` | Hugging Face Space write access token |
| `HF_SPACE_NAME` | Hugging Face target Space name (e.g., `jaizaa`) |
| `HF_USERNAME` | Hugging Face account username (e.g., `heagent`) |

---

## 🚀 Setup & Installation Instructions

### Prerequisites
* Python 3.11 installed
* Flutter SDK (3.22.0+) and Android SDK (Platform 36) installed
* Neon Postgres account

---

### 1. Local Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd jaizaa_backend
   ```
2. **Create a Virtual Environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```
4. **Configure Environment Variables**:
   Create a `.env` file inside the root directory and add the `DATABASE_URL`, `OPENROUTER_API_KEY`, and `OPENROUTER_MODEL`.
5. **Run Database Migrations**:
   ```bash
   python scripts/migrate.py
   ```
6. **Launch the FastAPI Server**:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

The backend API will be available locally at `http://localhost:8000`. You can inspect the interactive OpenAPI documentation at `http://localhost:8000/docs`.

---

### 2. Local Flutter Setup

1. **Navigate to the flutter directory**:
   ```bash
   cd jaizaa_flutter
   ```
2. **Resolve Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Launch the App**:
   * For Emulator / USB Connected device:
     ```bash
     flutter run
     ```
   * *Note*: When running on a physical mobile device, the app dynamically detects your local environment. Ensure your phone and development PC are connected to the **same WiFi network** to enable direct connectivity to the local API server (`http://<your-pc-ip>:8000`).

---

### 3. Packaging the Production APK

To compile an optimized, production-ready release APK signed with testing configurations:
```bash
cd jaizaa_flutter
flutter build apk --no-pub --release
```
The optimized APK will be generated at:  
`jaizaa_flutter/build/app/outputs/flutter-apk/app-release.apk`

---

### 🌐 Hugging Face Space Production Deployment

The project has integrated **Hugging Face Continuous Deployment** via GitHub Actions.

1. Set up your Hugging Face Space with the SDK type set to **Docker**.
2. Add your **Hugging Face Access Token**, **Space Name**, and **Username** as Actions secrets in your GitHub repository.
3. Add `DATABASE_URL`, `OPENROUTER_API_KEY`, and `OPENROUTER_MODEL` in your Hugging Face Space Settings tab under **Repository Secrets**.
4. Push any change to the `main` branch. GitHub Actions will trigger, upload the backend source code, and Hugging Face will automatically compile the Docker image and deploy the production API at:
   `https://<username>-<space-name>.hf.space`

---

## ⚖️ License & Ownership

This project is the proprietary property of **HeAgent** (available at [www.heagent.site](https://www.heagent.site/)). All rights reserved.

---
<p align="center">
  Built with 💜 by the HeAgent Team.
</p>
