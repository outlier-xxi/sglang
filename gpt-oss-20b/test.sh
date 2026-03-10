#!/usr/bin/env bash
set -euo pipefail

BASE_URL="http://localhost:30000"
PASS=0
FAIL=0

ok()   { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# 1. Health check
resp=$(curl -sf "$BASE_URL/health" -o /dev/null -w "%{http_code}")
[ "$resp" = "200" ] && ok "GET /health → 200" || fail "GET /health → $resp"

# 2. Model info
model=$(curl -sf "$BASE_URL/get_model_info" | python3 -c "import sys,json; print(json.load(sys.stdin)['model_path'])")
[ "$model" = "openai/gpt-oss-20b" ] && ok "model_path = $model" || fail "unexpected model_path: $model"

# 3. Chat completion
chat_resp=$(curl -sf "$BASE_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-20b",
    "messages": [{"role": "user", "content": "Reply with the single word: pong"}],
    "max_tokens": 16,
    "temperature": 0
  }')
content=$(echo "$chat_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'])")
echo "  response: $content"
[ -n "$content" ] && ok "chat completion returned content" || fail "chat completion empty"

# 4. Metrics endpoint
metrics_resp=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE_URL/metrics")
[ "$metrics_resp" = "200" ] && ok "GET /metrics → 200" || fail "GET /metrics → $metrics_resp"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
