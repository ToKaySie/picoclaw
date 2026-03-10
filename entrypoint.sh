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
echo "Generating /app/config.json..."

cat > /app/config.json <<EOF
{
  "providers": {
    "ollama_cloud": {
      "api_key": "${OLLAMA_API_KEY}",
      "api_base": "${OLLAMA_API_BASE}"
    }
  },
  "model_list": [
    {
      "model_name": "mon-modele",
      "model": "ollama_cloud/qwen3.5:0.8b",
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
  }
}
EOF

echo "config.json generated successfully."
echo "Starting PicoClaw gateway..."

exec picoclaw gateway --config /app/config.json
