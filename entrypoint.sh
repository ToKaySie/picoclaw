#!/usr/bin/env bash
set -e

echo "=== PicoClaw Entrypoint ==="
echo "Checking required environment variables..."

REQUIRED_VARS=(
  "OLLAMA_API_KEY"
  "OLLAMA_API_BASE"
  "SUPABASE_ACCESS_TOKEN"
  "SUPABASE_PROJECT_REF"
  "SUPABASE_ANON_KEY"
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

# Create PDF output directory in workspace
mkdir -p /root/.picoclaw/workspace/pdfs

# Create LaTeX compilation helper script
cat > /usr/local/bin/compile-latex <<'SCRIPT'
#!/usr/bin/env bash
set -e

TEX_FILE="$1"

if [ -z "$TEX_FILE" ]; then
  echo "ERROR: Usage: compile-latex <file.tex>"
  exit 1
fi

if [ ! -f "$TEX_FILE" ]; then
  echo "ERROR: File not found: $TEX_FILE"
  exit 1
fi

BASENAME=$(basename "$TEX_FILE" .tex)
DIRNAME=$(dirname "$TEX_FILE")

echo "Compiling $TEX_FILE with tectonic..."
cd "$DIRNAME"
tectonic "$TEX_FILE" 2>&1

PDF_FILE="${DIRNAME}/${BASENAME}.pdf"

if [ ! -f "$PDF_FILE" ]; then
  echo "ERROR: PDF was not generated."
  exit 1
fi

echo "PDF generated: $PDF_FILE"

# Upload to Supabase Storage if credentials are available
if [ -n "$SUPABASE_PROJECT_REF" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
  SUPABASE_URL="https://${SUPABASE_PROJECT_REF}.supabase.co"
  STORAGE_FILE="${BASENAME}_$(date +%s).pdf"

  echo "Uploading to Supabase Storage..."
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "${SUPABASE_URL}/storage/v1/object/pdfs/${STORAGE_FILE}" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/pdf" \
    --data-binary @"$PDF_FILE")

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | head -n -1)

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    PUBLIC_URL="${SUPABASE_URL}/storage/v1/object/public/pdfs/${STORAGE_FILE}"
    echo "UPLOAD_SUCCESS"
    echo "DOWNLOAD_URL=${PUBLIC_URL}"
  else
    echo "WARNING: Upload failed (HTTP $HTTP_CODE): $BODY"
    echo "PDF is still available locally at: $PDF_FILE"
  fi
else
  echo "Supabase credentials not set. PDF available locally at: $PDF_FILE"
fi

# Send directly to Telegram
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_USER_ID" ]; then
  echo "Sending PDF directly to Telegram..."
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
    -F chat_id="${TELEGRAM_USER_ID}" \
    -F document=@"$PDF_FILE" \
    -F caption="📄 Voici ton document PDF généré !" > /dev/null
  echo "TELEGRAM_SUCCESS"
  echo "Le PDF a été envoyé directement sur Telegram à l'utilisateur !"
fi
SCRIPT
chmod +x /usr/local/bin/compile-latex

# Generate config.json
echo "Generating /app/config.json..."

cat > /app/config.json <<EOF
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
          "url": "https://mcp.supabase.com/mcp?project_ref=${SUPABASE_PROJECT_REF}&features=database,storage",
          "headers": {
            "Authorization": "Bearer ${SUPABASE_ACCESS_TOKEN}"
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
