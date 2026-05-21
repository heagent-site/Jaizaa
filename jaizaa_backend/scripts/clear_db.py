import asyncio
import os
import sys

# Add the parent directory to the path so we can import db.connection
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from db.database import get_pool
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), '.env'))

async def clear_db():
    print("Connecting to database...")
    pool = await get_pool()
    async with pool.acquire() as conn:
        print("Executing DELETE commands...")
        # Delete in order of dependencies (child tables first)
        await conn.execute("DELETE FROM appointments;")
        await conn.execute("DELETE FROM alerts;")
        await conn.execute("DELETE FROM notifications;")
        await conn.execute("DELETE FROM patients;")
        print("Database cleared successfully.")
    await pool.close()

if __name__ == "__main__":
    asyncio.run(clear_db())
