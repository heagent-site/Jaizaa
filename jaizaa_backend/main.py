from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import analyze, patients, appointments, alerts, notifications, history

app = FastAPI(title="Jaizaa API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://heagent-jaizaa.hf.space",  # HF production
        "http://192.168.100.95:8000",        # same-WiFi local
        "http://localhost:8000",             # local dev
        "http://localhost:54019",            # Flutter web dev port
        "*",                                 # fallback (Postman / curl)
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analyze.router)
app.include_router(patients.router)
app.include_router(appointments.router)
app.include_router(alerts.router)
app.include_router(notifications.router)
app.include_router(history.router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "jaizaa-api"}
