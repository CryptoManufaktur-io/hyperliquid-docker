#!/usr/bin/env bash

# Set your RPC URLs
LOCAL_RPC="http://localhost:3001/evm"

# Testnet: https://rpc.hyperliquid-testnet.xyz/evm
# Mainnet: https://rpc.hyperliquid.xyz/evm
PUBLIC_RPC="https://rpc.hyperliquid.xyz/evm"

# Fetch your node’s latest block
LOCAL_HEX=$(curl -s -X POST $LOCAL_RPC \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  | jq -r '.result')

# Fetch the public head block
PUBLIC_HEX=$(curl -s -X POST $PUBLIC_RPC \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  | jq -r '.result')

# Convert hex to decimal
LOCAL=$(printf "%d\n" $((LOCAL_HEX)))
PUBLIC=$(printf "%d\n" $((PUBLIC_HEX)))

# Print and compare
echo "Local node:   $LOCAL"
echo "Public head:  $PUBLIC"

if [ "$LOCAL" -ge "$PUBLIC" ]; then
  echo "✅ Your node is in sync (or ahead!)"
else
  echo "⚠️  Your node is $((PUBLIC-LOCAL)) blocks behind"
fi
