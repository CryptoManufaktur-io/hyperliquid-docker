#!/usr/bin/env bash
# Removed strict mode to see more errors
# set -euo pipefail

# ——————— Load .env and export everything ———————
echo "Loading environment variables..."

# Get the script directory and the project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

set -o allexport
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
    echo "Loaded .env file"
else
    echo "Error: .env file not found"
    # Try to load from default.env instead
    if [ -f "$PROJECT_ROOT/default.env" ]; then
        source "$PROJECT_ROOT/default.env"
        echo "Loaded default.env file instead"
    else
        echo "Error: default.env file not found either"
        exit 1
    fi
fi
set +o allexport
# Check if CHAIN variable is set
if [ -z "${CHAIN+x}" ]; then
  echo "Error: CHAIN variable is not set in the environment file"
  exit 1
fi
echo "CHAIN is set to: $CHAIN"

# ——————— Define RPCs ———————
LOCAL_RPC="http://localhost:3001/evm"
echo "Local RPC endpoint: $LOCAL_RPC"

# choose public RPC based on CHAIN
case "${CHAIN}" in
  Testnet)
    PUBLIC_RPC="https://rpc.hyperliquid-testnet.xyz/evm"
    ;;
  Mainnet)
    PUBLIC_RPC="https://rpc.hyperliquid.xyz/evm"
    ;;
  *)
    echo "❌ Invalid CHAIN value: '$CHAIN'. Must be 'Testnet' or 'Mainnet'."
    exit 1
    ;;
esac
echo "Public RPC endpoint: $PUBLIC_RPC"

# ——————— Query blocks ———————
LOCAL_HEX=$(curl -s -X POST "$LOCAL_RPC" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  | jq -r '.result')

PUBLIC_HEX=$(curl -s -X POST "$PUBLIC_RPC" \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  | jq -r '.result')

# ——————— Convert and compare ———————
LOCAL=$(printf "%d\n" "$((LOCAL_HEX))")
PUBLIC=$(printf "%d\n" "$((PUBLIC_HEX))")

echo "$CHAIN Local node:   $LOCAL"
echo "$CHAIN Public head:  $PUBLIC"

if (( LOCAL >= PUBLIC )); then
  echo "✅ Your node is in sync (or ahead!)"
else
  echo "⚠️  Your node is $((PUBLIC - LOCAL)) blocks behind"
fi
