import asyncpg
import os
from dotenv import load_dotenv

# Load .env from project root (one level up from jaizaa_backend/)
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '..', '.env'))

_pool = None

async def get_pool():
    global _pool
    # Recreate pool if it was never created or has been closed
    if _pool is None or _pool._closed:
        db_url = os.getenv("DATABASE_URL")
        if not db_url:
            raise RuntimeError("DATABASE_URL is not set. Check your .env file.")
        _pool = await asyncpg.create_pool(
            db_url,
            min_size=1,
            max_size=5,
            max_inactive_connection_lifetime=300,  # recycle idle connections after 5 min
        )
    return _pool

