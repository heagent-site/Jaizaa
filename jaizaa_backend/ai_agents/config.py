import os
import json
from agents import AsyncOpenAI, OpenAIChatCompletionsModel, RunConfig
from dotenv import load_dotenv

# Load .env from project root
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '..', '.env'))

# Read OpenRouter API key from environment
OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY")
OPENROUTER_MODEL = os.environ.get("OPENROUTER_MODEL", "deepseek/deepseek-v4-flash:free")

# Create an AsyncOpenAI client with OpenRouter base URL
external_client = AsyncOpenAI(
    api_key=OPENROUTER_API_KEY,
    base_url="https://openrouter.ai/api/v1",
)

# Patch the create method to ensure max_tokens is always set (prevents OpenRouter 402 payment errors on lower credit balances)
original_create = external_client.chat.completions.create

async def patched_create(*args, **kwargs):
    model_name = kwargs.get("model", "")
    is_vision = (model_name == "google/gemini-2.5-flash")
    if not is_vision:
        # Check messages for any image_url
        for msg in kwargs.get("messages", []):
            if isinstance(msg, dict) and isinstance(msg.get("content"), list):
                for item in msg["content"]:
                    if isinstance(item, dict) and item.get("type") == "image_url":
                        is_vision = True
                        break

    if is_vision:
        kwargs["max_tokens"] = 1500
    else:
        kwargs["max_tokens"] = 1000
    return await original_create(*args, **kwargs)

external_client.chat.completions.create = patched_create

# Define the model to use (Deepseek via OpenRouter)
openrouter_model = OpenAIChatCompletionsModel(
    model=OPENROUTER_MODEL,
    openai_client=external_client,
)

# Configure how agents should run
run_config = RunConfig(
    model=openrouter_model,
    model_provider=external_client,
)

def clean_json_output(raw: str) -> dict:
    """Parse JSON from LLM output, handling markdown code fences."""
    raw = raw.strip()
    # Remove markdown code fences if present
    if raw.startswith("```"):
        lines = raw.split("\n")
        filtered = []
        in_fence = False
        for line in lines:
            if line.strip().startswith("```") and not in_fence:
                in_fence = True
                continue
            elif line.strip() == "```" and in_fence:
                in_fence = False
                continue
            filtered.append(line)
        raw = "\n".join(filtered)
    try:
        return json.loads(raw.strip())
    except json.JSONDecodeError as e:
        print(f"Failed to decode JSON: {raw[:500]}")
        raise e

# Validate API key on startup
if not OPENROUTER_API_KEY:
    raise RuntimeError("OPENROUTER_API_KEY is not set in .env file")
print(f"[OK] OpenRouter API key loaded: {OPENROUTER_API_KEY[:8]}...")
print(f"[OK] Using model: {OPENROUTER_MODEL}")
