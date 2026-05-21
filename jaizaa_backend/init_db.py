import asyncio
import os
import asyncpg
from dotenv import load_dotenv

# Load .env from project root
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))
DATABASE_URL = os.getenv("DATABASE_URL")

async def init_db():
    print(f"Connecting to database...")
    conn = await asyncpg.connect(DATABASE_URL)
    print("Connected! Executing migrations...")
    with open('migrations/001_initial.sql', 'r') as f:
        sql = f.read()
        await conn.execute(sql)
    print("Database initialized successfully.")
    
    # Verify tables
    tables = await conn.fetch(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
    )
    print(f"Tables created: {[t['table_name'] for t in tables]}")
    
    # Verify seed patient
    patient = await conn.fetchrow("SELECT * FROM patients WHERE patient_id = 1")
    if patient:
        print(f"Seed patient: {dict(patient)}")
    
    await conn.close()

if __name__ == "__main__":
    asyncio.run(init_db())
