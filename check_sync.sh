#!/usr/bin/env bash
set -euo pipefail

# ——————— Load .env and export everything ———————
set -o allexport
source "$(dirname "$0")/.env"
set +o allexport

# ——————— Define RPCs ———————
LOCAL_RPC="http://localhost:3001/evm"

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
