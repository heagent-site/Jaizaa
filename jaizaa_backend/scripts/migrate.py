import asyncio
import os
import asyncpg
from dotenv import load_dotenv

# Load .env from project root
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '..', '.env'))
DATABASE_URL = os.getenv("DATABASE_URL")

async def migrate():
    if not DATABASE_URL:
        print("DATABASE_URL is not set. Check your .env file.")
        return
        
    print(f"Connecting to database...")
    conn = await asyncpg.connect(DATABASE_URL)
    print("Connected! Running migration to add last_analysis_result column...")
    
    # Add column if not exists
    await conn.execute("""
        ALTER TABLE patients 
        ADD COLUMN IF NOT EXISTS last_analysis_result JSONB DEFAULT NULL;
    """)
    print("Migration completed successfully.")
    
    # Verify columns
    columns = await conn.fetch("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'patients';
    """)
    print("Patients table schema columns:")
    for col in columns:
        print(f" - {col['column_name']}: {col['data_type']}")
        
    await conn.close()

if __name__ == "__main__":
    asyncio.run(migrate())
