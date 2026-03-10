#!/usr/bin/env bash
set -e

echo "=== PicoClaw Entrypoint ==="
echo "Checking required environment variables..."

REQUIRED_VARS=(
  "OLLAMA_API_KEY"
  "OLLAMA_API_BASE"
  "SUPABASE_API_KEY"
  "TELEGRAM_BOT_TOKEN"
  "TELEGRAM_USER_ID"
)

MISSING=0
for VAR in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "ERROR: Required environment variable '$VAR' is not set."
    MISSING=1
  fi
done

if [ "$MISSING" -eq 1 ]; then
  echo "ERROR: One or more required environment variables are missing. Aborting."
  exit 1
fi

echo "All environment variables are set."

# Create PicoClaw workspace directory
mkdir -p /root/.picoclaw/workspace

# Copy AGENTS.md to workspace
echo "Copying AGENTS.md to workspace..."
cp /app/AGENTS.md /root/.picoclaw/workspace/AGENTS.md

# Generate config.json
echo "Generating /app/config.json..."

cat > /app/config.json <<EOF
{
  "model_list": [
    {
      "model_name": "mon-modele",
      "model": "ollama/qwen3.5:0.8b",
      "api_key": "${OLLAMA_API_KEY}",
      "api_base": "${OLLAMA_API_BASE}"
    }
  ],
  "agents": {
    "defaults": {
      "model": "mon-modele"
    }
  },
  "tools": {
    "mcp": {
      "enabled": true,
      "servers": {
        "supabase": {
          "enabled": true,
          "type": "http",
          "url": "https://mcp.supabase.com",
          "headers": {
            "Authorization": "Bearer ${SUPABASE_API_KEY}"
          }
        }
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "${TELEGRAM_BOT_TOKEN}",
      "allow_from": ["${TELEGRAM_USER_ID}"]
    }
  },
  "gateway": {
    "host": "0.0.0.0",
    "port": 3000
  }
}
EOF

echo "config.json generated successfully."
echo "Starting PicoClaw gateway..."

export PICOCLAW_CONFIG=/app/config.json
exec picoclaw gateway
