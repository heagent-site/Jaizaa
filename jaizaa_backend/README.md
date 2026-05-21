---
title: Jaizaa Backend
emoji: 🏥
colorFrom: green
colorTo: white
sdk: docker
app_port: 7860
pinned: false
---

# Jaizaa Backend API

This is the FastAPI backend for the Jaizaa mobile application. It processes lab reports, orchestrates a 6-agent AI pipeline using OpenRouter (`deepseek-v4-flash`), and persists the clinical actions directly into a Neon Postgres database.

## Environment Variables Needed in Hugging Face Space

You must configure the following Secrets in the Hugging Face Space settings:

- `DATABASE_URL` (Your Neon Postgres connection string)
- `OPENROUTER_API_KEY` (Your OpenRouter API key)
- `OPENROUTER_MODEL` (e.g., `deepseek/deepseek-v4-flash:free`)

## API Endpoints
- `GET /health`
- `POST /analyze` (Receives multipart form data: `file` and `patient_id`)
- `POST /patients`
- `POST /appointments`
- `POST /alerts`
- `POST /notifications`
