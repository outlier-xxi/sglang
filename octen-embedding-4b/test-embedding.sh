#!/usr/bin/env bash
# test for the Octen-Embedding-4B API.
# Usage: ./test-embedding.sh [host] [port]

set -euo pipefail

HOST="${1:-localhost}"
PORT="${2:-30001}"
BASE_URL="http://${HOST}:${PORT}"
MODEL="Octen/Octen-Embedding-4B"
EXPECTED_DIM=2560

fail() { echo "FAILED: $*" >&2; exit 1; }

echo "==> Health check"
curl -sf "${BASE_URL}/health" > /dev/null || fail "health endpoint unreachable"
echo "    OK"

echo ""
echo "==> Model info"
curl -sf "${BASE_URL}/get_model_info" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f'    model : {d[\"model_path\"]}')
print(f'    type  : {\"embedding\" if not d[\"is_generation\"] else \"generation\"}')"

echo ""
echo "==> Single-string embedding"
curl -sf "${BASE_URL}/v1/embeddings" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${MODEL}\",\"input\":\"Hello, this is a test sentence for embedding.\"}" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
emb = d['data'][0]['embedding']
dim = len(emb)
expected = ${EXPECTED_DIM}
print(f'    dimensions : {dim}')
print(f'    first 5    : {emb[:5]}')
print(f'    tokens used: {d[\"usage\"][\"prompt_tokens\"]}')
if dim != expected:
    print(f'FAILED: expected {expected} dimensions, got {dim}', file=sys.stderr)
    sys.exit(1)
print('    OK')"

echo ""
echo "==> Batch embedding (2 inputs)"
curl -sf "${BASE_URL}/v1/embeddings" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${MODEL}\",\"input\":[\"First sentence.\",\"Second sentence.\"]}" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
n = len(d['data'])
print(f'    returned   : {n} embeddings')
if n != 2:
    print(f'FAILED: expected 2 embeddings, got {n}', file=sys.stderr)
    sys.exit(1)
print('    OK')"

echo ""
echo "All tests passed."
