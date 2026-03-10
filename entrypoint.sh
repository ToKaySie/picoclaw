#!/usr/bin/env bash
set -e

echo "=== PicoClaw Entrypoint ==="
echo "Checking required environment variables..."

REQUIRED_VARS=(
  "OLLAMA_API_KEY"
  "OLLAMA_API_BASE"
  "SUPABASE_DATABASE_URL"
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

# Create PicoClaw config directory
mkdir -p /root/.picoclaw

echo "Generating /root/.picoclaw/config.json..."

cat > /root/.picoclaw/config.json <<EOF
{
  "model_list": [
    {
      "model_name": "mon-modele",
      "model": "ollama/qwen3.5:397b-cloud",
      "api_key": "${OLLAMA_API_KEY}",
      "api_base": "${OLLAMA_API_BASE}"
    }
  ],
  "agents": {
    "defaults": {
      "model": "mon-modele",
      "database_url": "${SUPABASE_DATABASE_URL}"
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

echo "config.json generated successfully at /root/.picoclaw/config.json"
echo "Starting PicoClaw gateway..."

exec picoclaw gateway
