FROM python:3.11-slim

WORKDIR /app

# Install system dependencies needed for asyncpg and PyMuPDF
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    gcc \
    libmupdf-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
# NOTE: .env is NOT copied — real secrets come from HF Space settings.
#       .env.example is copied for documentation only.
COPY . .
RUN rm -f .env  # safety: ensure no accidental secret leak if .env was present

# Hugging Face Spaces requires port 7860
EXPOSE 7860

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
